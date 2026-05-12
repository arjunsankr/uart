module uart_tx_fifo #(
  parameter int DATA_WIDTH = 8,
  parameter int ADDR_WIDTH = 11
)(
  input  logic                  clk_i,
  input  logic                  rst_n_i,
  input  logic                  wr_en_i,
  input  logic [DATA_WIDTH-1:0] wr_data_i,
  output logic                  full_o,
  input  logic                  rd_en_i,
  output logic [DATA_WIDTH-1:0] rd_data_o,
  output logic                  empty_o
);

  logic [DATA_WIDTH-1:0] mem_q [(1<<ADDR_WIDTH)-1:0];
  logic [ADDR_WIDTH:0] wr_ptr_q;
  logic [ADDR_WIDTH:0] rd_ptr_q;

  assign empty_o = (wr_ptr_q == rd_ptr_q);
  assign full_o  = (wr_ptr_q[ADDR_WIDTH] != rd_ptr_q[ADDR_WIDTH]) && 
                   (wr_ptr_q[ADDR_WIDTH-1:0] == rd_ptr_q[ADDR_WIDTH-1:0]);

  always_ff @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
      wr_ptr_q <= '0;
    end else if (wr_en_i && !full_o) begin
      mem_q[wr_ptr_q[ADDR_WIDTH-1:0]] <= wr_data_i;
      wr_ptr_q <= wr_ptr_q + 1;
    end
  end

  always_ff @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
      rd_ptr_q  <= '0;
      rd_data_o <= '0;
    end else if (rd_en_i && !empty_o) begin
      rd_data_o <= mem_q[rd_ptr_q[ADDR_WIDTH-1:0]];
      rd_ptr_q  <= rd_ptr_q + 1;
    end
  end

endmodule
