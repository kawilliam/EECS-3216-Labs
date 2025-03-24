module debounce_and_oneshot(
    output reg debounce_out,
    input debounce_in,
    input clk_50MHz,
    input rst
    );

parameter MINWIDTH = 5000000; //how many cycles must the debounce_in be pressed
parameter COUNTERWIDTH = 32;

reg [COUNTERWIDTH-1:0] counter;
//reg [COUNTERWIDTH-1:0] new_counter;

reg shot;

always @(posedge clk_50MHz, posedge rst) begin
  if (rst) begin
    counter <= 0;
    debounce_out <= 1'b0; 
    shot <= 1'b0; 
  end else begin
         if (~debounce_in) begin
               counter <= 0;
               debounce_out <= 1'b0;
          shot <= 1'b0; 
      end else if (counter!=MINWIDTH) begin
               counter<=counter+1;
               debounce_out <= 1'b0;
          shot <= 1'b0; 
      end else begin //we have reached MINWIDTH
                  counter<=counter;
               if (shot == 0) begin
                    shot <= 1'b1;
                  debounce_out<=1'b1;
                  end else begin
                       shot <= shot;
                  debounce_out<=1'b0;
                  end
           end
          
      end
end //end always


endmodule

