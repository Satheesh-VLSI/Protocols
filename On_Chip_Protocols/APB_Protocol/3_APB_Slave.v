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

  
  
  
  
  
/***********************************************************************/

module APB_master (
  input PCLK,    //system clock
  input PRESETn,   
  
  input transfer_en,  //signal to start the master to initial transfer
  input wr_en,         //From system
  
  input [7:0] PRDATA,  //data to be transmitted from the slave
  
  input [7:0] wr_data,   //from system
  input [9:0] wr_addr,     //from system
  
  input PSLVERR,      //Slave error
  input PREADY,
 
  output reg PENABLE,   //enable to go into data phase
  output reg PWRITE,    //read or write operation
  output reg [7:0] PADDR,
  output reg [7:0] PWDATA,
  
  output reg PSEL0,       //slave select0    
  output reg PSEL1,       //slave select1    
  output reg PSEL2,       //slave select2    
  output reg PSEL3,      //slave select3 
  
  output reg [7:0] read_out
);


  
  reg [1:0] state,next;
  
  localparam IDLE=2'b00,
             SETUP=2'b01,
             ACCESS=2'b10;
  
 
  always @(posedge PCLK)begin
    if(!PRESETn)
      state<=IDLE;
    else
      state<=next;
  end
  
  
  //next state combinational logic
  always @(*)begin
    next=state;
    case(state)
           IDLE:next=transfer_en?SETUP:IDLE;
           SETUP:next=ACCESS;
           ACCESS:next=(PREADY)?(transfer_en?SETUP:IDLE):ACCESS;
           default:next=IDLE;
    endcase
  end
      
  always@(posedge PCLK)begin
    if(!PRESETn)begin
      PENABLE<=0;  
      PWRITE<=0;   
      {PSEL3,PSEL2,PSEL1,PSEL0}<=4'b0000;       
      PADDR<=0;
      PWDATA<=0;

        end
        else begin
          case(state)
              IDLE:begin
                   PENABLE<=0;  
                   PWRITE<=0;   
                   {PSEL3,PSEL2,PSEL1,PSEL0}<=4'b0000;       
                   PADDR<=8'bx;
                   PWDATA<=0;
                end
            
              SETUP:begin
                  {PSEL3,PSEL2,PSEL1,PSEL0}<=4'b0000;
                case(wr_addr[9:8])     //slave select is asserted
                  2'b00:PSEL0<=1;
                  2'b01:PSEL1<=1;
                  2'b10:PSEL2<=1;
                  2'b11:PSEL3<=1;
                endcase
         
                   PENABLE<=0;
                   PWRITE<=wr_en;
                   PADDR<=wr_addr[7:0];
                   PWDATA<=wr_data;
                end

              ACCESS:begin
                    
                   PENABLE<=1; 
                   
              end
          endcase
          
        end
        
        
      end
  always @(*)
begin
    if(!PRESETn)
        read_out = 0;
    else if(state==ACCESS && !PWRITE && PREADY)
        read_out = PRDATA;
    else 
      read_out=read_out;
end
endmodule

/***********************************************************************************/

module APB_slave (
  input PCLK,
  input PRESETn,
  input PENABLE,
  input PWRITE,
  input PSEL,
  
  input [7:0]PADDR,
  input [7:0]PWDATA,

  output reg [7:0]PRDATA,
  output reg PSLVERR,
  output PREADY
);

reg [7:0] memory [0:255];

assign PREADY=PSEL?1'b1:0;   // APB slave always ready

// WRITE THE DATA FROM MASTER
always @(posedge PCLK)
begin
    if(PSEL&&PENABLE&&PWRITE)
    begin
        memory[PADDR]<=PWDATA;
    end
end


// READ FROM SLAVE
  always @(posedge PCLK)
begin
    if(PSEL && PENABLE && !PWRITE)
      if(!PSLVERR)
        PRDATA<=memory[PADDR];
    else
        PRDATA<=8'bx;
  
end


//Slave error
always @(*)
begin
  if(PSEL && PENABLE)begin
    if(PADDR>8'd255)
        PSLVERR=1;
    else if(^PADDR===1'bx)
        PSLVERR=1;
    else
        PSLVERR=0;
    end
  else
    PSLVERR=0;
end

endmodule

 
