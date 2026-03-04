module transmitter_baud_gen (clk,rst,tx_en);
input clk,rst;
output reg tx_en;

reg [12:0] count;

always @(posedge clk or posedge rst)begin

	if(rst)begin
		tx_en<=0;
		count<=0;
	end

	else if(count==13'd5207)begin  //count is 5207 so my tx will send a bit every 5208 cycles
		tx_en<=1;
	        count<=0;
	end
	else begin
		count<=count+1;
	        tx_en<=0;
	end

        end 
endmodule

