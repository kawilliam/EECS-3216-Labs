module snake_game_tb();
    // Testbench signals
    logic clk;
    logic reset_n;
    logic [1:0] KEY;
    logic [9:0] SW;
    logic [3:0] VGA_R;
    logic [3:0] VGA_G;
    logic [3:0] VGA_B;
    logic VGA_HS;
    logic VGA_VS;
    
    // Instantiate the snake game module
    snake_game dut(
        .clk(clk),
        .reset_n(reset_n),
        .KEY(KEY),
        .SW(SW),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #10 clk = ~clk; // 50MHz clock
    end
    
    // Test sequence
    initial begin
        // Initialize signals
        reset_n = 0;
        KEY = 2'b11; // No buttons pressed
        SW = 10'b0000000001; // Border visible
        
        // Apply reset
        #20 reset_n = 1;
        
        // Wait for game to start
        #1000;
        
        // Test button presses - turn left (counter-clockwise)
        #1000 KEY[1] = 0; // Press KEY[1]
        #50 KEY[1] = 1;   // Release KEY[1]
        
        // Wait for snake to move in the new direction
        #3000;
        
        // Test button presses - turn right (clockwise)
        #1000 KEY[0] = 0; // Press KEY[0]
        #50 KEY[0] = 1;   // Release KEY[0]
        
        // Wait for snake to move in the new direction
        #3000;
        
        // Toggle border visibility
        SW[0] = 0; // Hide border
        
        // Continue simulation
        #10000;
        
        // End simulation
        $finish;
    end
    
    // Optional: VGA signal monitoring
    initial begin
        $monitor("Time=%0t: VGA_HS=%b VGA_VS=%b", $time, VGA_HS, VGA_VS);
    end

endmodule