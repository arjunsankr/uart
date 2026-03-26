module unpack_tx();
  reg clk;
  reg rstn;
  reg [7:0]din;
  reg [2:0]datawidthsel;
  wire dout;

  DUT unpack_tx T1(clk,rstn,din,datawidthsel,dout);

  forever clk=
  initial begin
     rstn=1'b0;
     

  
