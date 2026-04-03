module uart_tx( 
  input logic clk_i,
  input logic rst_n_i,
  input logic baud_tick_i,
  input logic [7:0]data_i,
  input logic data_valid_i,
  //input logic stop_bits_i,
  input logic parity_i,
  input logic data_bits_i;
  
               
