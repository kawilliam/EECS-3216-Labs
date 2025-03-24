module gridalizer(
    output reg [5:0] grid_x,
    output reg [4:0] grid_y,
    input [10:0] pos_h,
    input [9:0] pos_v,
    input clk
);

    // Assuming grid size of 40x30 (adjust as needed)
    parameter GRID_WIDTH = 80;
    parameter GRID_HEIGHT = 120;
    parameter PIXELS_PER_GRID_X = 8; // 640 / 40
    parameter PIXELS_PER_GRID_Y = 12; // 480 / 30

    always @(posedge clk)
    begin
        if (pos_h < (GRID_WIDTH * PIXELS_PER_GRID_X))
            grid_x <= pos_h / PIXELS_PER_GRID_X;
        else
            grid_x <= GRID_WIDTH - 1;

        if (pos_v < (GRID_HEIGHT * PIXELS_PER_GRID_Y))
            grid_y <= pos_v / PIXELS_PER_GRID_Y;
        else
            grid_y <= GRID_HEIGHT - 1;
    end

endmodule


