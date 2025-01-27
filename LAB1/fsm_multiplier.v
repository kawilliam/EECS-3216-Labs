
module fsm_multiplier (MAX10_CLK1_50, KEY, SW, state, product, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, LEDR);
    input MAX10_CLK1_50;
    input [1:0] KEY;    							 
    input [9:0] SW;               							
    output reg [3:0] state;
    output reg [15:0] product;
	output reg [7:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    output reg [9:0] LEDR;           						


    // State encoding
    localparam IDLE = 4'b0001,
               FIRST_NUM = 4'b0010,
               NEXT_NUM = 4'b0100,
               ERROR = 4'b1000;

    // Internal registers
    reg [9:0] num1, num2;           // Two 10-bit registers to hold the numbers
    reg [31:0] mul_result;          // For storing the multiplication result (since 10 bits * 10 bits = 20 bits max)
    reg btn_reg, btn_reg_d;         // Button debounce registers
	 reg [3:0] next_state;
    
    // BCD conversion logic: Convert a 16-bit number to BCD (4 decimal digits)
    wire [3:0] bcd1, bcd10, bcd100, bcd1000;

    bcd_converter A(
        .binary(product),
        .bcd1(bcd1),
        .bcd10(bcd10),
        .bcd100(bcd100),
        .bcd1000(bcd1000)
    );

    // Combinational logic for state transitions and output logic
    always @* begin
        // Default values for outputs
        next_state = state;    // Default to the current state
        LEDR = 10'b0;          // Default LEDR output

        case (state)
            IDLE: begin
                if (btn_reg && !btn_reg_d) begin
                    next_state = FIRST_NUM;
                end
                LEDR = 10'b0000000001;  
					 num1 <= 10'b0;
					 num2 <= 10'b0;
					 mul_result <= 32'b0;
            end

            FIRST_NUM: begin
                if (btn_reg && !btn_reg_d) begin
                    num1 = SW[9:0];  
                    next_state = NEXT_NUM;
                end
                LEDR = 10'b0000000010;  // LEDR indicates FIRST_NUM state
            end

            NEXT_NUM: begin
                if (btn_reg && !btn_reg_d) begin
                    num2 = SW[9:0];  
                    mul_result = num1 * num2;
						  num1 = mul_result;  
                    
                    // Check for overflow (if the result is greater than 9999)
                    if (mul_result > 9999) begin
                        next_state = ERROR;
                    end else begin
                        next_state = NEXT_NUM;  // Doesn't change state unless reset or error.
                    end
                end
                LEDR = 10'b0000000100;  // LEDR indicates NEXT_NUM state
            end

            ERROR: begin
                LEDR = 10'b0000001000;  // LEDR indicates ERROR state
                next_state = IDLE;  // Return to IDLE state after error
            end

            default: begin
                next_state = IDLE;  // Default to IDLE state if unknown state
            end
        endcase
    end

    // Sequential logic for state updates and storing the first number and cumulative product
    always @(posedge MAX10_CLK1_50 or posedge !KEY[1]) begin
        if (!KEY[1]) begin
            state <= IDLE;
            product <= 16'b0;
            btn_reg <= 0;
            btn_reg_d <= 0;
        end else begin
            state <= next_state;  // Update state
            btn_reg <= KEY[0];
            btn_reg_d <= btn_reg;
				
		  if (state == NEXT_NUM) begin
            if (mul_result <= 9999) begin
                product <= mul_result[15:0];  // Store the product if no overflow
            end else begin
                product <= 16'b0;  // Reset product in error state
            end
        end else if (state == ERROR) begin
            product <= 16'b0;  // Reset product in error state
        end
        end
    end

    // 7-segment display logic for showing the product or error state
    always @(posedge MAX10_CLK1_50) begin
        if (state == ERROR) begin
            HEX0 <= 8'b00000000;  // Display error (empty display)
            HEX1 <= 8'b00000000;
            HEX2 <= 8'b00000000;
				HEX3 <= 8'b00000000;
            HEX4 <= 8'b00000000;
				HEX5 <= 8'b00000000;
        end else begin
            // Display the BCD digits on the 7-segment displays
            HEX0 <= get_segment(bcd1);  // Least significant digit (ones)
            HEX1 <= get_segment(bcd10);  // Tens place
            HEX2 <= get_segment(bcd100);  // Hundreds place
            HEX3 <= get_segment(bcd1000);  // Thousands place;
        end
    end

    // Function to convert a BCD digit to the corresponding 7-segment code
    function [7:0] get_segment;
        input [3:0] bcd;
        begin
            case (bcd)
					4'd0: get_segment = 8'b11000000;  // Display 0
					4'd1: get_segment = 8'b11111001;  // Display 1
					4'd2: get_segment = 8'b10100100;  // Display 2
					4'd3: get_segment = 8'b10110000;  // Display 3
					4'd4: get_segment = 8'b10011001;  // Display 4
					4'd5: get_segment = 8'b10010010;  // Display 5
					4'd6: get_segment = 8'b10000010;  // Display 6
					4'd7: get_segment = 8'b11111000;  // Display 7
					4'd8: get_segment = 8'b10000000;  // Display 8
					4'd9: get_segment = 8'b10010000;  // Display 9
					default: get_segment = 8'b11111111;
            endcase
        end
    endfunction

    // Button debouncing task
    task debounce_btn(input KEY0, output reg stable_btn);
        reg [3:0] btn_sync;  // Synchronize the button signal with the clock
        reg [15:0] counter;  // Counter for debounce timing
        begin
            btn_sync = {btn_sync[2:0], KEY0};  // Shift previous state into the register
            if (btn_sync[3] == btn_sync[2]) begin
                if (counter == 16'd49999) begin  // 50000 cycles for debounce (adjust as needed)
                    stable_btn = btn_sync[3];  // Stable button state
                end else begin
                    counter = counter + 1;  // Increment the counter
                    stable_btn = btn_sync[3];  // Continue holding the previous stable state
                end
            end else begin
                counter = 16'b0;  // Reset counter if the button changes state
                stable_btn = btn_sync[3];  // Hold the previous stable state
            end
        end
    endtask

endmodule

// BCD converter module to convert binary to BCD
module bcd_converter (
    input [15:0] binary,  // 16-bit binary number
    output reg [3:0] bcd1, // BCD digit for ones place
    output reg [3:0] bcd10, // BCD digit for tens place
    output reg [3:0] bcd100, // BCD digit for hundreds place
    output reg [3:0] bcd1000  // BCD digit for thousands place
);
    integer i;
    always @(binary) begin
        bcd1 = 4'b0000;
        bcd10 = 4'b0000;
        bcd100 = 4'b0000;
        bcd1000 = 4'b0000;
        
        for (i = 15; i >= 0; i = i - 1) begin
            if (bcd1000 >= 5) bcd1000 = bcd1000 + 3;
            if (bcd100 >= 5) bcd100 = bcd100 + 3;
            if (bcd10 >= 5) bcd10 = bcd10 + 3;
            if (bcd1 >= 5) bcd1 = bcd1 + 3;
            
            bcd1000 = bcd1000 << 1;
            bcd1000[0] = bcd100[3];
            bcd100 = bcd100 << 1;
            bcd100[0] = bcd100[3];
            bcd10 = bcd10 << 1;
            bcd10[0] = bcd10[3];
            bcd1 = bcd1 << 1;
            bcd1[0] = binary[i];
        end
    end
endmodule
