`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////

// Company:

// Engineer:

//

// Create Date:    19:39:32 10/25/2017

// Design Name:

// Module Name:    directionizer

// Project Name:

// Target Devices:

// Tool versions:

// Description:

//

// Dependencies:

//

// Revision:

// Revision 0.01 - File Created

// Additional Comments:

//

//////////////////////////////////////////////////////////////////////////////////

module directionizer(

    input clk,

    input clockwise,

    input counterclockwise,

    output reg [1:0] direction,

       input reset

    );

 

       reg [1:0] last;

       

      always @(posedge clk, posedge reset) begin

           if(reset) begin

                 direction <= 2; // initally moving downwards

           end

           // check the current direction and update the new direction

           else if(clockwise) begin

           case (last)

                 0: direction <= 1; // if was upwards, now rightwards

                 1: direction <= 2; // if was rightwards, now downwards

                 2: direction <= 1; // if was downwards, now rightwards

                 3: direction <= 0; // if was leftwards, now upwards

           endcase

           end

           else if (counterclockwise)begin

           case (last) // same scheme as clockwise

                 0: direction <= 3;

                 1: direction <= 0;

                 2: direction <= 3;

                 3: direction <= 2;

           endcase

           end

           else begin

                 direction <= last;

           end  

      end

     

      always @(direction) begin

           last = direction; // update the current direction from the new direction

      end

endmodule