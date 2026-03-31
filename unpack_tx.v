// data unpacking from 8 bit parallel to serial

module unpack_tx(
    input clk,
    input rstn,
    input start,
    input [7:0] din,
    input [1:0] datawidthsel,
    output reg dout
);

  // internal registers
  reg [7:0] data;
  reg [2:0] dindex;

  // logic for selecting data width and managing transmission
  always @(posedge clk, negedge rstn)
  begin
    if (!rstn) begin
      dindex <= 3'b000;
    end
    else begin
      if (start) begin
        // Load data width and start transmission
        case(datawidthsel)
          2'b00: dindex <= 3'b100;  // 5 bits
          2'b01: dindex <= 3'b101;
          2'b10: dindex <= 3'b110;  
          2'b11: dindex <= 3'b111;  // 8 bits
        endcase
      end
      else if (dindex != 0) begin
        dindex <= dindex - 1;
      end
    end
  end

  always @(posedge clk, negedge rstn)
  begin
    if (!rstn) begin
      data <= 0;
      dout <= 1'b0;
    end
    else begin
      if(start)
      begin
        data <= din;
        dout <= din[0];
      end
      else if(dindex != 0)
      begin
        dout <= data[0];
        data <= {1'b0, data[7:1]};
      end
    end
  end

endmodule
