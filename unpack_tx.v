// data unpacking from 8 bit parallel to serial

module unpack_tx(
    input clk,
    input rstn,
    input [7:0] din,
    input [1:0] datawidthsel,
    output reg dout
);

  // internal registers
  reg [7:0] data;
  reg [2:0] dindex;
  reg [2:0] i;

  // logic for selecting data width
  always @(posedge clk, negedge rstn)
  begin
    if (!rstn)
      dindex <= 3'b000;
    else if (datawidthsel == 2'b00) // 5 bits
      dindex <= 3'b100;
    else if (datawidthsel == 2'b01) // 6 bits
      dindex <= 3'b101;
    else if (datawidthsel == 2'b10) // 7 bits
      dindex <= 3'b110;
    else if (datawidthsel == 2'b11) // 8 bits
      dindex <= 3'b111;
  end


  always @(posedge clk, negedge rstn)
  begin
    if (!rstn)
    begin
      i <= 0;
      data <= 0;
    end
    else
    begin
      if (i <= dindex)
      begin
        if (i == 0)
        begin
          data <= din;
          dout <= din[0];
          i <= i + 1;
        end
        else
        begin
          dout <= data[0];
          data <= data >> 1;
          i <= i + 1;
        end
      end
      else
      begin
        i <= 0;
      end
    end
  end

endmodule
