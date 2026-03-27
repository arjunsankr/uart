module unpack_tx();
  reg clk;
  reg rstn;
  reg [7:0]din;
  reg [2:0]datawidthsel;
  wire dout;

  DUT unpack_tx T1(clk,rstn,din,datawidthsel,dout);

  forever #5 clk=~clk; //clock generation
  
  initial 
    begin
      #10 rstn=1'b0;
      #10 rsntn=1'b1;
      din=8'b10110110;
      dataselectwidth=2'b00;
    end
