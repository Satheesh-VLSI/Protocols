`include "3_SPI_Slave.v"
`include "2_SPI_Master.v"
module top (
    input  wire m_clk,      //Master clock
    input  wire s_clk,      //Slave clock  
    input  wire rst,        //Reset
    input  wire start_en,   //Start transfer enable for master
  
    input  wire [7:0] m_data_in,  //Master sending data
    input  wire [7:0] s_data_in,  //Slave sending data
  
    output wire [7:0] m_data_out, //Master received data
    output wire [7:0] s_data_out, //Slave received data
  
    output wire m_busy,     //Master busy
    output wire m_done,     //Master done
    output wire s_busy,     //Slave busy
    output wire s_done      //Slave done
);


wire sclk,cs;
wire MOSI,MISO;
  
  
//Master instantiation
  spi_master master_dut(.i_clk(m_clk),
                        .i_rst(rst),
                        .start_en(start_en),
                        .i_tx_data(m_data_in),
                        .i_miso(MISO),
                        .o_mosi(MOSI),
                        .cs(cs),
                        .sclk(sclk),
                        .m_busy(m_busy),
                        .m_done(m_done),
                        .rx_data(m_data_out));
  
  //slave instantiation
  spi_slave slave1(.i_clk(s_clk),
                   .sclk(sclk),
                   .cs(cs),
                   .i_mosi(MOSI),
                   .i_tx_data(s_data_in),
                   .o_miso(MISO),
                   .o_rx_data(s_data_out),
                   .s_done(s_done),
                   .s_busy(s_busy));
  

endmodule
