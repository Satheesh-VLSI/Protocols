`include "Transmitter.v"
`include "Receiver.v"
`include "Transmitter_Baud_generator.v"
`include "Receiver_Baud_generator.v"


module top(
input t_clk,r_clk,rst,w_en,
input [7:0] TDR,
output busy,done,frame_err,parity_err,
output [7:0] dout);


wire tx_en,rx_en; //from baud generators to transmitter and receiver
wire Tx;    //serial output from Transmitter to the Receiver
  


  
transmitter_baud_gen tbg(.clk(t_clk),
                         .rst(rst),
                         .tx_en(tx_en));
                         
receiver_baud_gen rbg(.clk(r_clk),
                      .rst(rst),
                      .rx_en(rx_en));
                      
UART_Transmitter  transmit(.clk(t_clk),
                 .rst(rst),
                 .tx_en(tx_en),
                 .w_en(w_en),
                 .TDR(TDR),
                 .Tx(Tx),
                 .busy(busy));
                 
UART_Receiver receive(.clk(r_clk),
              .rst(rst),
              .rx_en(rx_en),
                      .Rx(Tx),
              .done(done),
              .dout(dout),
              .frame_err(frame_err),
              .parity_err(parity_err));
              
              
endmodule

