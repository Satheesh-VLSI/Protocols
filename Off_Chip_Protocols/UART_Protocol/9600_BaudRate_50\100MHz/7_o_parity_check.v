module Odd_Par_CHECK(Data,Odd_parity, OpCheck);
  input [7:0] Data;
  input Odd_parity;
  output OpCheck ;
  
  assign OpCheck=~(Odd_parity^Data[7]^Data[6]^Data[5]^Data[4]^Data[3]^Data[2]^Data[1]^Data[0]);
 
endmodule

