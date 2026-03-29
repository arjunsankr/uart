// data unpacking from 8 bit parallel to serial

module unpack_tx(
    input clk,
    input rstn,
    input start
    input [7:0] din,
    input [1:0] datawidthsel,
    output reg dout
);

  // internal registers
  reg [7:0] data;
  reg [2:0] dindex;

  // logic for selecting data width
  always @(posedge clk, negedge rstn)
  begin
    if (!rstn)
      dindex <= 3'b000;
    else
        case(datawidthsel)
            00:dindex <= 3'b100;
            01:dindex<=3'b111;
        endcase
  end
      if(dindex!=0)
          dindex<=dindex-1;
  end

  always @(posedge clk, negedge rstn)
  begin
    if (!rstn)
      data <= 0;
      else
          begin
               if(start)
                 begin
                 data<=din;
                     dout<=din[0];
                 end
              else
                  begin
                      dout<=data[0];
                      data<={1'b0,data[7:1]};
                  end
          end
      
      /*begin
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
*/
endmodule
