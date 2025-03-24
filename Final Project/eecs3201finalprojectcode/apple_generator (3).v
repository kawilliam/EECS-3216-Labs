module apple_generator(
    input clk,
	 input generate_new,
    output reg [5:0] x_pos,
    output reg [4:0] y_pos
);

    reg [7:0] rand;

    initial begin
        x_pos = 10;
        y_pos = 10;
        rand = 8'hFF; // Initial seed
    end

    always @(posedge clk)
    begin
        rand <= rand + 8'h13; // Simple LFSR for randomness
        x_pos <= (rand % 38); // Grid width
        y_pos <= (rand % 28); // Grid height
    end

endmodule