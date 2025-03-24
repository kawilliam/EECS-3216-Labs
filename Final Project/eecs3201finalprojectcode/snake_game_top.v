module snake_game_top(
    input wire MAX10_CLK1_50,  // 50 MHz clock from the DE10-Lite board
    input wire [1:0] KEY,	 // Keys for reset and user input
	 input wire [0:0] SW,
    output wire VGA_HS,        // Horizontal sync signal
    output wire VGA_VS,        // Vertical sync signal
    output wire [3:0] VGA_R,   // Red VGA output
    output wire [3:0] VGA_G,   // Green VGA output
    output wire [3:0] VGA_B   // Blue VGA output
);

// Invert reset signal (active low)
wire reset_n = SW[0];
wire reset = ~reset_n;

// Generate 25 MHz VGA clock using PLL
wire VGA_CLK;
wire locked;
vga_pll u1(
    .areset(~reset_n),
    .inclk0(MAX10_CLK1_50),
    .c0(VGA_CLK),
    .locked(locked)
);

// VGA sync signals and counters
wire blank_n;
wire HS;
wire VS;
wire [10:0] h_cnt;
wire [9:0] v_cnt;

// Instantiate VGA sync generator
video_sync_generator vga_sync_inst(
    .reset(reset),
    .vga_clk(VGA_CLK),
    .blank_n(blank_n),
    .HS(HS),
    .VS(VS),
    .h_cnt(h_cnt),
    .v_cnt(v_cnt)
);

// Map pixel positions to grid positions
wire [6:0] grid_x;
wire [5:0] grid_y;

gridalizer grid_inst(
    .grid_x(grid_x),
    .grid_y(grid_y),
    .pos_h(h_cnt),
    .pos_v(v_cnt),
    .clk(VGA_CLK)
);

// Generate apple position
wire [5:0] appleX;
wire [4:0] appleY;

apple_generator apple_gen_inst(
    .clk(VGA_CLK),
    .x_pos(appleX),
    .y_pos(appleY)
);
 // Concatenate foodx and foody to form curApple 
 reg [10:0] curApple; 
 always @(posedge VGA_CLK or posedge reset) begin 
 if (reset) begin 
	curApple <= {appleY, appleX}; // Initial apple position 
 end 
 else if (generate_new_apple) begin 
	curApple <= {appleY, appleX}; // Update apple position 
	end 
end   
// User input handling (debounced)
wire clockwise_input_raw = ~KEY[0]; // Use KEY[1] for user input
wire clockwise_input;

wire counterclockwise_input_raw = ~KEY[1]; // Use KEY[1] for user input
wire counterclockwise_input;


debounce_and_oneshot debounce_inst_cw(
    .debounce_out(clockwise_input),
    .debounce_in(clockwise_input_raw),
    .clk_50MHz(MAX10_CLK1_50),
    .rst(reset)
);
debounce_and_oneshot debounce_inst_ccw(
    .debounce_out(counterclockwise_input),
    .debounce_in(counterclockwise_input_raw),
    .clk_50MHz(MAX10_CLK1_50),
    .rst(reset)
);
// Direction handling
wire [1:0] direction;

directionizer dir_inst(
    .clk(MAX10_CLK1_50),
    .clockwise(clockwise_input),
    .counterclockwise(counterclockwise_input),
    .direction(direction),
    .reset(reset)
);

// Generate movement pulses based on snake length
wire move_pulse;
reg [2:0] snake_length;

pulser pulser_inst(
    .p(move_pulse),
    .clk(MAX10_CLK1_50),
    .len(snake_length),
    .reset(reset)
);

// Snake positions
reg [10:0] snake[0:9]; // 32 snake segments ; changed to 10 for now

integer i;

// Snake movement logic
always @(posedge move_pulse or posedge reset)
begin
    if (reset)
    begin
        // Initialize snake
        snake_length <= 3'd1; //0001
        snake[0] <= {5'd2, 6'd2}; // Initial position at grid_x=20, grid_y=15
        for (i = 1; i < 10; i = i + 1)
            snake[i] <= 11'd0;
    end
    else
    begin
        // Shift snake segments
        for (i = 9; i > 0; i = i - 1)
		  begin
				if (i <= snake_length)
					snake[i] <= snake[i - 1];
				end

        // Move snake head based on direction
        case (direction)
            2'd0: snake[0][10:6] <= snake[0][10:6] - 1; // Up
            2'd1: snake[0][5:0]  <= snake[0][5:0] + 1;  // Right
            2'd2: snake[0][10:6] <= snake[0][10:6] + 1; // Down
            2'd3: snake[0][5:0]  <= snake[0][5:0] - 1;  // Left
        endcase

        // Collision with apple
        if (snake[0] == curApple)
        begin
            if (snake_length < 9) begin
                snake_length <= snake_length + 1;
				end
				//snake[i] <= snake[i+1];
        end
    end
end

// VGA rectangle rendering
wire red;
wire green;
wire blue;
wire [5:0] CurAppleX;
wire [4:0] CurAppleY;

vga_rectangle vga_rect_inst(
    .red(red),
    .green(green),
    .blue(blue),
    .grid_x(grid_x),
    .grid_y(grid_y),
    .blank(~blank_n),
    .clk(VGA_CLK),
    .appleX(appleX),
    .appleY(appleY),
    .snake0(snake[0]),
    .snake1(snake[1]),
    .snake2(snake[2]),
    .snake3(snake[3]),
    .snake4(snake[4]),
    .snake5(snake[5]),
    .snake6(snake[6]),
    .snake7(snake[7]),
    .snake8(snake[8]),
    .snake9(snake[9]),
    .reset(reset),
    .CurAppleX(CurAppleX),
    .CurAppleY(CurAppleY)
);

// Assign VGA outputs
assign VGA_HS = HS;
assign VGA_VS = VS;
assign VGA_R = {4{red}};
assign VGA_G = {4{green}};
assign VGA_B = {4{blue}};

endmodule



