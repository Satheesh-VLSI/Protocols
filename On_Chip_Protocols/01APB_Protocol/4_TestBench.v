
`timescale 1ns/1ps

module APB_tb ;

  reg PCLK;
  reg PRESETn;
  reg transfer_en;
  reg wr_en;
  
  reg [7:0] wr_data;
  reg [9:0] wr_addr;

  wire [7:0] read_out;
  wire PSLVERR;
  wire PENABLE;


// DUT instantiationa
APB3 apb_dut (
    .PCLK(PCLK),
    .PRESETn(PRESETn),
    .transfer_en(transfer_en),
    .wr_en(wr_en),
    .wr_data(wr_data),
    .wr_addr(wr_addr),
    .read_out(read_out),
  .PSLVERR(PSLVERR),
  .PENABLE(PENABLE)
);


// CLOCK GENERATION
always #10 PCLK = ~PCLK;


//rseset
task reset;
begin
    PRESETn = 0;
    transfer_en = 0;
    wr_en = 0;
    wr_addr = 0;
    wr_data = 0;

    @(posedge PCLK);

    PRESETn = 1;
end
endtask


//wRITE Task
task apb_write;
input [9:0]addr;
input [7:0] data;
begin

    @(posedge PCLK);
    transfer_en=1;
    wr_en=1;
    wr_addr=addr;
    wr_data=data;

    @(posedge PCLK); 
    @(posedge PCLK);
    @(posedge PCLK); 

    transfer_en=0;

end
endtask
//Read Task 
task apb_read;
input [9:0] addr;
begin

    @(posedge PCLK);
    transfer_en=1;
    wr_en=0;
    wr_addr=addr;

    @(posedge PCLK); 
    @(posedge PCLK); 
    @(posedge PCLK); 
    @(posedge PCLK); 

    $display("TIME=%0t READ ADDR=%0d DATA=%0d",
             $time, addr,read_out);
  if(PSLVERR==1'b1)
    $display("\nPSLVERR=%B : INVALID ADDRESS \n",PSLVERR);
   
    @(posedge PCLK); 
    transfer_en=0;

end
endtask



//  TEST SEries 
initial begin
PCLK = 0;
    $dumpfile("apb.vcd");
    $dumpvars(0, APB_tb);

    
    reset();

    // WRITE 
    apb_write(10'd21 ,8'd10);
    apb_write(10'd195,8'd20);
    apb_write(10'd731,8'd30);
    apb_write(10'd795,8'd40);
    apb_write(10'd283,8'd50);
    apb_write(10'd1019,8'd60);
    apb_write(10'd58 ,8'd70);
    apb_write(10'd205,8'd80);
    apb_write(10'd999,8'd90);
    apb_write(10'd654,8'd100);


    // READ 
    apb_read(10'd21);
    apb_read(10'd195);
    apb_read(10'd731);
    apb_read(10'd795);
    apb_read(10'd283);
    apb_read(10'd1019);
    apb_read(10'd58);
    apb_read(10'd205);
    apb_read(10'd999);
    apb_read(10'd654);


    #100 $finish;

end


endmodule

