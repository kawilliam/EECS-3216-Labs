module snake_game(
    input logic clk,           // 50MHz system clock
    input logic reset_n,       // Active low reset
    input logic [1:0] KEY,     // Direction control keys
    input logic [9:0] SW,      // Switches, SW[0] controls border visibility
    output logic [3:0] VGA_R,  // VGA Red channel
    output logic [3:0] VGA_G,  // VGA Green channel
    output logic [3:0] VGA_B,  // VGA Blue channel
    output logic VGA_HS,       // Horizontal sync
    output logic VGA_VS,        // Vertical sync
	 output logic [$clog2(GRID_WIDTH*GRID_HEIGHT)-1:0] score
);

    // VGA Parameters for 1920x1080 @60Hz
    parameter H_PIXELS = 640;
    parameter H_FP = 16;
    parameter H_PULSE = 96;
    parameter H_BP = 48;
    parameter V_PIXELS = 480;
    parameter V_FP = 10;
    parameter V_PULSE = 2;
    parameter V_BP = 33;
    
    // Game parameters
    parameter GRID_SIZE = 20;                        // Size of each grid cell
    parameter GRID_WIDTH = 32;                       // Number of grid cells horizontally (1920/20)
    parameter GRID_HEIGHT = 24;                      // Number of grid cells vertically (1080/20)
    parameter BORDER_SIZE = 1;                       // Border thickness in grid cells
    parameter INIT_SNAKE_LEN = 1;                    // Initial snake length
    parameter GAME_SPEED_MAX = 12000000;             // Slowest game speed (higher = slower)
    parameter GAME_SPEED_MIN = 3000000;              // Fastest game speed (lower = faster)
    parameter GAME_SPEED_DECREMENT = 500000;         // Speed increase per apple eaten
    parameter MAX_SNAKE_LENGTH = 100;
    
    // Color definitions (4-bit RGB)
    parameter [11:0] COLOR_BLACK = 12'h000;          // Background
    parameter [11:0] COLOR_GREEN = 12'h0F0;          // Snake
    parameter [11:0] COLOR_RED = 12'hF00;            // Apple
    parameter [11:0] COLOR_BLUE = 12'h00F;           // Border
    parameter [11:0] COLOR_DARK_GREEN = 12'h080;     // Snake body
    
    // Direction definitions
    typedef enum logic [1:0] {
        DIR_RIGHT = 2'b00,
        DIR_DOWN  = 2'b01,
        DIR_LEFT  = 2'b10,
        DIR_UP    = 2'b11
    } direction_t;
    
    // Game state
    typedef enum logic [1:0] {
        IDLE,
        RUNNING,
        GAME_OVER
    } game_state_t;
    
    // Pixel clock generation (25MHz for VGA)
    logic pixel_clk;
    logic clk_div;
    
    always_ff @(posedge clk or negedge reset_n) begin
        if (~reset_n) 
            clk_div <= 0;
        else
            clk_div <= ~clk_div;
    end
    
    assign pixel_clk = clk_div;
    
    // VGA controller signals
    logic vga_disp_ena;
    logic [31:0] vga_column;
    logic [31:0] vga_row;
    
    // Game variables
    game_state_t game_state;
    direction_t curr_direction, next_direction;
	logic [$clog2(GRID_WIDTH)-1:0]  snake_x [0:GRID_WIDTH*GRID_HEIGHT-1];
	logic [$clog2(GRID_HEIGHT)-1:0] snake_y [0:GRID_WIDTH*GRID_HEIGHT-1];
    logic [100:0] snake_length;                // Current snake length
    logic [$clog2(GRID_WIDTH)-1:0] apple_x;          // Apple X position
    logic [$clog2(GRID_HEIGHT)-1:0] apple_y;         // Apple Y position
    logic [$clog2(GAME_SPEED_MAX):0] move_counter;   // Counter for snake movement speed
    logic [$clog2(GAME_SPEED_MAX):0] game_speed;     // Current game speed
    logic game_tick;                                 // Pulses when snake should move
    logic collision_border;                          // Flag for border collision
    logic collision_self;                            // Flag for self collision
    logic apple_eaten;                               // Flag for apple eaten
    logic border_visible;                            // Border visibility flag

    
    // LFSR for random number generation
    logic [15:0] lfsr;
    
    // VGA Controller instantiation
    vga_controller #(
        .h_pixels(H_PIXELS),
        .h_fp(H_FP),
        .h_pulse(H_PULSE),
        .h_bp(H_BP),
        .v_pixels(V_PIXELS),
        .v_fp(V_FP),
        .v_pulse(V_PULSE),
        .v_bp(V_BP)
    ) vga_inst (
        .pixel_clk(pixel_clk),
        .reset_n(reset_n),
        .h_sync(VGA_HS),
        .v_sync(VGA_VS),
        .disp_ena(vga_disp_ena),
        .column(vga_column),
        .row(vga_row)
    );
    
    // LFSR implementation for pseudo-random numbers
    always_ff @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            lfsr <= 16'hACE1;  // Initial seed
        end else begin
            lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
        end
    end
    
    // Game tick generator
    always_ff @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            move_counter <= 0;
            game_tick <= 0;
        end else begin
            if (move_counter >= game_speed) begin
                move_counter <= 0;
                game_tick <= 1;
            end else begin
                move_counter <= move_counter + 1;
                game_tick <= 0;
            end
        end
    end
    
    // Direction control - using asynchronous reset
			always_ff @(posedge clk or negedge reset_n) begin
				 if (~reset_n) begin
					  // Reset on global reset or game over
					  curr_direction <= DIR_RIGHT;
					  next_direction <= DIR_RIGHT;
				 end else if (game_state == RUNNING) begin
					  // Handle key presses
					  if (KEY[0]) begin
							// Rotate clockwise
							case (curr_direction)
								 DIR_UP:    next_direction <= DIR_RIGHT;
								 DIR_RIGHT: next_direction <= DIR_DOWN;
								 DIR_DOWN:  next_direction <= DIR_LEFT;
								 DIR_LEFT:  next_direction <= DIR_UP;
							endcase
					  end else if (KEY[1]) begin
							// Rotate counter-clockwise
							case (curr_direction)
								 DIR_UP:    next_direction <= DIR_LEFT;
								 DIR_LEFT:  next_direction <= DIR_DOWN;
								 DIR_DOWN:  next_direction <= DIR_RIGHT;
								 DIR_RIGHT: next_direction <= DIR_UP;
							endcase
					  end
					// Immediate direction update on pulse
					if (game_tick) begin
						curr_direction <= next_direction;
					end
				 end
			end

    
    // Border visibility toggle - using asynchronous reset
    always_ff @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            border_visible <= 1'b1;  // Border visible by default
        end else begin
            border_visible <= SW[0];  // SW[0] controls border visibility
        end
    end
    
    // Snake movement and game logic - using asynchronous reset
    always_ff @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            // Initialize game state
            game_state <= IDLE;
            snake_length <= INIT_SNAKE_LEN;
            game_speed <= GAME_SPEED_MAX;
            score <= 0;
            
            // Initialize snake position (center of screen, pointing right)
            snake_x[0] <= GRID_WIDTH / 2;
            snake_y[0] <= GRID_HEIGHT / 2;
            // snake_x[1] <= (GRID_WIDTH / 2) - 1;
            // snake_y[1] <= GRID_HEIGHT / 2;
				
			   // Clear all other segments to unused positions (e.g., 0)
				for (int i = 1; i < MAX_SNAKE_LENGTH; i++) begin
					snake_x[i] <= 0;
					snake_y[i] <= 0;
				end
            
            // Initialize apple position
            apple_x <= (GRID_WIDTH / 4);
            apple_y <= (GRID_HEIGHT / 4);
            
            apple_eaten <= 0;
            collision_border <= 0;
            collision_self <= 0;
        end else begin
            // Default values
            apple_eaten <= 0;
            collision_border <= 0;
            collision_self <= 0;
            
            case (game_state)
                IDLE: begin
                    // Start game
                    game_state <= RUNNING;
                end
                
                RUNNING: begin
                    if (game_tick) begin
                        // Move snake body (shift all segments)
                       for (int i = 0; i < MAX_SNAKE_LENGTH; i++) begin
										if (i < snake_length) begin
											if (i == 0) begin
										// Move head based on direction (handled in case statement)
										end else begin
											snake_x[i] <= snake_x[i-1];
											snake_y[i] <= snake_y[i-1];
										end
									end
								end
                        
                        // Move snake head based on direction
                        case (curr_direction)
                            DIR_RIGHT: snake_x[0] <= snake_x[0] + 1;
                            DIR_LEFT:  snake_x[0] <= snake_x[0] - 1;
                            DIR_DOWN:  snake_y[0] <= snake_y[0] + 1;
                            DIR_UP:    snake_y[0] <= snake_y[0] - 1;
                        endcase
                        
                        // Check for border collision
                        if (border_visible && (
                            (snake_x[0] == BORDER_SIZE - 1 && curr_direction == DIR_LEFT) ||
                            (snake_x[0] == GRID_WIDTH - BORDER_SIZE && curr_direction == DIR_RIGHT) ||
                            (snake_y[0] == BORDER_SIZE - 1 && curr_direction == DIR_UP) ||
                            (snake_y[0] == GRID_HEIGHT - BORDER_SIZE && curr_direction == DIR_DOWN)
                        )) begin
                            collision_border <= 1;
                            game_state <= GAME_OVER;
                        end
                        
                        // Check for self collision 
                        for (int i = 1; i < MAX_SNAKE_LENGTH; i++) begin
									if (snake_x[0] == snake_x[i] && snake_y[0] == snake_y[i]) begin
										collision_self <= 1;
										game_state <= GAME_OVER;
									end
								end
                        
                        // Check if apple is eaten
								if (snake_x[0] == apple_x && snake_y[0] == apple_y) begin
									 // Declare variables at the beginning of the block
									 logic valid_position;
									 logic [$clog2(GRID_WIDTH)-1:0] new_x;
									 logic [$clog2(GRID_HEIGHT)-1:0] new_y;

									 apple_eaten <= 1;
									 
									 // Increase snake length
									 if (snake_length < GRID_WIDTH*GRID_HEIGHT - 1) begin
										  snake_length <= snake_length + 1;
									 end
									 
									 // Increase score
									 score <= score + 1;
									 
									 // Generate new apple position
									 // Use LFSR to generate random positions
									 new_x = (lfsr[7:0] % (GRID_WIDTH - 2*BORDER_SIZE)) + BORDER_SIZE;
									 new_y = (lfsr[15:8] % (GRID_HEIGHT - 2*BORDER_SIZE)) + BORDER_SIZE;
									 
									 // Check if position is valid (not on snake)
									 valid_position = 1;
									 for (int i = 0; i < MAX_SNAKE_LENGTH; i++) begin
										if (new_x == snake_x[i] && new_y == snake_y[i]) begin
											valid_position = 0;
											end
									 end
									 
									 if (valid_position) begin
										  apple_x <= new_x;
										  apple_y <= new_y;
									 end else begin
										  // If invalid, try a different position by shifting
										  apple_x <= ((new_x + 3) % (GRID_WIDTH - 2*BORDER_SIZE)) + BORDER_SIZE;
										  apple_y <= ((new_y + 5) % (GRID_HEIGHT - 2*BORDER_SIZE)) + BORDER_SIZE;
									 end
									 
									 // Increase game speed (decrease delay)
									 if (game_speed > GAME_SPEED_MIN + GAME_SPEED_DECREMENT) begin
										  game_speed <= game_speed - GAME_SPEED_DECREMENT;
									 end
								end
                    end
                end
                
                GAME_OVER: begin
                    // Reset the game after a brief delay
                    if (move_counter >= GAME_SPEED_MAX) begin
                        // Reset game state
                        game_state <= IDLE;
                        snake_length <= INIT_SNAKE_LEN;
                        game_speed <= GAME_SPEED_MAX;
                        score <= 0;
                        
                    end
                end
            endcase
        end
    end
    
    // VGA Output
    logic [11:0] pixel_color;
    logic is_border, is_snake_head, is_snake_body, is_apple;
    logic [$clog2(GRID_WIDTH)-1:0] grid_x;
    logic [$clog2(GRID_HEIGHT)-1:0] grid_y;
    
    // Determine what to display at current pixel
    always_comb begin
        // Default - black background
        pixel_color = COLOR_BLACK;
        
        // Calculate grid position of current pixel
        grid_x = vga_column / GRID_SIZE;
        grid_y = vga_row / GRID_SIZE;
        
        // Check if current pixel is in the border
        is_border = border_visible && (
            grid_x < BORDER_SIZE || 
            grid_x >= GRID_WIDTH - BORDER_SIZE || 
            grid_y < BORDER_SIZE || 
            grid_y >= GRID_HEIGHT - BORDER_SIZE
        );
        
        // Check if current pixel is the snake head
        is_snake_head = (grid_x == snake_x[0] && grid_y == snake_y[0]);
        
        // Check if current pixel is snake body
        is_snake_body = 0;
        for (int i = 1; i < MAX_SNAKE_LENGTH; i++) begin
            if (grid_x == snake_x[i] && grid_y == snake_y[i]) begin
                is_snake_body = 1;
            end
        end
        
        // Check if current pixel is the apple
        is_apple = (grid_x == apple_x && grid_y == apple_y);
        
        // Set pixel color based on what it represents
        if (is_border) begin
            pixel_color = COLOR_BLUE;
        end else if (is_snake_head) begin
            pixel_color = COLOR_GREEN;
        end else if (is_snake_body) begin
            pixel_color = COLOR_DARK_GREEN;
        end else if (is_apple) begin
            pixel_color = COLOR_RED;
        end
    end
    
    // Drive VGA outputs - using asynchronous reset
    always_ff @(posedge pixel_clk or negedge reset_n) begin
        if (~reset_n) begin
            VGA_R <= 4'h0;
            VGA_G <= 4'h0;
            VGA_B <= 4'h0;
        end else if (vga_disp_ena) begin
            VGA_R <= pixel_color[11:8];
            VGA_G <= pixel_color[7:4];
            VGA_B <= pixel_color[3:0];
        end else begin
            VGA_R <= 4'h0;
            VGA_G <= 4'h0;
            VGA_B <= 4'h0;
        end
    end

endmodule