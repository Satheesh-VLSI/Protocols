module parity_gen (
    input clk,
    input rst,
    input load,
    input [7:0] x,
    output reg odd
);
always @(posedge clk or posedge rst) begin
    if (rst)
        odd<=0;
    else if (load)      //TX FSM asserts load
      odd<=~(^x);      // XNOR all bits → odd parity
end
endmodule
