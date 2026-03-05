`include "3_SPI_Slave.v"
`include "2_SPI_Master.v"
module top #(parameter size=8)(clk,rst,en,data_in,finish,mdata_out,ready,data_out);
input clk,rst,en;
input [size-1:0] data_in; 
output finish,ready;
output [size-1:0] mdata_out,data_out;

wire sclk,ss;
wire MOSI,MISO;
  
  
//Master instantiation
  spi_master #(size) M(.clk(clk),
                        .rst(rst),
                        .en(en),
                        .data_in(data_in),
                        .MISO(MISO),
                        .MOSI(MOSI),
                        .ss(ss),
                        .finish(finish),
                        .sclk(sclk),
                        .mdata_out(mdata_out));
  
  spi_slave #(size) S1(.sclk(sclk),
                       .rst(rst),
                       .ss(ss),
                       .MOSI(MOSI),
                       .MISO(MISO),
                       .ready(ready),
                       .data_out(data_out));
endmodule
