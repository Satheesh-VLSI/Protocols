
`include "7_o_parity_check.v"
//UART Receiver with 8 Data bit - 1 Stop bit - 9600 baud rate for 100Mhz
module UART_Receiver(clk,rst,rx_en,Rx,done,dout,frame_err,parity_err);
input clk,rst,rx_en;
output reg [7:0] dout;
input Rx; 
output reg done,frame_err,parity_err;

//Controller
localparam IDLE=3'B000,
           START=3'B001,
           DATA=3'B010,
           PARITY=3'B011,
           STOP=3'B100;

reg [2:0] state,next_state;
reg o_parity;
wire o_parity_check;
reg [7:0] TDR;
reg [3:0] sample;
wire sample_mid,sample_end;
 reg [2:0] index;

assign sample_mid=(sample==4'd8)&&rx_en;
assign sample_end=(sample==4'd15)&&rx_en;
assign sh_en=((rx_en)&&(sample_mid)&&(state==DATA));
 


//parity check
Odd_Par_CHECK pc(.Data(TDR),
	.Odd_parity(o_parity),
	.OpCheck(o_parity_check));
 //sequential logic
always @(posedge clk or posedge rst)begin
        if(rst)
           state<=IDLE;
        else
           state<=next_state;

end
//combinational logic
always @(*)begin
        next_state=state;
        case(state)
		  IDLE: next_state<=(Rx==0)? START:IDLE;
          START:begin  if (sample_mid && Rx==1)
                            next_state = IDLE;
                       else
                            next_state<=(sample_end)?DATA:START; 
                 end
          DATA: next_state<=((sample_end)&&(index==3'd7))? PARITY:DATA;
          PARITY: next_state<=(sample_end)? STOP:PARITY;
          STOP:next_state<=(sample_end)?IDLE:STOP;
        endcase
end
//output logic upon states
always @(posedge clk or posedge rst)begin	
    if (rst)begin 
	    sample<=0;
        frame_err<=0;
	    parity_err<=0;
	    done<=0;
        index<=0;
    	dout<=0;
	    o_parity<=0;
	 
    end
    else begin
      done<=0;
       if (state != next_state)
           sample <= 0;
       else if(rx_en && (state==START || state==DATA || state==PARITY || state==STOP))begin
           if(sample == 4'd15)
              sample <= 4'd0;
           else
              sample <= sample + 1'b1;
      end

    end
        case(state)
		IDLE:begin
            TDR<=0;  
            index<=0;
            sample <= 0;
			frame_err<=0;
	        parity_err<=0;
		    done<=0;
                end
			
          START:begin
                frame_err <= 0;
                parity_err <= 0; 
                index<=0;
                end
			
         DATA:begin
           if(sample_mid)
             TDR[index]<=Rx;
           if(sample_end)
               index<=index+1;    
         end
			
		PARITY:begin
			if(sample_mid)	
               o_parity<=Rx;  
		end
			
        STOP:begin
          if(sample_mid)begin 
		        frame_err<=~Rx;
                parity_err<=o_parity_check;
                dout<=TDR;
		      end
          if(sample_end)
             done<=1;
		end
			
        endcase
    end
endmodule
