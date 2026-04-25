`timescale 1ns / 1ps

module tb_I2C_MultiSlave;

  // ┌─────────────────────────────────┐
  // │        Testbench Signals        │
  // └─────────────────────────────────┘
  reg m_clk,s_clk;
  reg rst;
  reg start_en;
  reg RW;
  reg [6:0] s_addr;
  reg [7:0] reg_addr;
  reg [7:0] w_data;

  wire [7:0] r_data;
  wire m_done;
  wire m_ack_err;
  wire s_done1;
  wire s_done2;
  wire s_done3;


  integer tests_passed = 0;
  integer tests_failed = 0;
  
  // ┌─────────────────────────────────┐
  // │         DUT Instantiation       │
  // └─────────────────────────────────┘
  I2C_Top dut(.m_clk(m_clk),
              .s_clk(s_clk),
              .rst(rst),
              .start_en(start_en),
              .RW(RW),
              .s_addr(s_addr),
              .reg_addr(reg_addr),
              .w_data(w_data),
              .r_data(r_data),
              .m_done(m_done),
              .m_ack_err(m_ack_err),
              .s_done1(s_done1),
              .s_done2(s_done2),
              .s_done3(s_done3)
             );
  
  // ┌─────────────────────────────────┐
  // │        Clock Generation         │
  // └─────────────────────────────────┘
  initial m_clk = 0;
  always #10 m_clk = ~m_clk; 

  initial s_clk = 0;
  always #5 s_clk = ~s_clk;   


  initial begin
    $dumpfile("i2c_multi_slave.vcd"); 
    $dumpvars(0, tb_I2C_MultiSlave);
  end
  
  // ┌─────────────────────────────────┐
  // │           WRITE TASK            │
  // └─────────────────────────────────┘
  
  task write_data(input [7:0] register,write_data,
                  input [6:0] slave,
                  input expected_ack);
    $display("[Writing] Target slave : %0d | Register_addr : %0d | Write_data : %0d",slave,register,write_data);
    
      @(posedge m_clk);
    RW=0;
    reg_addr=register;
    s_addr=slave;
    w_data=write_data;
    start_en=1;
    
      @(posedge m_clk);
    start_en=0;
    
    wait(m_done==1);
    if(m_ack_err==expected_ack)begin
      $display("PASS: Got the expected ack %b",expected_ack);
      tests_passed=tests_passed+1;
    end
    else begin
      $display("FAIL: Expected ack : %b | Received ack : %b",expected_ack,m_ack_err);
      tests_failed=tests_failed+1;
    end
      
    $display("-----------------------------------------------------------------------");
      repeat(20) @(posedge m_clk);
    
  endtask

  
  // ┌─────────────────────────────────┐
  // │           READ TASK             │
  // └─────────────────────────────────┘
  
  task read_data(input [7:0] register,ex_read_data,
                 input [6:0] slave,
                 input expected_ack);
      
    $display("[Reading] Target slave : %0d | Register_addr : %0d | Expected_data : %0d",slave,register,ex_read_data);
      @(posedge m_clk);
    RW=1;
    reg_addr=register;
    s_addr=slave;
    start_en=1;
    
      @(posedge m_clk);
    start_en=0;
    
    wait(m_done==1);
    
    if(m_ack_err!=expected_ack)begin
      $display("FAIL : Expected Data : %0d | Read Data : %0d | Expected ack : %b | Got ack : %b",ex_read_data,r_data,expected_ack,m_ack_err);
      tests_failed=tests_failed+1;
    end
    else if(!m_ack_err && ex_read_data!=r_data)begin
      $display("FAIL: Expected Data : %0d | Read Data : %0d | Expected ack : %b | Got ack : %b",ex_read_data,r_data,expected_ack,m_ack_err);
      tests_failed=tests_failed+1;
    end
    else begin
      $display("PASS: Expected Data : %0d | Read Data : %0d | Got the Expected ack :  %b",ex_read_data,r_data,expected_ack);
      tests_passed=tests_passed+1;
    end
    
      
    $display("-----------------------------------------------------------------------");
      repeat(20) @(posedge m_clk);
    
  endtask
  
  // ┌─────────────────────────────────┐
  // │          Test Stimulus          │
  // └─────────────────────────────────┘
  initial begin
    $display("\n==================================================");
    $display("             STARTING MULTI-SLAVE I2C ");
    $display("==================================================\n");
    

    rst= 1;
    start_en=0;
    RW= 0;
    s_addr=7'd0;
    reg_addr=8'd0;
    w_data=8'd0;

    repeat(10) @(posedge m_clk);
      rst=0;
    repeat(10) @(posedge m_clk);
      
    $display("\n===========================================");
    $display("   PHASE 1: WRITING TO MULTIPLE SLAVES");
    $display("===========================================\n");
    
    write_data(8'd5,8'd55,7'd10,1'b0); // Slave 1 gets 55 at 5
    write_data(8'd15,8'd110,7'd20,1'b0);// Slave 2 gets 110 at 15
    write_data(8'd25,8'd79,7'd30,1'b0);// Slave 3 gets 79 at 25
    write_data(8'd10,8'd189,7'd10,1'b0); // Slave 1 gets 189 at 10
    write_data(8'd20,8'd99,7'd20,1'b0);// Slave 2 gets 99 at 20
    write_data(8'd30,8'd32,7'd30,1'b0);// Slave 3 gets 32 at 30
    
  $display("\n===================================================");
    $display("  PHASE 2: READING THE WRITTEN MEMORIES OF SLAVES");
    $display("===================================================\n");
    
    read_data(8'd5,8'd55,7'd10,1'b0);
    read_data(8'd15,8'd110,7'd20,1'b0);
    read_data(8'd25,8'd79,7'd30,1'b0); 
    read_data(8'd10,8'd189,7'd10,1'b0); 
    read_data(8'd20,8'd99,7'd20,1'b0); 
    read_data(8'd30,8'd32,7'd30,1'b0);
    
    $display("\n============================================");
    $display(" PHASE 3: Writing and Reading a GHOST Slave");
    $display("============================================\n");
    
    write_data(8'd5,8'd0,7'd11,1'b1); 
    read_data(8'd30,8'd0,7'd50,1'b1);
    
    
    $display("\n===========================================");
    $display("            ALL TESTS COMPLETED");
    $display("===========================================");
    $display("   TOTAL PASSED : %0d", tests_passed);
    $display("   TOTAL FAILED : %0d", tests_failed);
    if (tests_failed==0)
      $display("   DESIGN STATUS : SUCCESS");
    else
      $display("   DESIGN STATUS : FAILED");
    $display("===========================================\n");
    
    $finish;


    
  end
endmodule

  
