module spi_master(
  input i_clk,    //system clock
  input i_rst,
  input start_en,  //signal to start the master
  input [7:0] i_tx_data,  //data to be transmitted to the slave
  input i_miso,
  
  output reg o_mosi,   //master out-slave in
  output reg cs,       //slave select
  output reg sclk,     //synchronized clock
  
  output reg m_busy,     //status of master
  output reg m_done,   
  
  output reg [7:0] rx_data
);
  
  reg [3:0] bit_count;
  reg [7:0] tx_shift;
  reg [7:0] rx_shift;
  
  reg [1:0] clk_count;
  reg sclk_enable;
  reg sclk_p; //for edge detection

  // ╔══════════════════════════════════════╗
  // ║       SCLK GENERATOR (INSIDE)        ║
  // ╚══════════════════════════════════════╝
  always @(posedge i_clk) begin
        if (i_rst|| !sclk_enable)begin
            sclk<=1'b0;           
            clk_count<= 2'b0;
          end 
        else if(clk_count==2'd1)begin
            sclk<= ~sclk;        // Toggle every 4 sys_clk
            clk_count<=2'b0;
          end 
        else begin
            clk_count<=clk_count+1;
          end
    end
  
  
  reg [1:0] state,next;
  
  localparam IDLE=2'b00,
             LOAD=2'b01,
             TRANSFER=2'b10,
             DONE=2'b11;
  
 // ╔══════════════════════════════════════╗
 // ║  STATE TRANSITION SEQUENTIAL LOGIC   ║
 // ╚══════════════════════════════════════╝
  always @(posedge i_clk)begin
    if(i_rst)
      state<=IDLE;
    else
      state<=next;
  end
  
  
  
 // ╔══════════════════════════════════════╗
 // ║    NEXT STATE COMBINATIONAL LOGIC    ║
 // ╚══════════════════════════════════════╝
  always @(*)begin
    next=state;
    case(state)
           IDLE:next=start_en?LOAD:IDLE;
           LOAD:next=TRANSFER;
           TRANSFER:next=(bit_count==4'd8)?DONE:TRANSFER;
           DONE:next=IDLE;
           default:next=IDLE;
    endcase
  end
      
      always@(posedge i_clk)begin
        if(i_rst)begin
          bit_count<=0;
          tx_shift<=0;
          rx_shift<=0;
          sclk_enable<=0;
          sclk_p<=0;
          o_mosi<=0;
          cs<=1;
          sclk<=0;
          m_busy<=0;
          m_done<=0;
          rx_data<=0;
        end
        else begin
          sclk_p<=sclk;
          m_done <= 0;
          case(state)
              IDLE:begin
                bit_count<=0;
                sclk_enable<=0;
                cs<=1;
                m_busy<=0;
                m_done <= 0;
              end
              LOAD:begin
                cs<=0;                 //slave select is asserted
                tx_shift<=i_tx_data;  //loading the input data on a shift register
                rx_shift<=0;
                o_mosi<=i_tx_data[7]; //preloading of MSB before the sampling edge
                m_busy<=1;       // the master became busy
                bit_count<=0;   //making the count 0
                sclk_enable<=1;  //enabling the sclk generator
              end
              TRANSFER:begin
                
                if (sclk==1 && sclk_p==0)begin //rising edge
                  rx_shift<={rx_shift[6:0],i_miso};  //input from slave is sampled here
                 end
                
                
                if(sclk==0 && sclk_p==1)begin  //falling edge
                  if(bit_count<=7)begin
                    tx_shift<={tx_shift[6:0],1'b0};  //output to slave is changed here
                    o_mosi<=tx_shift[6];
                    bit_count<=bit_count+1;
                  end
                end
              end
              DONE:begin
                sclk_enable<=0;
                bit_count<=0;
                m_done<=1;
                m_busy<=0;
                rx_data<=rx_shift;
                o_mosi<=1'bz;
                
              end
          endcase
          
        end
        
        
      end
endmodule
