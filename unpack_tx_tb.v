  // Code your testbench here
  // or browse Examples
  module unpack_tx_tb();
    reg clk;
    reg rstn;
    reg [7:0]din;
    reg start;
    reg [1:0]datawidthsel;
    wire dout;

    unpack_tx DUT(clk,rstn,start,din,datawidthsel,dout);

    //clock generation
    initial 
      begin
        clk=1'b0;
        forever #5 clk=~clk;
      end

    //dump waves
    initial
      begin
        $dumpfile("dump.vcd");
        $dumpvars(1);
      end
  

    //inputs
    initial 
      begin
        rstn=1'b0;
        #10 rstn=1'b1;
        start=1'b1;
        din=8'b10110111;
        #10 start=1'b0;
        datawidthsel=2'b00;
        #1000 $finish;
      end
    always @(posedge clk)begin
      $display("Time=%0t | rstn=%b | start | din=%b | datawidthsel=%b | dout=%b", 
           $time, rstn,start, din, datawidthsel, dout);
    end
  endmodule
