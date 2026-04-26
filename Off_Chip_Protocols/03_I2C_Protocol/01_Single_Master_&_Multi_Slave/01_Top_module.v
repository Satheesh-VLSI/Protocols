`include "02_I2C_Master.v"
`include "03_I2C_Slave.v"

module I2C_Top (
    input m_clk,         // Master's system clock
    input s_clk,        // Slave's system clock
    input rst,       // rst
    input start_en,     // transaction enable from the system
    input RW,            // Read/Write: 0=Write, 1=Read

    input [6:0] s_addr,  // Target slave device address
    input [7:0] reg_addr,  // Internal register address(memory)
    input [7:0] w_data,    // Data to be written

    output [7:0] r_data,   // Data read from slave
    output m_done,         // master's done flag
    output m_ack_err,      // Acknowledge error
    
    output s_done1,        // Status: Slave 1 operation done
    output s_done2,        // Status: Slave 2 operation done
    output s_done3         // Status: Slave 3 operation done
);

  wire sda;
  wire scl;

  pullup p1(sda);
  pullup p2(scl);

  I2C_MASTER master(.clk(m_clk),
                    .rst(rst),
                    .start_en(start_en),
                    .RW(RW),
                    .s_addr(s_addr),
                    .reg_addr(reg_addr),
                    .w_data(w_data),
                    .r_data(r_data),
                    .done(m_done),
                    .ack_err(m_ack_err),
                    .sda(sda),
                    .scl(scl));

  I2C_SLAVE #(.slave_address(7'd10)) slave1(.clk(s_clk),
                                           .rst(rst),
                                           .done(s_done1),
                                           .sda(sda),
                                           .scl(scl)); 
                                           
  I2C_SLAVE #(.slave_address(7'd20)) slave2(.clk(s_clk),
                                           .rst(rst),
                                           .done(s_done2),
                                           .sda(sda),
                                           .scl(scl)); 
                                           
  I2C_SLAVE #(.slave_address(7'd30)) slave3(.clk(s_clk),
                                           .rst(rst),
                                           .done(s_done3),
                                           .sda(sda),
                                           .scl(scl));

endmodule
