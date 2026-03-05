module transmitter_baud_gen #(parameter baudrate=115200,t_frq=50000000)(clk,rst,tx_en);
input clk,rst;
output reg tx_en;

reg [$clog2(t_frq/baudrate):0]count;

always @(posedge clk or posedge rst)begin

	if(rst)begin
		tx_en<=0;
		count<=0;
	end

  else if(count==t_frq/baudrate)begin  //count
		tx_en<=1;
	        count<=0;
	end
	else begin
		count<=count+1;
	        tx_en<=0;
	end

        end 
endmodule


