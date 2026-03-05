module spi_master #(parameter size=8) (clk,rst,en,data_in,MISO,MOSI,ss,finish,sclk,mdata_out);
input clk,rst,en;
input [size-1:0] data_in; 
input MISO;
output reg MOSI;
output reg ss,finish,sclk;
output reg [size-1:0] mdata_out;

  reg [1:0]clk_count=0;
  reg [$clog2(size)-1:0] mosi_count;
  

 
//clock devider by 4
  always @(negedge clk)begin
       if(rst)
         sclk<=0;
  else if(clk_count==1)begin
	 sclk<=~sclk;
	 clk_count<=0;
     end
  else
	   clk_count<=clk_count+1;
end
//mosi_count

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
	      idle:next=en?transfer:idle;
          transfer:next=(mosi_count==size-1)?done:transfer;
          done:next=idle;
          default: next=idle;
	endcase

end

  always @(negedge sclk or negedge rst)begin
        if(rst)begin
	          ss<=1;
              finish<=0;
              MOSI <= 0;
              mosi_count<=0;
             end
        else begin 
             case(state)
               idle:begin    
                 ss<=0;
                 finish<=0;
                 MOSI<=data_in[size-1];
                 mosi_count<=0;
                        end
               transfer:begin 
                 MOSI <= data_in[size-2-mosi_count];
                    if (mosi_count == size-1)begin
                                mosi_count <= mosi_count;
                    end
                          else
                                mosi_count <= mosi_count + 1;
                         end
               done: begin mosi_count<=0; finish<=1;  end
               default:begin  ss<=1;
                             finish<=0;
                   end
                  endcase
        end

end



  always @(posedge sclk)begin
	if(rst)begin
		mdata_out<=0;
	end
  else if(state==transfer) begin
    mdata_out<={mdata_out[size-2:0],MISO};
		end
	else
		mdata_out<=mdata_out;
end


endmodule

