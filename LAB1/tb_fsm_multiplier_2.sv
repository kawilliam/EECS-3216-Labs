module tb_fsm_multiplier_2;

    // Inputs to the fsm_multiplier module
    reg MAX10_CLK1_50;
    reg [1:0] KEY;
    reg [9:0] SW;

    // Outputs from the fsm_multiplier module
    wire [3:0] state;
    wire [15:0] product;
    wire [7:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    wire [9:0] LEDR;

    // Instantiate the fsm_multiplier module
    fsm_multiplier_sim uut (
        .MAX10_CLK1_50(MAX10_CLK1_50),
        .KEY(KEY),
        .SW(SW),
        .state(state),
        .product(product),
        .HEX0(HEX0),
        .HEX1(HEX1),
        .HEX2(HEX2),
        .HEX3(HEX3),
        .HEX4(HEX4),
        .HEX5(HEX5),
        .LEDR(LEDR)
    );
	 
    // Clock generation
    initial begin
        MAX10_CLK1_50 = 0;
        forever #1 MAX10_CLK1_50 = ~MAX10_CLK1_50; // 50 MHz clock
    end

    // Stimulus generation
    initial begin
        // Initialize inputs
		  
		  #50  KEY = 2'b01;  // Change mode to ADD (press KEY[1])
        #50  KEY = 2'b11;  // Release KEY[1]
		  
        KEY = 2'b11;  // Both keys not pressed (active-low, so 1 is not pressed)
        SW = 10'b0000000001; // Initialize switches

        // Apply stimulus
        #50  KEY = 2'b10;  // Simulate pressing KEY[0] to start the multiplication (active-low)
        #50  KEY = 2'b11;  // Release KEY[0]
        SW = 10'b0000010100; // Set first number to 20
        #50  KEY = 2'b10;  // Simulate pressing KEY[0] to enter second number
        #50  KEY = 2'b11;  // Release KEY[0]
        SW = 10'b0000000011; // Set second number to 3
        #50  KEY = 2'b10;  // Simulate pressing KEY[0] to compute the result
        #50  KEY = 2'b11;  // Release KEY[0]

        // Switch modes
        #50  KEY = 2'b01;  // Change mode to ADD (press KEY[1])
        #50  KEY = 2'b11;  // Release KEY[1]

        // Test other operations
        #50 KEY = 2'b10;  // Start multiplication (active-low)
        #50 KEY = 2'b11;  // Release KEY[0]
        SW = 10'b0000010100; // Set first number to 20
        #50 KEY = 2'b10;  // Set second number to 3
        #50 KEY = 2'b11;  // Release KEY[0]
        SW = 10'b0000000011; // Set second number to 3
        #50 KEY = 2'b10;  // Simulate pressing KEY[0] to compute the result
        #50 KEY = 2'b11;  // Release KEY[0]

        // Test error handling with division by zero
        #50 KEY = 2'b10;  // Simulate pressing KEY[0] to start operation
        #50 KEY = 2'b11;  // Release KEY[0]
        SW = 10'b0000010100; // Set first number to 20
        #50 KEY = 2'b10;  // Simulate pressing KEY[0] to enter second number
        #50 KEY = 2'b11;  // Release KEY[0]
        SW = 10'b0000000000; // Set second number to 0 (division by zero)

        // End simulation after some time
        #100 $finish;
    end

    // Monitor signals
    initial begin
        $monitor("Time=%0t, state=%b, product=%d, HEX0=%b, HEX1=%b, HEX2=%b, HEX3=%b, HEX4=%b, HEX5=%b, LEDR=%b",
                 $time, state, product, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, LEDR);
    end

endmodule
