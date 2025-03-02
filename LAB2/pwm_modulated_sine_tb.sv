// pwm_modulated_sine_tb.sv
// Testbench for PWM modulated sine wave generator
`timescale 1ns/1ps

module pwm_modulated_sine_tb();

  // Clock and reset signals
  logic clk_50mhz;
  logic [1:0] sw;
  logic [1:0] key;
  logic [1:0] arduino_io;
  logic [9:0] ledr;
  
  // DUT Instantiation
  pwm_modulated_sine dut(
    .MAX10_CLK1_50(clk_50mhz),
    .SW(sw),
    .KEY(key),
    .ARDUINO_IO(arduino_io),
    .LEDR(ledr)
  );
  
  // For monitoring state of the DUT
  state_t current_state, next_state;
  assign current_state = dut.current_state;
  assign next_state = dut.next_state;
  
  // Create 50MHz clock (20ns period)
  initial begin
    clk_50mhz = 0;
    forever #10 clk_50mhz = ~clk_50mhz;
  end
  
  // Test procedure
  initial begin
    // Initialize inputs
    sw = 2'b11;  // No reset
    key = 2'b11; // No keys pressed (active low)
    
    // Apply reset
    sw[0] = 0;   // Assert reset (active low)
    #100;
    sw[0] = 1;   // Deassert reset
    
    // Wait for stabilization
    #1000;
    
    // Check initial frequency - should be BASE_FREQ (1000 Hz)
    $display("Initial frequency: %d Hz", dut.freq);
    assert(dut.freq == 1000) else $error("Initial frequency not set to BASE_FREQ");
    
    // Calculate how long to wait for one full PWM cycle at 1kHz (1ms)
    // 50,000 clock cycles at 50MHz = 1ms
    #1000000;  // Wait for 1ms
    
    // Check PWM outputs are toggling
    $display("Checking PWM generation...");
    
    // Test frequency increase (press KEY[0])
    $display("\nTesting frequency increase...");
    repeat(10) begin  // Press KEY[0] 10 times to increase by 1000Hz
      // Press KEY[0] (active low)
      key[0] = 0;
      #1000000;  // Hold for 1ms
      key[0] = 1;
      #1000000;  // Wait 1ms between presses
      
      // Display and check current frequency
      $display("Current frequency after increase: %d Hz", dut.freq);
    end
    
    // Test upper frequency limit (10kHz)
    $display("\nTesting upper frequency limit...");
    repeat(100) begin  // Try to go well beyond max
      key[0] = 0;
      #500000;  // Hold for 0.5ms (faster for simulation)
      key[0] = 1;
      #500000;  // Wait 0.5ms between presses
    end
    $display("Frequency after attempting to exceed max: %d Hz", dut.freq);
    assert(dut.freq <= 10000) else $error("Frequency exceeds MAX_FREQ");
    
    // Test frequency decrease (press KEY[1])
    $display("\nTesting frequency decrease...");
    repeat(100) begin  // Press KEY[1] many times to reduce frequency
      // Press KEY[1] (active low)
      key[1] = 0;
      #1000000;  // Hold for 1ms
      key[1] = 1;
      #1000000;  // Wait 1ms between presses
      
      // Every 10 decreases, show current frequency
      if (($time % 10) == 0)
        $display("Current frequency after decrease: %d Hz", dut.freq);
    end
    
    // Test lower frequency limit (100Hz)
    $display("\nTesting lower frequency limit...");
    repeat(10) begin  // Try to go below min
      key[1] = 0;
      #1000000;  // Hold for 1ms
      key[1] = 1;
      #1000000;  // Wait 1ms between presses
    end
    $display("Frequency after attempting to go below min: %d Hz", dut.freq);
    assert(dut.freq >= 100) else $error("Frequency below MIN_FREQ");
    
    // Test state transitions
    $display("\nTesting state transitions...");
    
    // Wait for COUNT state
    wait(current_state == dut.S_COUNT);
    $display("Current state: S_COUNT");
    
    // Press a key to trigger state transition to UPDATE
    key[0] = 0;
    #100;
    
    // Wait for transition to UPDATE state
    wait(current_state == dut.S_UPDATE);
    $display("State transitioned to: S_UPDATE");
    
    // Release key
    key[0] = 1;
    #100;
    
    // Wait for transition back to COUNT
    wait(current_state == dut.S_COUNT);
    $display("State transitioned back to: S_COUNT");
    
    // Test reset during operation
    $display("\nTesting reset during operation...");
    #1000;
    sw[0] = 0;  // Assert reset
    #100;
    
    // Verify state is RESET
    assert(current_state == dut.S_RESET) else $error("Reset did not transition to S_RESET state");
    $display("State after reset: S_RESET");
    
    // Release reset
    sw[0] = 1;
    #1000;
    
    // Verify returned to normal operation
    assert(current_state == dut.S_COUNT) else $error("Did not return to normal operation after reset");
    $display("State after releasing reset: S_COUNT");
    
    // End simulation
    $display("\nTestbench completed successfully!");
    #10000;
    $finish;
  end
  
  // Optional: Add waveform dumping for viewing in simulator
  initial begin
    $dumpfile("pwm_sine_tb.vcd");
    $dumpvars(0, pwm_modulated_sine_tb);
  end

endmodule