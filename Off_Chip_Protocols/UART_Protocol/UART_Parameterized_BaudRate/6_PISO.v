
//Right  shift
module PISO (input [7:0] Data_in,input load, clk,rst,tx_en,output reg Q );
  reg [7:0]Q_temp;
  always @(posedge clk or posedge rst)begin
    if(rst)begin
      Q_temp<={8{1'B0}};
      Q<=0;
    end                // here LSB is  Q[0] and MSB is Q[3]
    else if (load)
     Q_temp<=Data_in;
    else if(tx_en) begin
      Q<=Q_temp[0];
      Q_temp<={1'B0,Q_temp[7:1]};
 
    end

  end
endmodule
