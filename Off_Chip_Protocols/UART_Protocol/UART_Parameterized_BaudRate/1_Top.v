`include "2_UART_Transmitter.v"
`include "3_UART_Receiver.v"
`include "4_Transmitter_Baud_Gen.v"
`include "5_Receiver_Baud_Gen.v"


module top #(parameter baudrate=57600,t_frq=50000000,r_frq=100000000) (
input t_clk,r_clk,rst,w_en,
input [7:0] TDR,
output busy,done,frame_err,parity_err,
output [7:0] dout);


wire tx_en,rx_en; //from baud generators to transmitter and receiver
wire Tx;    //serial output from Transmitter to the Receiver
  
reg rx_sync1,rx_sync2;

always @(posedge r_clk or posedge rst) begin
  if(rst)begin
    rx_sync1<=1'b1;
    rx_sync2<=1'b1;
  end else begin
    rx_sync1<=Tx;
    rx_sync2<=rx_sync1;
  end
end
  
  transmitter_baud_gen #(.baudrate(baudrate),.t_frq(t_frq))
                     tbg(.clk(t_clk),
                         .rst(rst),
                         .tx_en(tx_en));
                         
  receiver_baud_gen #(.baudrate(baudrate),.r_frq(r_frq))
                  rbg(.clk(r_clk),
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
              .Rx(rx_sync2),
              .done(done),
              .dout(dout),
              .frame_err(frame_err),
              .parity_err(parity_err));
              
              
endmodule

