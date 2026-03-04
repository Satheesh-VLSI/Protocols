`include "PISO.v"
`include "Parity.v"

module UART_Transmitter(clk,rst,tx_en,w_en,TDR,Tx,busy);
input clk,rst,tx_en,w_en;
input [7:0] TDR;
output reg Tx;
output reg busy;

//Controller

localparam IDLE=3'B000,
       	START=3'B001,
	DATA=3'B010,
	PARITY=3'B011,
	STOP=3'B100;


reg [2:0] state,next_state;
reg [2:0] counter;
wire load;
wire TSR;
wire parity;

//shift register for converting the parallel input into serial stream of data
//to be sent
 PISO piso(.Data_in(TDR),
	 .load(load),
	 .clk(clk),
	 .rst(rst),
	 .Q(TSR),
	 .tx_en(tx_en));
 

 //Parity generator
 parity_gen  par(.clk(clk),
	 .rst(rst),
	 .x(TDR),
	 .load(load),
	 .odd(parity));
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
		IDLE: next_state<=(w_en)? START:IDLE;
		START: next_state<=(tx_en)? DATA:START;
		DATA: next_state<=((tx_en==1)&&(counter==3'd7))? PARITY:DATA;
		PARITY: next_state<=(tx_en)? STOP:PARITY;
		STOP:next_state<=(tx_en)? IDLE:STOP;
	endcase

end
//output logic upon states

assign load =(( state==IDLE)&&( next_state==START));
always @(posedge clk or posedge rst)begin
    if (rst)begin
            Tx<=1;
	    busy<=0;
	    counter<=0;
    end
    else begin
	case(state)
		IDLE:begin
			Tx<=1;
			busy<=0;
			counter<=0;
		end
		START:begin
			Tx<=0;
			busy<=1;
			counter<=0;
		end
		DATA:begin
			Tx<=TSR;
			busy<=1;
                        if(tx_en)
				counter<=counter+1;
		end
		PARITY:begin
			Tx<=parity;
			busy<=1;
			counter<=0;
		end
		STOP:begin
			Tx<=1;
			busy<=1;
			counter<=0;
		end
	endcase
    end
    end
    endmodule

