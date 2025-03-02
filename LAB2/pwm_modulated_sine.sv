//=============================================================================
// pwm_modulated_sine: PWM modulated sine generator with integrated Mealy FSM,
// synchronized reset from SW[0], and button debouncing for KEY[0] and KEY[1]
// ARDUINO PIN 0: fixed 50% duty cycle PWM
// ARDUINO PIN 1: Modulated PWM
//=============================================================================
module pwm_modulated_sine (
    input logic MAX10_CLK1_50, // 50MHz clock
    input logic [1:0] SW,      // Board switches (SW[0] used for reset)
    input logic [1:0] KEY,     // Push buttons for frequency control
    output logic ARDUINO_IO[1:0], // PWM outputs
    output logic [9:0] LEDR    // LED dimming / status outputs
);
    //-------------------------------------------------------------------------
    // Reset Generation: SW[0] is active low. We create an asynchronous
    // reset (rst_async) and then synchronize its deassertion with a two-FF
    // synchronizer to generate rst_sync.
    //-------------------------------------------------------------------------
    logic rst_async;
    assign rst_async = ~SW[0]; // Active when SW[0] is low
    reg rst_ff1, rst_ff2;
    always_ff @(posedge MAX10_CLK1_50 or posedge rst_async) begin
        if (rst_async) begin
            rst_ff1 <= 1'b1;
            rst_ff2 <= 1'b1;
        end
        else begin
            rst_ff1 <= 1'b0;
            rst_ff2 <= rst_ff1;
        end
    end
    assign rst_sync = rst_ff2;
    
    //-------------------------------------------------------------------------
    // Parameters
    //-------------------------------------------------------------------------
    localparam CLOCK_FREQ = 50_000_000;
    localparam BASE_FREQ = 1000;       // Initial frequency = 1 kHz
    localparam SAMPLE_COUNT = 200;     // 200-point sine LUT
    localparam MIN_FREQ = 100;         // Minimum frequency = 100 Hz
    localparam MAX_FREQ = 10000;       // Maximum frequency = 10 kHz
    localparam STEP_FREQ = 100;        // Step up or down frequency change 100 Hz
    
    //-------------------------------------------------------------------------
    // Debounced push-button pulses for frequency control.
    // KEY[0] increases frequency; KEY[1] decreases frequency.
    //-------------------------------------------------------------------------
    logic key0_pulse, key1_pulse;
    button_debounce deb0 (
        .clk(MAX10_CLK1_50),
        .rst(rst_sync),
        .button(KEY[0]),
        .pulse(key0_pulse)
    );
    button_debounce deb1 (
        .clk(MAX10_CLK1_50),
        .rst(rst_sync),
        .button(KEY[1]),
        .pulse(key1_pulse)
    );
    
    //-------------------------------------------------------------------------
    // Frequency and PWM control registers and variables
    //-------------------------------------------------------------------------
    logic [31:0] freq;          // Current frequency in Hz
    logic [31:0] counter;       // PWM period counter
    logic [31:0] counter_max;   // Maximum counter value (PWM period)
    logic [31:0] d0_compare;    // 50% duty cycle compare value
    logic [31:0] d1_compare;    // Modulated duty cycle compare value
    logic [15:0] phase;         // Phase index into sine LUT
    logic signed [31:0] scaled; // Scaled sine value (for modulation)
    logic [15:0] amplitude;     // Amplitude for modulation
    
    // python code to get the Sine LUT values below:
    // import numpy as np
    // SAMPLE_COUNT = 200
    // n = np.arange(SAMPLE_COUNT)
    // sine_values = np.sin(2 * np.pi * n / SAMPLE_COUNT)
    // q15_lut = np.round(sine_values * 32767).astype(int)
    // print("logic signed [15:0] sine_lut [0:SAMPLE_COUNT-1] = '{")
    // print(" " + ",\n ".join(
    // ", ".join(f"{val:6d}" for val in q15_lut[i:i+10])
    // for i in range(0, SAMPLE_COUNT, 10)
    // ))
    // print("};")
    
    //-------------------------------------------------------------------------
    // Sine LUT (16 bit quantized format)
    //-------------------------------------------------------------------------
    logic signed [15:0] sine_lut [0:SAMPLE_COUNT-1] = '{
        0,    1029,    2057,    3084,    4107,    5126,    6140,    7148,    8149,    9142,
        10126, 11099, 12062, 13013, 13952, 14876, 15786, 16680, 17557, 18418,
        19260, 20083, 20886, 21669, 22431, 23170, 23886, 24579, 25247, 25891,
        26509, 27101, 27666, 28204, 28714, 29196, 29648, 30072, 30466, 30830,
        31163, 31466, 31738, 31978, 32187, 32364, 32509, 32622, 32702, 32751,
        32767, 32751, 32702, 32622, 32509, 32364, 32187, 31978, 31738, 31466,
        31163, 30830, 30466, 30072, 29648, 29196, 28714, 28204, 27666, 27101,
        26509, 25891, 25247, 24579, 23886, 23170, 22431, 21669, 20886, 20083,
        19260, 18418, 17557, 16680, 15786, 14876, 13952, 13013, 12062, 11099,
        10126,  9142,  8149,  7148,  6140,  5126,  4107,  3084,  2057,  1029,
            0, -1029, -2057, -3084, -4107, -5126, -6140, -7148, -8149, -9142,
        -10126,-11099,-12062,-13013,-13952,-14876,-15786,-16680,-17557,-18418,
        -19260,-20083,-20886,-21669,-22431,-23170,-23886,-24579,-25247,-25891,
        -26509,-27101,-27666,-28204,-28714,-29196,-29648,-30072,-30466,-30830,
        -31163,-31466,-31738,-31978,-32187,-32364,-32509,-32622,-32702,-32751,
        -32767,-32751,-32702,-32622,-32509,-32364,-32187,-31978,-31738,-31466,
        -31163,-30830,-30466,-30072,-29648,-29196,-28714,-28204,-27666,-27101,
        -26509,-25891,-25247,-24579,-23886,-23170,-22431,-21669,-20886,-20083,
        -19260,-18418,-17557,-16680,-15786,-14876,-13952,-13013,-12062,-11099,
        -10126, -9142, -8149, -7148, -6140, -5126, -4107, -3084, -2057, -1029
    };
    
    //-------------------------------------------------------------------------
    // Compute counter_max, d0_compare, and amplitude.
    //-------------------------------------------------------------------------
    always_ff @(posedge MAX10_CLK1_50) begin
        if (rst_sync) begin
            counter_max <= 0;
            d0_compare <= 0;
            amplitude <= 0;
        end
        else begin
            counter_max <= (CLOCK_FREQ / freq) - 1;
            d0_compare <= ((CLOCK_FREQ / freq)) >> 1;
            amplitude <= ((CLOCK_FREQ / freq)) >> 2;
        end
    end
    
    //-------------------------------------------------------------------------
    // Our pending key event latches for KEY[0] and KEY[1]
    // These registers hold a key event until it is processed in S_UPDATE.
    //-------------------------------------------------------------------------
    logic pending_key0, pending_key1;
    always_ff @(posedge MAX10_CLK1_50 or posedge rst_sync) begin
        if (rst_sync) begin
            pending_key0 <= 1'b0;
            pending_key1 <= 1'b0;
        end
        else begin
            // Latch a new event if detected.
            pending_key0 <= (current_state == S_UPDATE) ? 1'b0 : (pending_key0 || key0_pulse);
            pending_key1 <= (current_state == S_UPDATE) ? 1'b0 : (pending_key1 || key1_pulse);
        end
    end
    
    //-------------------------------------------------------------------------
    // Mealy FSM for PWM generation, sine modulation, and frequency control.
    // We use combinational logic to immediately compute a new frequency if a
    // pending key event is present.
    //-------------------------------------------------------------------------
    typedef enum logic [1:0] {
        S_RESET,  // Initialize registers
        S_COUNT,  // Generate PWM signals
        S_UPDATE  // Update modulation parameters (and frequency if needed)
    } state_t;
    
    state_t current_state, next_state;
    logic [31:0] new_freq; // Combinationally computed new frequency
    
    // Combinational next-state and frequency-update logic (Mealy style)
    always_comb begin
        // Default: no frequency change.
        new_freq = freq;
        
        // Use latched key events to update new_freq immediately.
        if (pending_key0 && (freq < MAX_FREQ))
            new_freq = freq + STEP_FREQ;
        else if (pending_key1 && (freq > MIN_FREQ))
            new_freq = freq - STEP_FREQ;
        
        // Transition to S_UPDATE if a pending key event exists or the PWM period expires.
        if ((pending_key0 || pending_key1) || (counter == counter_max))
            next_state = S_UPDATE;
        else
            next_state = S_COUNT;
    end
    
    // FSM state update (synchronous reset)
    always_ff @(posedge MAX10_CLK1_50) begin
        if (rst_sync)
            current_state <= S_RESET;
        else
            current_state <= next_state;
    end
    
    // FSM outputs and actions
    always_ff @(posedge MAX10_CLK1_50) begin
        if (rst_sync) begin
            counter <= 0;
            phase <= 0;
            freq <= BASE_FREQ;
            d1_compare <= ((CLOCK_FREQ / BASE_FREQ)) >> 1;
            scaled <= 0;
            ARDUINO_IO[0] <= 0;
            ARDUINO_IO[1] <= 0;
            LEDR <= 10'b0;
        end
        else begin
            case (current_state)
                S_RESET: begin
                    counter <= 0;
                    phase <= 0;
                    d1_compare <= ((CLOCK_FREQ / freq)) >> 1;
                    ARDUINO_IO[0] <= 0;
                    ARDUINO_IO[1] <= 0;
                    LEDR <= 10'b0;
                end
                
                S_COUNT: begin
                    if (counter < counter_max)
                        counter <= counter + 1;
                    ARDUINO_IO[0] <= (counter < d0_compare);
                    ARDUINO_IO[1] <= (counter < d1_compare);
                    LEDR[0] <= (counter < d1_compare);
                    LEDR[9:1] <= 0;
                end
                
                S_UPDATE: begin
                    // Immediately update the frequency using the combinationally
                    // computed new_freq.
                    freq <= new_freq;
                    
                    // Recalculate modulation parameters using the (possibly) new frequency.
                    scaled <= amplitude * sine_lut[phase];
                    d1_compare <= (((CLOCK_FREQ / new_freq)) >> 1) + (scaled >>> 15);
                    phase <= (phase == SAMPLE_COUNT - 1) ? 0 : phase + 1;
                    counter <= 0;
                    ARDUINO_IO[0] <= 0;
                    ARDUINO_IO[1] <= 0;
                    LEDR[0] <= 0;
                end
            endcase
        end
    end
endmodule

//=============================================================================
// Button_debounce with a two-FF synchronizer, a counter-based filter, and a
// rising-edge detector that generates a single pulse per button press.
//=============================================================================
module button_debounce (
    input logic clk,      // Clock signal
    input logic rst,      // Synchronous reset (e.g., rst_sync)
    input logic button,   // Raw button input
    output logic pulse    // Single-cycle pulse on rising edge (debounced)
);
    // Step 1: Synchronize the raw button input to avoid metastability.
    logic button_sync1, button_sync2;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            button_sync1 <= 1'b0;
            button_sync2 <= 1'b0;
        end
        else begin
            button_sync1 <= button;
            button_sync2 <= button_sync1;
        end
    end
    
    // Step 2: Debounce filter using a counter.
    localparam COUNTER_MAX = 20'hFFFFF;
    logic [19:0] counter;
    logic stable_button;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
            stable_button <= button_sync2; // Assume initial state is stable
        end
        else begin
            if (button_sync2 != stable_button)
                counter <= 0; // Restart counter when a change is detected
            else if (counter < COUNTER_MAX)
                counter <= counter + 1;
                
            // Once stable for enough cycles, update the stable state.
            if (counter == COUNTER_MAX)
                stable_button <= button_sync2;
        end
    end
    
    // Step 3: Edge detector to generate a single pulse on the rising edge.
    logic stable_button_prev;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            stable_button_prev <= 1'b0;
            pulse <= 1'b0;
        end
        else begin
            stable_button_prev <= stable_button;
            pulse <= (~stable_button_prev) & stable_button;
        end
    end
endmodule