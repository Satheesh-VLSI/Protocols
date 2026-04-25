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
