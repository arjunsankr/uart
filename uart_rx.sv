module uart_rx( 
  input logic clk_i,
  input logic rst_n_i,
  input logic baud_tick_i,
  input logic rx_i,
  input logic start,// for testing only
  //input logic stop_bits_i,
  input logic [2:0] parity_i,
  input logic [1:0] data_bits_i,
  output logic [7:0] data_o,       // changed
  output logic data_valid_o,       // changed
  output logic rx_busy_o           // changed
);

  //internal registers 
  logic [7:0]rx_shift_reg_q; // for internal shifting of data
  logic [2:0]bit_cnt_q;// to count number of bits
  logic [2:0]data_bit_max; //Max index
  //logic [3:0]tick_cnt_q;
  logic parity_bit; //calculated parity value
  
//data index selection
  always @(posedge clk_i or negedge rst_n_i)
  begin
    if (!rst_n_i) begin
      bit_cnt_q<= 3'b000;
    end
    else begin
      if (start) begin   // changed from data_valid_i
        case(data_bits_i)
          2'b00: bit_cnt_q <= 3'b100;// 5 bits
          2'b01: bit_cnt_q<= 3'b101;  // 6 bits    
          2'b10: bit_cnt_q <= 3'b110;  // 7  bits
          2'b11: bit_cnt_q <= 3'b111;  // 8 bits
        endcase
      end
      else if (bit_cnt_q >0) begin
        bit_cnt_q<= bit_cnt_q - 1;
      end
    end
  end 
  
  //parity bit calculation
  always@(posedge clk_i or negedge rst_n_i)
    begin
      if (!rst_n_i)
        begin 
          parity_bit<=0;
        end
      else if(parity_i==3'b000)
        parity_bit <= ^rx_shift_reg_q;
      else if(parity_i==3'b001)
        parity_bit<=~^rx_shift_reg_q;
      else if(parity_i==3'b010)
        parity_bit<=1'b1; //mark parity
      else if (parity_i==3'b011)
        parity_bit<=1'b0;
    end

  //output logic
  always@(posedge clk_i or negedge rst_n_i)
    begin
      if(!rst_n_i)
        begin
          rx_shift_reg_q<=0;
          data_o<=0;
        end
      else
        begin
          if(baud_tick_i && bit_cnt_q>0 )begin   // changed from data_valid_i
            rx_shift_reg_q <= {rx_i, rx_shift_reg_q[7:1]}; // shift in
          /*else if(baud_tick_i && bit_cnt_q==0)
        begin 
          rx_shift_reg_q <= {rx_i, rx_shift_reg_q[7:1]};*/
        end
      else 
        begin
          data_o <= rx_shift_reg_q;
        end
    end
    end

endmodule
