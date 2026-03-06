module tb_top;
    reg m_clk = 0, s_clk = 0, rst = 0, start_en = 0;
    reg [7:0] m_data_in;
    reg [7:0] s_data_in;
    
    wire [7:0] m_data_out, s_data_out;
    wire m_busy, m_done, s_busy, s_done;
    
    // Clock generation
    always #10 m_clk = ~m_clk;  // 50MHz Master's System clock
    always #5  s_clk = ~s_clk;  // 100MHz Slave's System clcok
    
    top  dut(.m_clk(m_clk),
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
             .s_done(s_done));
    
    initial begin
        $dumpfile("spi.vcd");
        $dumpvars;
        
        // Test Case 1
        rst = 1; #20 rst= 0;
        #50 m_data_in=165; s_data_in=90;   start_en=1;
        wait(m_done==1); wait(s_done==1);
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
        #40 m_data_in=255; s_data_in=0;   
        wait(m_done==1); wait(s_done==1);
        $display("Test 4 - Master RX: %d (should be 0)", m_data_out);
        $display("Test 4 - Slave RX:  %d (should be 255)", s_data_out);
        
        $display("=== ALL TESTS COMPLETE ===");
        $finish;
    end
endmodule

