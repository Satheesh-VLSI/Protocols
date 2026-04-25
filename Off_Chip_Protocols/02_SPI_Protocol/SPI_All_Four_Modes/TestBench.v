module tb_top #(parameter MODE=2'b11);
    reg m_clk,s_clk,rst,start_en;
    reg [7:0] m_data_in;
    reg [7:0] s_data_in;
    
    wire [7:0] m_data_out, s_data_out;
    wire m_busy, m_done, s_busy, s_done;
    
    // Clock generation
    always #15 m_clk=~m_clk;  // 50MHz
    always #5  s_clk=~s_clk;  // 100MHz
    
  top #(MODE) dut (
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
        m_clk=0;s_clk=0;start_en=0;
        $dumpfile("spi.vcd");
        $dumpvars(0, tb_top);
        
        // Test Case 1
        rst = 1; #20 rst = 0;
        #50 m_data_in=165; s_data_in=90;   start_en=1;
        wait(m_done==1); wait(s_done==1);
        $display("\n\n*****Multiple Data - SIngle Start Enable TEST SERIES*****");
        $display("Test 1 - Master RX: %d (should be 90)", m_data_out);
        $display("Test 1 - Slave RX:  %d (should be 165)", s_data_out);
        
        // Test  2  
        m_data_in=16;  s_data_in=100;
        #40 wait(m_done==1); wait(s_done==1);
        
        $display("Test 2 - Master RX: %d (should be 100)", m_data_out);
        $display("Test 2 - Slave RX:  %d (should be 16)", s_data_out);
        
        // Test  3
        #40 m_data_in=33;  s_data_in=66;  
        wait(m_done==1); wait(s_done==1);
        $display("Test 3 - Master RX: %d (should be 66)", m_data_out);
        $display("Test 3 - Slave RX:  %d (should be 33)", s_data_out);
        
        // Test  4
        #40 m_data_in=27; s_data_in=0; #50 start_en=0;  
        wait(m_done==1); wait(s_done==1);
        $display("Test 4 - Master RX: %d (should be 0)", m_data_out);
      $display("Test 4 - Slave RX:  %d (should be 27)", s_data_out);
        
        $display("=== TESTS COMPLETE ===");
        // Test Case 1 
        #50 m_data_in=55; s_data_in=9; 
        start_en=1;#50 start_en=0;
        wait(m_done==1); wait(s_done==1);
        $display("\n\n*****Multiple Data - Multiple Start Enables TEST SERIES*****");
        $display("Test 1 - Master RX: %d (should be 9)", m_data_out);
        $display("Test 1 - Slave RX:  %d (should be 55)", s_data_out);
        
        // Test  2  
        #50 m_data_in=123;  s_data_in = 108;  
        start_en=1; #50 start_en = 0;
        wait(m_done==1); wait(s_done==1);
        $display("Test 2 - Master RX: %d (should be 108)", m_data_out);
        $display("Test 2 - Slave RX:  %d (should be 123)", s_data_out);
        
        // Test  3
        #50 m_data_in=42;  s_data_in=89;   
        start_en=1; #50 start_en=0;
        wait(m_done==1); wait(s_done==1);
        $display("Test 3 - Master RX: %d (should be 89)", m_data_out);
        $display("Test 3 - Slave RX:  %d (should be 42)", s_data_out);
        wait(m_done==0); wait(s_done==0);

        
        // Test  4
        m_data_in=200; s_data_in=0;
        start_en=1; #50 start_en= 0;
        wait(m_done==1); wait(s_done==1);
        $display("Test 4 - Master RX: %d (should be 0)", m_data_out);
        $display("Test 4 - Slave RX:  %d (should be 200)", s_data_out);
        
      $display("************ ALL TESTS COMPLETE **************");
        $finish;
    end
endmodule
