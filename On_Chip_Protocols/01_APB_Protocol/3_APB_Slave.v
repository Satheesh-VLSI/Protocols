
module APB_slave (
  input PCLK,
  input PRESETn,
  input PENABLE,
  input PWRITE,
  input PSEL,
  
  input [7:0]PADDR,
  input [7:0]PWDATA,

  output reg [7:0]PRDATA,
  output reg PSLVERR,
  output PREADY
);

reg [7:0] memory [0:255];

assign PREADY=PSEL?1'b1:0;   // APB slave always ready

// WRITE THE DATA FROM MASTER
always @(posedge PCLK)
begin
    if(PSEL&&PENABLE&&PWRITE)
    begin
        memory[PADDR]<=PWDATA;
    end
end


// READ FROM SLAVE
  always @(posedge PCLK)
begin
    if(PSEL && PENABLE && !PWRITE)
      if(!PSLVERR)
        PRDATA<=memory[PADDR];
    else
        PRDATA<=8'bx;
  
end


//Slave error
always @(*)
begin
  if(PSEL && PENABLE)begin
    if(PADDR>8'd255)
        PSLVERR=1;
    else if(^PADDR===1'bx)
        PSLVERR=1;
    else
        PSLVERR=0;
    end
  else
    PSLVERR=0;
end

endmodule

 
