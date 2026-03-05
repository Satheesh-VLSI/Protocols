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
