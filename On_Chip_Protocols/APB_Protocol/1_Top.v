`timescale 1ns/1ps
module APB3  (
  input PCLK,    //system clock
  input PRESETn,   
  
  input transfer_en,  //signal to start the master to initial transfer
  input wr_en,         //From system
  
  input [7:0] wr_data,   //from system
  input [9:0] wr_addr,     //from system
 
  output PSLVERR,
  output [7:0] read_out,
  output PENABLE  //enable to go into data phase

);
  wire [7:0] PADDR;
   
      //read or write operation
  wire PSEL0,PSEL1,PSEL2,PSEL3; 
  reg [7:0] PRDATA;
  wire PREADY,PWRITE;
  
  wire [7:0] PWDATA;   //written in slave
  


  wire [7:0] PRDATA0,PRDATA1,PRDATA2,PRDATA3;
  wire PSLVERR0,PSLVERR1,PSLVERR2,PSLVERR3;
  wire PREADY0,PREADY1,PREADY2,PREADY3;
  
  
  //master instantiation
  APB_master M(.PCLK(PCLK),
                        .PRESETn(PRESETn),
                        .transfer_en(transfer_en),
                        .wr_en(wr_en),
                        .PRDATA(PRDATA),
                        .wr_data(wr_data),
                        .wr_addr(wr_addr),
                        .PSLVERR(PSLVERR),
                        .PREADY(PREADY),
                        .PENABLE(PENABLE),
                        .PWRITE(PWRITE),
                        .PADDR(PADDR),
                        .PWDATA(PWDATA),
                        .PSEL0(PSEL0),
                        .PSEL1(PSEL1),
                        .PSEL2(PSEL2),
                        .PSEL3(PSEL3),
                        .read_out(read_out));
  
  //SLAVE 0
  APB_slave S0(.PCLK(PCLK),
                        .PRESETn(PRESETn),
                        .PENABLE(PENABLE),
                        .PWRITE(PWRITE),
                        .PSEL(PSEL0),
                        .PADDR(PADDR),
                        .PWDATA(PWDATA),
                        .PRDATA(PRDATA0),
                        .PSLVERR(PSLVERR0),
                        .PREADY(PREADY0));
    //SLAVE 1 
  APB_slave  S1(.PCLK(PCLK),
                        .PRESETn(PRESETn),
                        .PENABLE(PENABLE),
                        .PWRITE(PWRITE),
                        .PSEL(PSEL1),
                        .PADDR(PADDR),
                        .PWDATA(PWDATA),
                        .PRDATA(PRDATA1),
                        .PSLVERR(PSLVERR1),
                        .PREADY(PREADY1));
    //SLAVE 2
  APB_slave  S2(.PCLK(PCLK),
                        .PRESETn(PRESETn),
                        .PENABLE(PENABLE),
                        .PWRITE(PWRITE),
                        .PSEL(PSEL2),
                        .PADDR(PADDR),
                        .PWDATA(PWDATA),
                        .PRDATA(PRDATA2),
                        .PSLVERR(PSLVERR2),
                        .PREADY(PREADY2));
    //SLAVE 3
  APB_slave  S3(.PCLK(PCLK),
                        .PRESETn(PRESETn),
                        .PENABLE(PENABLE),
                        .PWRITE(PWRITE),
                        .PSEL(PSEL3),
                        .PADDR(PADDR),
                        .PWDATA(PWDATA),
                        .PRDATA(PRDATA3),
                        .PSLVERR(PSLVERR3),
                        .PREADY(PREADY3));
  
  
  always@(PRDATA0 or PRDATA1 or PRDATA2 or PRDATA3)begin
        PRDATA=(PSEL0)?PRDATA0:
               (PSEL1)?PRDATA1:
               (PSEL2)?PRDATA2:
               (PSEL3)?PRDATA3:
                             0;
  end
assign PREADY =(PSEL0)?PREADY0:
               (PSEL1)?PREADY1:
               (PSEL2)?PREADY2:
               (PSEL3)?PREADY3:
                             0;

 assign PSLVERR =(PSEL0 && PENABLE)?PSLVERR0:
                 (PSEL1 && PENABLE)?PSLVERR1:
                 (PSEL2 && PENABLE)?PSLVERR2:
                 (PSEL3 && PENABLE)?PSLVERR3:
                                           0;
endmodule
