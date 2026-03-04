module receiver_baud_gen (clk,rst,rx_en);
input clk,rst;
output reg rx_en;

reg [9:0] count;

always @(posedge clk or posedge rst)begin

        if(rst)begin
                rx_en<=0;
                count<=0;
        end

  else if(count==10'd650)begin  //count is 650 so my tx will send a bit every 651 cycles
                rx_en<=1;
                count<=0;
        end
        else begin
                count<=count+1;
                rx_en<=0;
        end

        end
endmodule

