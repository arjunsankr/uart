module uart_tx( 
  input logic clk_i,
  input logic rst_n_i,
  input logic baud_tick_i,
  input logic [7:0]data_i,
  input logic data_valid_i,
  //input logic stop_bits_i,
  input logic [2:0]parity_i,
  input logic [1:0]data_bits_i,
  output logic tx_o,
  output logic tx_ready_o,
  output logic tx_busy_o
);

  //internal registers 
  logic [7:0]tx_shift_reg_q;// for internal shifting of data
  logic [2:0]bit_cnt_q;// to count number of bits
  logic [2:0]data_bit_max; //Max index
  //logic [3:0]tick_cnt_q;
  logic parity_bit; //calculated parity value
  logic [2:0]dindex;

  //reset logic
  always @(posedge clk_i or negedge rst_n_i)
    begin 
      if (!rst_n_i)
        begin 
          //tx_o<= 1'b1; 
          tx_ready_o<= 1'b1;
          //bit_cnt_q<= 3'b0;
          //parity_bit<= 1'b0;
        end
    end
  
//data index selection
  always @(posedge clk_i or negedge rst_n_i)
  begin
    if (!rst_n_i) begin
      bit_cnt_q<= 3'b000;
    end
    else begin
      if (data_valid_i) begin
        // Load data width and start transmission
        case(data_bits_i)
          2'b00: bit_cnt_q <= 3'b100;// 5 bits
          2'b01: bit_cnt_q<= 3'b101;  // 6 bits    
          2'b10: bit_cnt_q <= 3'b110;  // 7  bits
          2'b11: bit_cnt_q <= 3'b111;  // 8 bits
        endcase
        dindex<=bit_cnt_i
      end
      else if (bit_cnt_q >0) begin
        bit_cnt_q<= bit_cnt_q - 1;
      end
    end
  end 
  
  //parity bit calculation
  always@(data_valid_i)
    begin
      if(parity_i==3'b000)
        parity_bit <= ^tx_shift_reg_q;
      else if(parity_i==3'b001)
        parity_bit<=~^tx_shift_reg_q;
      else if(parity_i==3'b010)
        parity_bit<=1'b1; //mark parity
      else if (parity_i==3'b011)
        parity_bit<=1'b0;
    end

  //output logic
  always@(baud_tick_i)
    begin
      if(bit_cnt_q==0)
        begin 
          tx_o<=parity_bit;
        end
      else 
        begin
          tx_o<=tx_shift_reg_q[0];
          tx_shift_reg_q<={1'b0,tx_shift_reg_q[7:1]};
        end
    end
endmodule
