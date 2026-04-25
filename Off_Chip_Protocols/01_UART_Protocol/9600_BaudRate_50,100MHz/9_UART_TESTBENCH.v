
module uart_tb;

reg t_clk;
reg r_clk;
reg rst;
reg w_en;
reg [7:0]TDR;

wire busy;
wire done;
wire frame_err;
wire parity_err;
wire [7:0] dout;


top DUT (.t_clk(t_clk),
    .r_clk(r_clk),
    .rst(rst),
    .w_en(w_en),
    .TDR(TDR),
    .busy(busy),
    .done(done),
    .frame_err(frame_err),
    .parity_err(parity_err),
    .dout(dout)
);


always #10 t_clk=~t_clk;   // 50MHz


always #5 r_clk=~r_clk;   //100MHZ

initial begin
    t_clk=0;
    r_clk= 0;
    rst=1;
    w_en=0;
    TDR=8'd0;

    #200;
    rst=0;

  
  repeat(10) begin @(posedge t_clk);

   
    TDR=TDR+30; 
    w_en=1;
    @(posedge t_clk);
    w_en=0;
 

    // wait for Receiver to be done
    wait(done==1);

  $display("************************************");
    $display("Sent= %d",TDR);
    $display("Received=%d",dout);
    $display("FrameErr=%b",frame_err);
    $display("ParityErr=%b",parity_err);
  $display("************************************");
end
    #2000;
    $finish;
end

initial begin
    $dumpfile("uart.vcd");
    $dumpvars(0, uart_tb);

$monitor("t=%0t  busy=%b done=%b frame_err=%b parity_err=%b dout=%d",$time,busy,done,frame_err,parity_err,dout);
end

endmodule
