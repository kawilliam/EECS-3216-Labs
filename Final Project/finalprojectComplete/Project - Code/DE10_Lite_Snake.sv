module DE10_Lite_Snake(
    ///////// CLOCK /////////
    input logic           ADC_CLK_10,
    input logic           MAX10_CLK1_50,
    input logic           MAX10_CLK2_50,

    ///////// KEY /////////
    input logic  [1:0]    KEY,

    ///////// SW /////////
    input logic  [9:0]    SW,

    ///////// LEDR /////////
    output logic [9:0]    LEDR,

    ///////// HEX /////////
    output logic [7:0]    HEX0,
    output logic [7:0]    HEX1,
    output logic [7:0]    HEX2,
    output logic [7:0]    HEX3,
    output logic [7:0]    HEX4,
    output logic [7:0]    HEX5,

    ///////// VGA /////////
    output logic [3:0]    VGA_R,
    output logic [3:0]    VGA_G,
    output logic [3:0]    VGA_B,
    output logic          VGA_HS,
    output logic          VGA_VS
);

    // Debounced key signals
    logic key0_pulse, key1_pulse;
	 logic key0_stable, key1_stable;
    logic rst_sync;
	 
	 // Score
	 logic [9:0] score;
	 logic [3:0] bcd_hundreds, bcd_tens, bcd_units;
	 
	 always_comb begin
        bcd_units = score % 10;          // Units digit
        bcd_tens = (score / 10) % 10;    // Tens digit
        bcd_hundreds = (score / 100) % 10; // Hundreds digit
    end
	 
	     // Function to convert BCD digit to 7-segment (active-low)
    function logic [7:0] bcd_to_seg(input [3:0] bcd);
        case (bcd)
            4'd0: bcd_to_seg = 8'b11000000; // 0
            4'd1: bcd_to_seg = 8'b11111001; // 1
            4'd2: bcd_to_seg = 8'b10100100; // 2
            4'd3: bcd_to_seg = 8'b10110000; // 3
            4'd4: bcd_to_seg = 8'b10011001; // 4
            4'd5: bcd_to_seg = 8'b10010010; // 5
            4'd6: bcd_to_seg = 8'b10000010; // 6
            4'd7: bcd_to_seg = 8'b11111000; // 7
            4'd8: bcd_to_seg = 8'b10000000; // 8
            4'd9: bcd_to_seg = 8'b10010000; // 9
            default: bcd_to_seg = 8'b11111111; // Off
        endcase
    endfunction
	 
    // Synchronize reset
    always_ff @(posedge MAX10_CLK1_50) begin
        rst_sync <= ~SW[0];  // Active-high synchronized reset
    end
	 
    // Debounce KEY[0]
    button_debounce db_key0 (
        .clk(MAX10_CLK1_50),
        .rst(rst_sync),
        .button(~KEY[0]),     // Invert active-low KEY[0]
        .pulse(key0_pulse),   // For direction control
        .stable(key0_stable)  // For LED
    );

    // Debounce KEY[1]
    button_debounce db_key1 (
        .clk(MAX10_CLK1_50),
        .rst(rst_sync),
        .button(~KEY[1]),     // Invert active-low KEY[1]
        .pulse(key1_pulse),   // For direction control
        .stable(key1_stable)  // For LED
    );

    // Connect to LEDs (LEDR[1] and LEDR[2])
    assign LEDR[1] = key0_stable;  // KEY[0] pressed → LEDR[1] on
    assign LEDR[2] = key1_stable;  // KEY[1] pressed → LEDR[2] on
	 
	 // Turn off all HEX displays (active low)
    assign HEX0 = 8'hFF;
    assign HEX1 = 8'hFF;
    assign HEX2 = 8'hFF;
	 
    assign HEX3 = bcd_to_seg(bcd_units); // Hundreds place
    assign HEX4 = bcd_to_seg(bcd_tens);     // Tens place
    assign HEX5 = bcd_to_seg(bcd_hundreds);
	 
    // Connect the Snake Game module to the top-level module
    snake_game snake_inst(
        .clk(MAX10_CLK1_50),      // Use the 50MHz clock
        .reset_n(SW[0]),          // SW up is on, down off/reset
        .KEY({key1_pulse, key0_pulse}), // Direction control keys
        .SW(SW),                  // Switches for border visibility
        .VGA_R(VGA_R),            // VGA Red channel
        .VGA_G(VGA_G),            // VGA Green channel
        .VGA_B(VGA_B),            // VGA Blue channel
        .VGA_HS(VGA_HS),          // Horizontal sync
        .VGA_VS(VGA_VS),           // Vertical sync
		  .score(score)
    );
    
    // Display the border status on LEDR[0]
    assign LEDR[0] = SW[0];
    

    
    // Turn off unused LEDs
    assign LEDR[9:3] = 9'b0;

endmodule