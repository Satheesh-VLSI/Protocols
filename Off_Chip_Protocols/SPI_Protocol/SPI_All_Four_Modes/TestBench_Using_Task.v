`timescale 1ns/1ps

module tb_top #(parameter MODE=2'b11);

    reg m_clk, s_clk, rst, start_en;
    reg [7:0] m_data_in;
    reg [7:0] s_data_in;

    wire [7:0] m_data_out, s_data_out;
    wire m_busy, m_done, s_busy, s_done;

    // Clocks
    always #10 m_clk = ~m_clk;  // 50 MHz
    always #5  s_clk = ~s_clk;  // 100 MHz

    // DUT
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

    //==================== TASK 1 ====================//
    task SPI_SINGLE_START(input [7:0] m_data,input [7:0] s_data,input int num);
    begin
        @(posedge m_clk);
        m_data_in=m_data;
        s_data_in=s_data;

       //He is Waiting
      wait(m_done);  wait(s_done);

        $display("\nTest %0d",num);
        $display("Master RX = %0d (Expected %0d)", m_data_out,s_data);
        $display("Slave  RX = %0d (Expected %0d)", s_data_out,m_data);

        if (m_data_out==s_data&&s_data_out==m_data)
            $display("STATUS = PASS");
        else
            $display("STATUS = FAIL");
      
        @(posedge m_clk);
    end
    endtask

    //==================== TASK 2 ====================//
    task SPI_PULSE_START(input [7:0] m_data,input [7:0] s_data,input int num);
    begin
        @(posedge s_clk);
         m_data_in=m_data;
         s_data_in=s_data;

       
        start_en=1;
        @(posedge m_clk);
        start_en=0;

        // Wait for transfer complete
         wait(m_done);  wait(s_done);

        $display("\nTest %0d", num);
        $display("Master RX = %0d (Expected %0d)",m_data_out,s_data);
        $display("Slave  RX = %0d (Expected %0d)",s_data_out,m_data);

        if (m_data_out == s_data && s_data_out == m_data)
          $display("STATUS : PASS");
        else
          $display("STATUS : FAIL");

        @(posedge m_clk);

    end
    endtask

   
    initial begin
        m_clk=0;
        s_clk=0;
        rst=1;
        start_en=0;
        m_data_in=0;
        s_data_in=0;

        $dumpfile("spi.vcd");
        $dumpvars(0, tb_top);
        #20 rst=0;

        //------------------ SINGLE START ENABLE -----------------//
      $display("\n******** SINGLE START ENABLE TEST SERIES ********");
        start_en = 1;

      SPI_SINGLE_START(8'd20,8'd100,1);
      SPI_SINGLE_START(8'd40,8'd80,2);
      SPI_SINGLE_START(8'd60,8'd60,3);
      SPI_SINGLE_START(8'd80,8'd40,4);
      SPI_SINGLE_START(8'd100,8'd80,5);

        start_en = 0;

        //-=--------------- MULTIPLE START ENABLE -----------------//
      $display("\n********* MULTIPLE START ENABLE TEST SERIES ********");

      SPI_PULSE_START(8'd20,8'd100,1);
      SPI_PULSE_START(8'd40,8'd80,2);
      SPI_PULSE_START(8'd60,8'd60,3);
      SPI_PULSE_START(8'd80,8'd40,4);
      SPI_PULSE_START(8'd100,8'd80,5);


        $display("\n************ ALL TESTS COMPLETE **************");
        $finish;
    end

endmodule
