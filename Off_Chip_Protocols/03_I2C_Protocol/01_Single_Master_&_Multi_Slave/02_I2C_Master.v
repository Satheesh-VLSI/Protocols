module I2C_MASTER(
  input clk,   //Master's System clock
  input rst,   //rst
  input start_en,     // transaction enable from the system
  input RW,          // Read/Write: 0=Write, 1=Read
  input [6:0] s_addr,   // 7-bit slave address
  input [7:0] reg_addr, // Internal register address(memory)
  input [7:0] w_data,   // Data to send

  output reg [7:0] r_data, // Data received
  output reg done,         // Master finished flaf
  output reg ack_err,      // NACK detection

  inout sda,            // Serial data line
  output scl            // Serial clock line
);

  
  
  //-----------------------------------------
  //    Open Drain Connection OF SDA Line
  //-----------------------------------------
  
  reg sda_high;
  wire sda_in;
  assign sda_in=sda;      
  assign sda=sda_high?1'bz:1'b0; 
  //-----------------------------------------
  //    Open Drain Connection OF SDA Line
  //-----------------------------------------
  
   reg tclk;
   wire scl_in;
   assign scl_in=scl;      
   assign scl=tclk?1'bz:1'b0;        

  //==========================================
  //      SCL GENERATOR:Clock Divider
  //==========================================
  reg [1:0] clk_count;
  always @(posedge clk) begin
    if(rst==1||state==IDLE) begin
            tclk<=1'b1;
            clk_count<=2'b0;
          end
    else if(clk_count==2'd3) begin
            tclk<=~tclk;            
            clk_count<=2'b0;
          end
        else begin
            clk_count<=clk_count+1;
          end
    end

  reg [3:0] state,next;
  localparam  IDLE=0,  START=1, SLAVE_ADDR=2,   ACK1=3,    REG_ADDR=4,
              ACK2=5,  WDATA=6, ACK3=7,         RESTART=8, SLAVE_ADDR_R=9,
              ACK4=10, READ=11, MASTER_NACK=12, STOP=13;

  //==========================================
  //         STATE SEQUENTIAL BLOCK
  //==========================================
  always @(posedge clk) begin
    if(rst) 
      state<=IDLE;
    else 
      state<=next;
  end
  //-----------------------------------------
  //            SDA Synchronizer
  //-----------------------------------------
  reg sda_sync1, sda_sync2;
  always @(posedge clk) begin
    sda_sync1<=sda_in;
    sda_sync2<=sda_sync1;
  end

  //-----------------------------------------
  //            SCL Synchronizer
  //-----------------------------------------
  reg scl_sync1, scl_sync2;
  always @(posedge clk) begin
    scl_sync1<=scl_in;
    scl_sync2<=scl_sync1;
  end
 
  //-----------------------------------------
  //            Scl edge Detector
  //-----------------------------------------
  wire scl_rising, scl_falling;
  reg scl_prev;
  
  assign scl_rising=(!scl_prev&&scl_sync2);
  assign scl_falling=(scl_prev&&!scl_sync2);
  
  //==========================================
  //         STATE TRANSITION BLOCK
  //==========================================
  always @(*) begin
    next=state;
    case(state)
      IDLE        :  next=start_en?START:IDLE;
      START       :  next=(scl_falling&&sda_high==0)?SLAVE_ADDR:START;
      SLAVE_ADDR  :  next=(bit_count==8 && scl_falling)?ACK1:SLAVE_ADDR;
      ACK1        :  next=(scl_falling)?((!ack_err)?REG_ADDR:STOP):ACK1;
      REG_ADDR    :  next=(bit_count==8 && scl_falling)?ACK2:REG_ADDR;
      ACK2: begin
        if(!RW)      next=(scl_falling)?((!ack_err)?WDATA:STOP):ACK2;
        else         next=(scl_falling)?((!ack_err)?RESTART:STOP):ACK2;
      end
      WDATA       :  next=(bit_count==8 && scl_falling)?ACK3:WDATA;
      ACK3        :  next=(scl_falling)?STOP:ACK3; 
      RESTART     :  next=(scl_falling&&sda_high==0)?SLAVE_ADDR_R:RESTART;
      SLAVE_ADDR_R:  next=(bit_count==8 && scl_falling)?ACK4:SLAVE_ADDR_R;
      ACK4        :  next=(scl_falling)?((!ack_err)?READ:STOP):ACK4;
      READ        :  next=(bit_count==8 && scl_falling)?MASTER_NACK:READ;
      MASTER_NACK :  next=(scl_falling)?STOP:MASTER_NACK;
      STOP        :  next=(scl_rising)?IDLE:STOP;
      default     :  next=IDLE;
    endcase
  end

  //-----------------------------------------
  //      All the register's we use
  //-----------------------------------------
  reg [7:0] saddr_shift;
  reg [7:0] regaddr_shift;
  reg [7:0] wdata_shift;
  reg [7:0] read_shift;
  reg [3:0] bit_count; 
  //==========================================
  //         STATE DATAPATH BLOCK
  //==========================================
  always @(posedge clk) begin
   if(rst) begin
    r_data       <=0;
    done       <=0;
    sda_high     <=1;
    scl_prev     <=0;
    bit_count    <=0;
    saddr_shift  <=0;
    regaddr_shift<=0;
    wdata_shift  <=0;
    read_shift   <=0;
    ack_err      <=0;
   end
    else begin
      scl_prev<=scl_sync2;
      case(state)
        IDLE: begin
          ack_err<=0;
          r_data<=0;
          done<=0;
          sda_high<=1;
          bit_count<=0;
              end
              
        START: begin
          if(tclk) begin
            sda_high<=0;  //start bit,slave will detect this 
            saddr_shift<={s_addr,1'b0};
            regaddr_shift<=reg_addr;
            wdata_shift<=w_data; 
          end
          if(scl_falling&&sda_high==0) begin
            sda_high<=s_addr[6];      //preloading the s_addr bit
            saddr_shift<={s_addr[5:0],2'b00};
            bit_count<=1; 
          end
        end
        
        SLAVE_ADDR: begin
          if(scl_falling) begin
            if(bit_count<8) begin 
              sda_high<=saddr_shift[7];
              saddr_shift <={saddr_shift[6:0],1'b0};
              bit_count <=bit_count+1;
            end else begin
                sda_high<=1;   //we release the sdal ine in this state itself for next state ack sampling
                bit_count<=0;
            end
          end
         end
        //*****SLAVE ADDRESS ACKNOWLEDGEMENT***** 
        ACK1: begin  
          if(scl_rising) begin
            if(sda_sync2) 
              ack_err<=1;
            else 
              ack_err<=0;
            bit_count<=0;
          end
          if(scl_falling) begin
             if(!ack_err) begin
                 sda_high<=regaddr_shift[7];
                 regaddr_shift<={regaddr_shift[6:0],1'b0};
                 bit_count<=1;
             end else sda_high<=0; 
          end
        end
        
        REG_ADDR: begin
          if(scl_falling) begin
            if(bit_count<8) begin 
                sda_high<=regaddr_shift[7];
                regaddr_shift<={regaddr_shift[6:0],1'b0};
                bit_count<=bit_count+1;
            end else begin
                sda_high<=1; 
                bit_count<=0;
            end
          end
        end
        //*****REGISTER ADDRESS ACKNOWLEDGEMENT*****
        ACK2: begin
          if(scl_rising) begin
            if(sda_sync2) 
              ack_err<=1;
            else 
              ack_err<=0;
            bit_count<=0;
          end
          if(scl_falling) begin
              if(!ack_err) begin
                  if(!RW) begin
                      sda_high<=wdata_shift[7];
                      wdata_shift<={wdata_shift[6:0],1'b0};
                      bit_count<=1;
                  end else begin
                      sda_high<=1; 
                      saddr_shift<={s_addr,1'b1}; 
                  end
              end else sda_high<=0; 
          end
        end
        
        WDATA: begin
          if(scl_falling) begin
              if(bit_count<8) begin 
                  sda_high<=wdata_shift[7];
                  wdata_shift<={wdata_shift[6:0],1'b0};
                  bit_count<=bit_count+1;
              end else begin
                  sda_high<=1; 
                  bit_count<=0;
              end
          end
        end
        //*****WRITE DATA ACKNOWLEDGEMENT*****
        ACK3: begin
         if(scl_rising) begin
           if(sda_sync2) 
             ack_err<=1;
           else
             ack_err<=0;
           bit_count<=0;
         end
         if(scl_falling) sda_high<=0; 
        end
        
        RESTART: begin    
          if(tclk) sda_high<=0; //this is the restart bit, slave will detect this as well
          if(scl_falling&&sda_high==0) begin
                sda_high<=saddr_shift[7];
                saddr_shift<={saddr_shift[6:0],1'b0};
                bit_count<=1;
          end
        end
        
        SLAVE_ADDR_R: begin
           if(scl_falling) begin
               if(bit_count<8) begin 
                   sda_high<=saddr_shift[7];
                   saddr_shift<={saddr_shift[6:0],1'b0};
                   bit_count<=bit_count+1;
               end else begin
                   sda_high<=1; 
                   bit_count<=0;
               end
           end
        end
        //*****SLAVE ADDRESS ACKNOWLEDGEMENT*****
        ACK4: begin
          if(scl_rising) begin
            if(sda_sync2) 
              ack_err<=1;
            else 
              ack_err<=0;
            bit_count<=0;
          end
          if(scl_falling) sda_high<=1; 
        end
        
        READ: begin
          if(scl_rising) begin
            read_shift<={read_shift[6:0],sda_sync2};
            bit_count<=bit_count+1; 
          end
        end
        //*****MASTER'S ACKNOWLEDGEMENT*****
        MASTER_NACK: begin
          if(scl_falling) 
            sda_high<=0; 
          bit_count<=0; 
        end
        
        STOP: begin
           if(scl_rising) begin
             sda_high<=1; 
             done<=1;
             if(RW) r_data<=read_shift;
           end
         end
      endcase
    end

  end
endmodule
