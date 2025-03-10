module fsm_multiplier (
    input MAX10_CLK1_50,
    input [1:0] KEY,          // KEY[0]: Start/multiply (active-low), KEY[1]: Mode cycle (active-low)
    input [9:0] SW,
    output reg [3:0] state,
    output reg [15:0] product,
    output reg [7:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
    output reg [9:0] LEDR
);

    // State encoding (one-hot)
    localparam IDLE      = 4'b0001,
               FIRST_NUM = 4'b0010,
               NEXT_NUM  = 4'b0100,
               ERROR     = 4'b1000;

    // Mode encoding
    localparam MODE_DIV = 2'b00,
               MODE_ADD = 2'b01,
               MODE_SUB = 2'b10,
               MODE_MUL = 2'b11;

    // Internal registers
    reg [15:0] num1, next_num1;
    reg [9:0] num2, next_num2;
    reg [3:0] next_state;
    reg [31:0] mul_result, next_mul_result;
    reg btn_reg, btn_reg_d;
    reg btn1_reg, btn1_reg_d;
    wire btn_pressed, btn1_pressed;
    reg [1:0] mode_counter, next_mode_counter;

    // Debounce KEY[0] and KEY[1]
    wire debounced_key0, debounced_key1;
    debounce debounce_key0 (
        .clk(MAX10_CLK1_50),
        .btn_in(~KEY[0]),
        .btn_out(debounced_key0)
    );
    debounce debounce_key1 (
        .clk(MAX10_CLK1_50),
        .btn_in(~KEY[1]),
        .btn_out(debounced_key1)
    );

    // BCD converter
    wire [3:0] bcd1, bcd10, bcd100, bcd1000;
    bcd_converter A (
        .binary(product),
        .bcd1(bcd1),
        .bcd10(bcd10),
        .bcd100(bcd100),
        .bcd1000(bcd1000)
    );

    // Combinational next-state logic
    always_comb begin
        next_state = state;
        next_num1 = num1;
        next_num2 = num2;
        next_mul_result = mul_result;
        next_mode_counter = mode_counter;
        LEDR = 10'b0;
			
			$display("Time: %t, state: %b, KEY[0]: %b, KEY[1]: %b, debounced_key0: %b, debounced_key1: %b", 
             $time, state, KEY[0], KEY[1], debounced_key0, debounced_key1);
			
        case (state)
            IDLE: begin
                LEDR[5:0] = 6'b000001;
                if (btn_pressed) begin
                    next_state = FIRST_NUM;
                end
                if (btn1_pressed) begin
                    next_mode_counter = mode_counter + 1;
                end
            end
            FIRST_NUM: begin
                LEDR[5:0] = 6'b000010;
                if (btn_pressed) begin
                    next_num1 = {6'b0, SW};
                    next_state = NEXT_NUM;
                end
            end
            NEXT_NUM: begin
                LEDR[5:0] = 6'b000100;
                if (btn_pressed) begin
                    next_num2 = SW;
                    case (mode_counter)
                        MODE_DIV: begin
                            if (next_num2 == 0) begin
                                next_state = ERROR;
                            end else begin
                                next_mul_result = num1 / {6'b0, next_num2};
                                if (next_mul_result > 9999)
                                    next_state = ERROR;
                                else
                                    next_num1 = next_mul_result[15:0];
                            end
                        end
                        MODE_ADD: begin
                            next_mul_result = num1 + {6'b0, next_num2};
                            if (next_mul_result > 9999)
                                next_state = ERROR;
                            else
                                next_num1 = next_mul_result[15:0];
                        end
                        MODE_SUB: begin
                            if (num1 < {6'b0, next_num2})
                                next_state = ERROR;
                            else begin
                                next_mul_result = num1 - {6'b0, next_num2};
                                next_num1 = next_mul_result[15:0];
                            end
                        end
                        MODE_MUL: begin
                            next_mul_result = num1 * next_num2;
                            if (next_mul_result > 9999)
                                next_state = ERROR;
                            else
                                next_num1 = next_mul_result[15:0];
                        end
                    endcase
                    if (next_state != ERROR)
                        next_state = NEXT_NUM;
                end
            end
            ERROR: begin
                LEDR = 10'b1111111111;
            end
            default: next_state = IDLE;
        endcase

        // Set mode LEDs unless in ERROR state
        if (state != ERROR) begin
            case (mode_counter)
                MODE_DIV: LEDR[9:6] = 4'b0001;
                MODE_ADD: LEDR[9:6] = 4'b0010;
                MODE_SUB: LEDR[9:6] = 4'b0100;
                MODE_MUL: LEDR[9:6] = 4'b1000;
                default: LEDR[9:6] = 4'b0000;
            endcase
        end
    end

    // Sequential logic
    always_ff @(posedge MAX10_CLK1_50 or negedge KEY[1]) begin
		if (!KEY[1]) begin 
			$display("always_ff block has been called with KEY[1] being TRUE!");
		      state <= IDLE;
            num1 <= 16'b0;
            num2 <= 10'b0;
            product <= 16'b0;
            mul_result <= 32'b0;
            btn_reg <= 0;
            btn_reg_d <= 0;
				if (state != IDLE) begin
					mode_counter <= mode_counter - 1;
				end
		end else begin
		$display("always_ff block has been called with KEY[1] being FALSE!");
        state <= next_state;
        num1 <= next_num1;
        num2 <= next_num2;
        mul_result <= next_mul_result;
        product <= (state == ERROR) ? 16'b0 : mul_result[15:0];
        mode_counter <= next_mode_counter;
        // Button edge detection
        btn_reg <= debounced_key0;
        btn_reg_d <= btn_reg;
        btn1_reg <= debounced_key1;
        btn1_reg_d <= btn1_reg;
    end
	end

    assign btn_pressed = btn_reg && !btn_reg_d;
    assign btn1_pressed = btn1_reg && !btn1_reg_d;

    // HEX display logic
    always @(*) begin
        if (state == ERROR) begin
            HEX0 = 8'b10000110; // 'E'
            HEX1 = 8'b10000110;
            HEX2 = 8'b10000110;
            HEX3 = 8'b10000110;
            HEX4 = 8'b10000110;
            HEX5 = 8'b10000110;
        end else begin
            HEX0 = get_segment(bcd1);
            HEX1 = get_segment(bcd10);
            HEX2 = get_segment(bcd100);
            HEX3 = get_segment(bcd1000);
            HEX4 = 8'b11111111;
            HEX5 = 8'b11111111;
        end
    end

    // Segment decoder function
    function [7:0] get_segment(input [3:0] bcd);
        case (bcd)
            4'd0: get_segment = 8'b11000000;
            4'd1: get_segment = 8'b11111001;
            4'd2: get_segment = 8'b10100100;
            4'd3: get_segment = 8'b10110000;
            4'd4: get_segment = 8'b10011001;
            4'd5: get_segment = 8'b10010010;
            4'd6: get_segment = 8'b10000010;
            4'd7: get_segment = 8'b11111000;
            4'd8: get_segment = 8'b10000000;
            4'd9: get_segment = 8'b10010000;
            default: get_segment = 8'b11111111;
        endcase
    endfunction
endmodule
	 
// Debounce module (corrected for active-low input)

module debounce (
    input clk,
    input btn_in, // Now expects active-high input (after inversion)
    output reg btn_out
);
    reg [15:0] counter;
    reg [3:0] sync_reg;

    always @(posedge clk) begin
        sync_reg <= {sync_reg[2:0], btn_in}; // Synchronize input
        if (sync_reg[3] ^ sync_reg[2]) // Reset counter on input change
            counter <= 0;
        else if (counter < 20'hFFFFF) // ~1ms debounce at 50MHz
            counter <= counter + 1;
        else
            btn_out <= sync_reg[3]; // Stable output
    end
endmodule

// BCD converter module (Double Dabble algorithm)

module bcd_converter (
    input [15:0] binary,
    output reg [3:0] bcd1, bcd10, bcd100, bcd1000
);
    integer i;
    reg [3:0] thousands, hundreds, tens, ones;

    always @(binary) begin
        thousands = 4'b0;
        hundreds = 4'b0;
        tens = 4'b0;
        ones = 4'b0;

        for (i = 15; i >= 0; i = i - 1) begin
            // Add 3 if >=5 for each digit
            if (thousands >= 5) thousands = thousands + 3;
            if (hundreds >= 5) hundreds = hundreds + 3;
            if (tens >= 5) tens = tens + 3;
            if (ones >= 5) ones = ones + 3;

            // Shift left
            thousands = thousands << 1;
            thousands[0] = hundreds[3];
            hundreds = hundreds << 1;
            hundreds[0] = tens[3];
            tens = tens << 1;
            tens[0] = ones[3];
            ones = ones << 1;
            ones[0] = binary[i];
        end

        bcd1000 = thousands;
        bcd100 = hundreds;
        bcd10 = tens;
        bcd1 = ones;
    end
endmodule