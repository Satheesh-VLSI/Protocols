module spi_slave(
  input i_clk,     //system clock of slave
  input sclk,       //synchronous clock from master
  input cs,          //slave select
  input i_mosi,
  input [7:0] i_tx_data,    //data which is to be send to master
  
  output reg o_miso,
  output reg [7:0] o_rx_data,   //data received from master
  output reg s_done,
  output reg s_busy

);
  
  reg [7:0] tx_shift;
  reg [7:0] rx_shift;
  
  reg sclk_p;
  reg [3:0] bit_count;
  
  reg [1:0] state,next;
  localparam IDLE=2'b00,
             LOAD=2'b01,
             TRANSFER=2'b10,
             DONE=2'b11;
  
  always@(posedge i_clk)begin
    if(cs)
      state<=IDLE;
    else
      state<=next;
  end
  
  
  //next state combinational logic
  always @(*)begin
    next=state;
    case(state)
           IDLE:next=(cs==0)?LOAD:IDLE;
           LOAD:next=TRANSFER;
           TRANSFER:next=(bit_count==4'd8)?DONE:TRANSFER;
           DONE:next=(!cs)?DONE:IDLE;
           default:next=IDLE;
    endcase
  end
      
       always@(posedge i_clk)begin
         if(cs)begin
          bit_count<=0;
          tx_shift<=0;
          rx_shift<=0;
          sclk_p<=0;
          o_miso<=1'bz;
          s_busy<=0;
          s_done<=0;
          o_rx_data<=0;
        end
        else begin
          sclk_p<=sclk;
          s_done <= 0; 
          
          case(state)
              IDLE:begin
                bit_count<=0;
                s_busy<=0;
                o_miso<=1'bz;
              end
              LOAD:begin               
                tx_shift<=i_tx_data;  //loading the input data(to be sent) on a shift register
                rx_shift<=0;
                o_miso<=i_tx_data[7]; //preloading of MSB before the sampling edge
                s_busy<=1;       // the master became busy
                bit_count<=0;   //making the count 0
              end
              TRANSFER:begin
                
                if (sclk==1 && sclk_p==0)begin //rising edge
                  rx_shift<={rx_shift[6:0],i_mosi};  //input from slave is sampled here
                 end
                
                
                if(sclk==0 && sclk_p==1)begin  //falling edge
                  if(bit_count<=7)begin
                    tx_shift<={tx_shift[6:0],1'b0};  //output to slave is changed here
                    o_miso<=tx_shift[6];
                    bit_count<=bit_count+1;
                  end
                end
              end
              DONE:begin
                s_done<=1;
                s_busy<=0;
                bit_count<=0;
                o_rx_data<=rx_shift;
                o_miso<= 1'bz;
                
              end
          endcase
          
        end
        
        
      end
endmodule
  
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
