module spi_master #(parameter MODE=2'b00) (
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
  
  //MODE parameters
  wire CPOL;
  wire CPHA;
  
  assign CPOL=MODE[1];
  assign CPHA=MODE[0];
  
  wire sample_edge0,shift_edge0,sample_edge1,shift_edge1;
  wire rising_edge,falling_edge;
  wire sample_edge,shift_edge;
  
  assign rising_edge=(sclk==1 && sclk_p==0);
  assign falling_edge=(sclk==0 && sclk_p==1);
  
  assign sample_edge0=(CPOL==0 && CPHA==0)?rising_edge:falling_edge;
  assign shift_edge0=(CPOL==0 && CPHA==0)?falling_edge:rising_edge;
  
  assign sample_edge1=(CPOL==1 && CPHA==0)?falling_edge:rising_edge;
  assign shift_edge1=(CPOL==1 && CPHA==0)?rising_edge:falling_edge;
  
  assign sample_edge= (CPOL)?sample_edge1:sample_edge0;
  assign shift_edge= (CPOL)?shift_edge1:shift_edge0;

  // ╔══════════════════════════════════════╗
  // ║       SCLK GENERATOR (INSIDE!)       ║
  // ╚══════════════════════════════════════╝
  always @(posedge i_clk) begin
        if (i_rst|| !sclk_enable)begin
            sclk<=CPOL;           
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
 // ║  state transition sequential logic   ║
 // ╚══════════════════════════════════════╝
  always @(posedge i_clk)begin
    if(i_rst)
      state<=IDLE;
    else
      state<=next;
  end
  
  
  //next state combinational logic
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
        sclk_p <= sclk; 
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
                //o_mosi<=i_tx_data[7]; //preloading of MSB before the sampling edge
                m_busy<=1;       // the master became busy
                bit_count<=0;   //making the count 0
                sclk_enable<=1;  //enabling the sclk generator
                if(CPHA==0)
                       o_mosi <= i_tx_data[7];   // preload only for CPHA=0
              end
              TRANSFER:begin
                
                if (sample_edge)begin //rising edge
                  rx_shift<={rx_shift[6:0],i_miso};  //input from slave is sampled here
                 end
                
                                
                if(shift_edge) begin 
                  if(bit_count < 8 && CPHA==0) 
                    bit_count <= bit_count + 1; 
                  
                end 
                if(sample_edge) begin 
                  if(bit_count < 8 && CPHA==1) 
                    bit_count <= bit_count + 1; 
                end
                
                if(shift_edge)begin  //falling edge
                  if(bit_count<=7)begin
                    if(CPHA && bit_count == 0)
                            o_mosi <= tx_shift[7];
                    else begin
                            tx_shift <= {tx_shift[6:0],1'b0};
                            o_mosi  <= tx_shift[6];
                    end
                    
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
