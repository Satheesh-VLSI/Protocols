module spi_slave #(parameter size=8) (sclk,rst,ss,MOSI,MISO,ready,data_out);
input sclk,rst,ss; 
input MOSI;  
output reg MISO; //output to master
output reg ready; //ready means the data has fully received
output reg [size-1:0] data_out;
  reg [size-1:0] temp=8'b11000011;

  reg [$clog2(size)-1:0] count;
  


reg [1:0] state,next;
parameter idle=0,transfer=1,done=2;


//sequential block of fsm control
  always @(negedge sclk or negedge rst)begin
	if(rst)
		state<=idle;
	else
		state<=next;
end

always @(*)begin
      next=state;
      case(state)
        idle:next=(!ss)?transfer:idle;
        transfer:next=(count==size-1)?done:transfer;
        done:next=(!ss)?transfer:idle;
        default: next=idle;
	endcase

end

  always @(negedge sclk or negedge rst)begin
        if(rst)begin
              ready<=0;
              MISO<= 0;
              count<=0;
             end
    
        else begin 

             case(state)
                  idle:begin 
                    ready<=0;
                    count<=0;
                       if(!ss)
                              MISO <= temp[size-1]; 
                        end
                  transfer:begin 
                    MISO<=temp[size-2-count];
                    
                    if (count == size-1)begin
                            count<=count;
                    end
                          else
                             count<=count+1;
                         end
               done: begin count<=0; ready<=1;  end
               default:begin  
                             ready<=0;
                   end
                  endcase
        end

end



  always @(posedge sclk)begin
	if(rst)begin
		data_out<=0;
	end
  else if(state==transfer) begin
    data_out={data_out[size-2:0],MOSI};
		end
	else
		data_out<=data_out;
end


endmodule
