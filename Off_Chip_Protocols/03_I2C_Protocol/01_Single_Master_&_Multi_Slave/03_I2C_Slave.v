`include "04_Single_Port_RAM.v"
module I2C_SLAVE #(parameter slave_address=7'd50)(
  input clk,  // Slave System clock
  input rst, // rst

  output reg [7:0] reg_addr, // Internal register address(memory)
  output reg [7:0] w_data,   // Data received from master for writing
  output reg valid,          // Data valid pulse for reading and writing which will be sent to single port RAM
  output reg RW,             // R/W status
  output reg done,           // DONE flaf

  inout sda,            // Data line
  input scl             // Clock line
);

  wire [7:0] r_data;
  reg master_ack;
  
  //-----------------------------------------
  //    Open Drain Connection OF SDA Line
  //-----------------------------------------
  reg sda_high;
  wire sda_in;
  assign sda_in=sda;
  assign sda=sda_high?1'bz:1'b0;
  
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
    scl_sync1<=scl;
    scl_sync2<=scl_sync1;
  end
  //-----------------------------------------
  //          START/STOP Detector
  //-----------------------------------------
  reg sda_prev;
  wire start_detect;
  wire stop_detect;

  wire raw_start=scl_sync2&&sda_prev&&!sda_sync2;
  assign start_detect=raw_start; 

  wire raw_stop=scl_sync2&&!sda_prev&&sda_sync2;
  assign stop_detect=raw_stop&&(state!=IDLE);

  //-----------------------------------------
  //          SCL Edge Detector
  //-----------------------------------------
  wire scl_rising,scl_falling;
  reg scl_prev;
  assign scl_rising=(!scl_prev&&scl_sync2);
  assign scl_falling=(scl_prev&&!scl_sync2);

  
  reg [3:0] state, next;
  localparam IDLE=0, START=1,      SLAVE_ADDR=2, ACK1=3,      REG_ADDR=4, 
             ACK2=5, WRITE_DATA=6, ACK3=7,       READ_DATA=8, ACK4=9;
      
  
  //==========================================
  //         STATE SEQUENTIAL BLOCK
  //==========================================
  always @(posedge clk) begin
    if(rst||stop_detect)
      state<=IDLE;
    else if(start_detect)
      state<=START; 
    else
      state<=next;
  end
  
  //==========================================
  //         STATE TRANSITION BLOCK
  //==========================================
  always @(*) begin
    next=state;
    case(state)
      IDLE:        next=IDLE; 
      START:       next=scl_falling?SLAVE_ADDR:START;
      SLAVE_ADDR:  next=(bit_count==8&&scl_falling)?ACK1:SLAVE_ADDR;
      ACK1: begin
        if(!saddr_shift[0]) 
          next=(scl_falling)?((slave_address==saddr_shift[7:1])?REG_ADDR:IDLE):ACK1;
        else             
          next=(scl_falling)?((slave_address==saddr_shift[7:1])?READ_DATA:IDLE):ACK1;
      end
      REG_ADDR:    next=(bit_count==8&&scl_falling)?ACK2:REG_ADDR;
      ACK2: begin
        if(!RW)    next=(scl_falling)?WRITE_DATA:ACK2;
        else       next=(scl_falling)?IDLE:ACK2; 
      end
      WRITE_DATA:  next=(bit_count==8&&scl_falling)?ACK3:WRITE_DATA;
      ACK3:        next=(scl_falling)?WRITE_DATA:ACK3; 
      READ_DATA:   next=(bit_count==7&&scl_falling)?ACK4:READ_DATA;
      ACK4:        next=(scl_falling)?((master_ack)?READ_DATA:IDLE):ACK4;
      default:     next=IDLE;
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

  //-----------------------------------------
  //     Single Port RAM instantiation
  //-----------------------------------------
  single_port_RAM mem(
      .data_in(w_data), 
      .addr(reg_addr), 
      .mode(RW), 
      .clk(clk), 
      .valid(valid), 
      .data_out(r_data)
  );

  //==========================================
  //         STATE DATAPATH BLOCK
  //==========================================
  always @(posedge clk) begin
    if(rst) begin
        sda_prev<=1; scl_prev<=1; done<=0; sda_high<=1;
        saddr_shift<=0; regaddr_shift<=0; wdata_shift<=0;
        read_shift<=0; bit_count<=0; RW<=0; valid<=0; master_ack<=0;
    end
    else if(stop_detect) begin
        done<=1; sda_high<=1; valid<=0;
    end
    else if(start_detect) begin
      sda_high<=1;
      bit_count<=0;
      valid<=0;
      sda_prev<=sda_sync2;
      scl_prev<=scl_sync2;
    end
    else begin
      sda_prev<=sda_sync2;
      scl_prev<=scl_sync2;

      case(state)
        IDLE: begin
          master_ack<=0;
          valid<=0; 
          done<=0;
          sda_high<=1; 
          bit_count<=0;
        end
        
        START: begin
          sda_high<=1;
          bit_count<=0;
        end
        
        SLAVE_ADDR: begin
            if(scl_rising) begin
                saddr_shift<={saddr_shift[6:0],sda_sync2};
                bit_count<=bit_count+1;
            end
            
            if(scl_falling) begin
                if(bit_count==8) begin
                  if(slave_address==saddr_shift[7:1]) begin
                      sda_high<=0; 
                      RW<=saddr_shift[0];
                      if(saddr_shift[0]==1)
                          valid<=1; 
                    end 
                  else 
                      sda_high<=1; 
                    
                    bit_count<=0;
                end
            end
        end
        
        ACK1: begin
            if(scl_falling) begin
                if(slave_address==saddr_shift[7:1]) begin
                  if(saddr_shift[0]==0) begin
                        sda_high<=1; 
                        valid<=0;
                    end 
                  else begin
                        sda_high<=r_data[7];
                        read_shift<={r_data[6:0],1'b0};
                        valid<=0;
                    end
                end 
              else 
                sda_high<=1; 
            end
        end
        
        REG_ADDR: begin
            if(scl_rising) begin
                regaddr_shift<={regaddr_shift[6:0],sda_sync2};
                bit_count<=bit_count+1; 
            end
            
            if(scl_falling) begin
                if(bit_count==8) begin 
                    sda_high<=0;  
                    reg_addr<=regaddr_shift; 
                    bit_count<=0;
                end
            end
        end
        
        ACK2: begin
            if(scl_falling) 
              sda_high<=1; 
        end
        
        WRITE_DATA: begin
            if(scl_rising) begin
                wdata_shift<={wdata_shift[6:0],sda_sync2};
                bit_count<=bit_count+1; 
            end
            
            if(scl_falling) begin
                if(bit_count==8) begin 
                    sda_high<=0; 
                    w_data<=wdata_shift; 
                    valid<=1; 
                    bit_count<=0;
                end
            end
        end
        
        ACK3: begin
            if(scl_falling) begin
                sda_high<=1; 
                valid<=0;
                if(reg_addr<255)
                  reg_addr<=reg_addr+1; 
            end
        end
        
        READ_DATA: begin
            if(scl_falling) begin
                if(bit_count<7) begin
                    sda_high<=read_shift[7]; 
                    read_shift<={read_shift[6:0],1'b0};
                    bit_count<=bit_count+1;
                end else begin
                    sda_high<=1; 
                    bit_count<=0;
                end
            end
        end
        
        ACK4: begin
            if(scl_rising) begin
                master_ack<=!sda_sync2; 
                if(!sda_sync2&&reg_addr<255) begin
                    reg_addr<=reg_addr+1; 
                    valid<=1; 
                end
            end
            
            if(scl_falling) begin
                valid<=0;
                if(master_ack) begin
                    sda_high<=r_data[7];
                    read_shift<={r_data[6:0],1'b0};
                end else begin
                    sda_high<=1; 
                end
            end
        end
      endcase
    end
  end
endmodule
