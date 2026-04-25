module single_port_RAM (
    input [7:0] data_in,  // Input data to write
    input [7:0] addr,     // Write/Read address
    input mode,           // 0=Write, 1=Read
    input clk,            // Clock
    input valid,          // Enable access
    output reg [7:0] data_out // Output data from RAM
);

  reg [7:0] memory [0:255];

  always @(posedge clk) begin
    if(valid) begin
      if(mode)
          data_out<=memory[addr];
      else begin
          memory[addr]<=data_in;
      end
    end
  end

endmodule
