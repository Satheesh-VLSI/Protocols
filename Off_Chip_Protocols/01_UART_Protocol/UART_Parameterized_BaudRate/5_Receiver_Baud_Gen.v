module receiver_baud_gen #(parameter baudrate=115200,r_frq=100000000)(clk,rst,rx_en);
input clk,rst;
output reg rx_en;

  reg [$clog2(r_frq/baudrate):0] count;

always @(posedge clk or posedge rst)begin

        if(rst)begin
                rx_en<=0;
                count<=0;
        end

  else if(count==(r_frq/baudrate)/16)begin  //count 
                rx_en<=1;
                count<=0;
        end
        else begin
                count<=count+1;
                rx_en<=0;
        end

        end
endmodule



