module tb_top;
    reg m_clk = 0, s_clk = 0, rst = 0, start_en = 0;
    reg [7:0] m_data_in;
    reg [7:0] s_data_in;
    
    wire [7:0] m_data_out, s_data_out;
    wire m_busy, m_done, s_busy, s_done;
    
    // Clock generation
    always #10 m_clk = ~m_clk;  // 50MHz
    always #5  s_clk = ~s_clk;  // 100MHz
    
    top dut (
        .m_clk(m_clk),
        .s_clk(s_clk),
        .rst(rst),
        .start_en(start_en),
        .m_data_in(m_data_in),
        .s_data_in(s_data_in),
        .m_data_out(m_data_out),
        .s_data_out(s_data_out),
        .m_busy(m_busy),
        .m_done(m_done),
        .s_busy(s_busy),
        .s_done(s_done)
    );
    
    initial begin
        $dumpfile("spi.vcd");
        $dumpvars(0, tb_top);
        
        // Test Case 1
        rst = 1; #20 rst = 0;
        #50 m_data_in = 165; s_data_in = 90;   start_en = 1;
        wait(m_done==1); wait(s_done==1);
        $display("Test 1 - Master RX: %d (should be 90)", m_data_out);
        $display("Test 1 - Slave RX:  %d (should be 165)", s_data_out);
        
        // Test Case 2  
        m_data_in = 16;  s_data_in = 100;
        #40 wait(m_done==1); wait(s_done==1);
        
        $display("Test 2 - Master RX: %d (should be 100)", m_data_out);
        $display("Test 2 - Slave RX:  %d (should be 16)", s_data_out);
        
        // Test Case 3
        #40 m_data_in = 33;  s_data_in = 66;  
        wait(m_done==1); wait(s_done==1);
        $display("Test 3 - Master RX: %d (should be 66)", m_data_out);
        $display("Test 3 - Slave RX:  %d (should be 33)", s_data_out);
        
        // Test Case 4
        #40 m_data_in = 255; s_data_in = 0;   
        wait(m_done==1); wait(s_done==1);
        $display("Test 4 - Master RX: %d (should be 0)", m_data_out);
        $display("Test 4 - Slave RX:  %d (should be 255)", s_data_out);
        
        $display("=== ALL TESTS COMPLETE ===");
        $finish;
    end
endmodule
module tb_spi_master_simple;

parameter size=8;

reg clk,rst,en;
reg [size-1:0] data_in;
wire [size-1:0] mdata_out,data_out;
wire finish,ready;

//Instantiate
top #(size) dut(clk,rst,en,data_in,finish,mdata_out,ready,data_out);

//clock
initial clk=0;
always #10 clk=~clk;  //50 MHz


initial begin
    rst=1; 
  en=0; data_in=8'd21;
    #50 rst=0;
    en=1;
  wait(ready==1);
    en=0;
    // Display results
  $display("Master sent: %d",data_in);
  $display("Slave received: %d", data_out);
  $display("Slave sent: %d",8'd195);
  $display("Master received: %d", mdata_out);

  if(mdata_out==8'd195)
    $display("\nMaster Received Successfully");
    else
      $display("Master Reception Failed");
  
  
  
 if(data_out==8'd21)
   $display("Slave Received Successfully");
    else
      $display("Slave Reception Failed");

    #50 $finish;
end

endmodule
