// ===================================================================
// UVM Testbench for UART TX Module
// ===================================================================

`include "uvm_macros.svh"
import uvm_pkg::*;

// ===================================================================
// Virtual Interface Definition
// ===================================================================
interface uart_tx_if (input logic clk, input logic rst_n);
  logic baud_tick;
  logic [7:0] data;
  logic data_valid;
  logic [2:0] parity;
  logic [1:0] data_bits;
  logic tx_out;
  logic tx_ready;
  logic tx_busy;

  clocking cb @(posedge clk);
    output baud_tick;
    output data;
    output data_valid;
    output parity;
    output data_bits;
    input tx_out;
    input tx_ready;
    input tx_busy;
  endclocking

  modport driver (clocking cb, output baud_tick, data, data_valid, parity, data_bits, input tx_out, tx_ready, tx_busy);
  modport monitor (input baud_tick, data, data_valid, parity, data_bits, tx_out, tx_ready, tx_busy);
endinterface

// ===================================================================
// Sequence Item
// ===================================================================
class uart_tx_seq_item extends uvm_sequence_item;
  `uvm_object_utils(uart_tx_seq_item)

  rand logic [7:0] data_payload;
  rand logic [1:0] data_width;      // 00=5bits, 01=6bits, 10=7bits, 11=8bits
  rand logic [2:0] parity_mode;     // 000=even, 001=odd, 010=mark, 011=space
  logic [2:0] parity_expected;
  logic tx_ready_status;
  logic tx_busy_status;

  constraint data_payload_c { data_payload inside {[0:255]}; }
  constraint data_width_c { data_width inside {[0:3]}; }
  constraint parity_mode_c { parity_mode inside {[0:3]}; }

  function new(string name = "uart_tx_seq_item");
    super.new(name);
  endfunction

  function void post_randomize();
    // Calculate expected parity
    case (parity_mode)
      3'b000: parity_expected = ^data_payload;          // even parity
      3'b001: parity_expected = ~^data_payload;         // odd parity
      3'b010: parity_expected = 3'b001;                 // mark parity
      3'b011: parity_expected = 3'b000;                 // space parity
      default: parity_expected = 0;
    endcase
  endfunction

  function string convert2string();
    return $sformatf("data=0x%02h, width=%0d bits, parity=%s",
      data_payload,
      (data_width == 2'b00) ? 5 : (data_width == 2'b01) ? 6 : (data_width == 2'b10) ? 7 : 8,
      (parity_mode == 3'b000) ? "even" : (parity_mode == 3'b001) ? "odd" : (parity_mode == 3'b010) ? "mark" : "space");
  endfunction
endclass

// ===================================================================
// Driver
// ===================================================================
class uart_tx_driver extends uvm_driver #(uart_tx_seq_item);
  `uvm_component_utils(uart_tx_driver)

  virtual uart_tx_if vif;
  uart_tx_seq_item req;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_build_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_tx_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not found")
  endfunction

  task run_phase(uvm_run_phase phase);
    forever begin
      seq_item_port.get_next_item(req);
      drive_transaction(req);
      seq_item_port.item_done();
    end
  endtask

  task drive_transaction(uart_tx_seq_item txn);
    `uvm_info("DRIVER", $sformatf("Driving: %s", txn.convert2string()), UVM_MEDIUM)
    
    vif.cb.data <= txn.data_payload;
    vif.cb.data_bits <= txn.data_width;
    vif.cb.parity <= txn.parity_mode;
    vif.cb.data_valid <= 1'b1;
    @(vif.cb);
    
    vif.cb.data_valid <= 1'b0;
    
    // Wait for transmission to complete (tx_busy goes low)
    while (vif.cb.tx_busy) begin
      vif.cb.baud_tick <= 1'b1;
      @(vif.cb);
      vif.cb.baud_tick <= 1'b0;
      @(vif.cb);
    end
  endtask
endclass

// ===================================================================
// Monitor
// ===================================================================
class uart_tx_monitor extends uvm_monitor;
  `uvm_component_utils(uart_tx_monitor)

  virtual uart_tx_if vif;
  uvm_analysis_port #(uart_tx_seq_item) item_collected_port;
  uart_tx_seq_item collected_item;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    item_collected_port = new("item_collected_port", this);
  endfunction

  function void build_phase(uvm_build_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_tx_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not found")
  endfunction

  task run_phase(uvm_run_phase phase);
    forever begin
      @(posedge vif.data_valid);
      collect_transaction();
    end
  endtask

  task collect_transaction();
    collected_item = uart_tx_seq_item::type_id::create("collected_item");
    collected_item.data_payload = vif.data;
    collected_item.data_width = vif.data_bits;
    collected_item.parity_mode = vif.parity;
    collected_item.tx_ready_status = vif.tx_ready;
    collected_item.tx_busy_status = vif.tx_busy;
    
    `uvm_info("MONITOR", $sformatf("Collected: %s", collected_item.convert2string()), UVM_MEDIUM)
    item_collected_port.write(collected_item);
  endtask
endclass

// ===================================================================
// Sequencer
// ===================================================================
class uart_tx_sequencer extends uvm_sequencer #(uart_tx_seq_item);
  `uvm_component_utils(uart_tx_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass

// ===================================================================
// Base Sequence
// ===================================================================
class uart_tx_base_seq extends uvm_sequence #(uart_tx_seq_item);
  `uvm_object_utils(uart_tx_base_seq)

  function new(string name = "uart_tx_base_seq");
    super.new(name);
  endfunction

  task body();
    `uvm_info("SEQ", "Base sequence body", UVM_LOW)
  endtask
endclass

// ===================================================================
// Simple Sequence - Single Transaction
// ===================================================================
class uart_tx_simple_seq extends uart_tx_base_seq;
  `uvm_object_utils(uart_tx_simple_seq)

  logic [7:0] data_val = 8'hA5;
  logic [1:0] width_val = 2'b11;  // 8 bits
  logic [2:0] parity_val = 3'b000;  // even

  function new(string name = "uart_tx_simple_seq");
    super.new(name);
  endfunction

  task body();
    req = uart_tx_seq_item::type_id::create("req");
    start_item(req);
    req.data_payload = data_val;
    req.data_width = width_val;
    req.parity_mode = parity_val;
    req.randomize_with {};
    finish_item(req);
    `uvm_info("SEQ", $sformatf("Sent: %s", req.convert2string()), UVM_LOW)
  endtask
endclass

// ===================================================================
// Random Sequence - Multiple Random Transactions
// ===================================================================
class uart_tx_random_seq extends uart_tx_base_seq;
  `uvm_object_utils(uart_tx_random_seq)

  int num_trans = 10;

  function new(string name = "uart_tx_random_seq");
    super.new(name);
  endfunction

  task body();
    repeat (num_trans) begin
      req = uart_tx_seq_item::type_id::create("req");
      start_item(req);
      if (!req.randomize())
        `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      `uvm_info("SEQ", $sformatf("Sent transaction %0d: %s", num_trans, req.convert2string()), UVM_LOW)
    end
  endtask
endclass

// ===================================================================
// Scoreboard
// ===================================================================
class uart_tx_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(uart_tx_scoreboard)

  uvm_analysis_imp #(uart_tx_seq_item, uart_tx_scoreboard) item_collected_imp;

  int total_transactions = 0;
  int error_count = 0;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    item_collected_imp = new("item_collected_imp", this);
  endfunction

  function void write(uart_tx_seq_item item);
    total_transactions++;
    
    // Validate transaction
    if (item.data_width > 3 || item.parity_mode > 3) begin
      `uvm_error("SCOREBOARD", $sformatf("Invalid transaction: %s", item.convert2string()))
      error_count++;
    end else begin
      `uvm_info("SCOREBOARD", $sformatf("Transaction %0d verified: %s", total_transactions, item.convert2string()), UVM_MEDIUM)
    end
  endfunction

  function void report_phase(uvm_report_phase phase);
    super.report_phase(phase);
    `uvm_info("SCOREBOARD", $sformatf("Total Transactions: %0d, Errors: %0d", total_transactions, error_count), UVM_LOW)
  endfunction
endclass

// ===================================================================
// Agent
// ===================================================================
class uart_tx_agent extends uvm_agent;
  `uvm_component_utils(uart_tx_agent)

  uart_tx_driver driver;
  uart_tx_sequencer sequencer;
  uart_tx_monitor monitor;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_build_phase phase);
    super.build_phase(phase);
    driver = uart_tx_driver::type_id::create("driver", this);
    sequencer = uart_tx_sequencer::type_id::create("sequencer", this);
    monitor = uart_tx_monitor::type_id::create("monitor", this);
  endfunction

  function void connect_phase(uvm_connect_phase phase);
    super.connect_phase(phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction
endclass

// ===================================================================
// Environment
// ===================================================================
class uart_tx_env extends uvm_env;
  `uvm_component_utils(uart_tx_env)

  uart_tx_agent agent;
  uart_tx_scoreboard scoreboard;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_build_phase phase);
    super.build_phase(phase);
    agent = uart_tx_agent::type_id::create("agent", this);
    scoreboard = uart_tx_scoreboard::type_id::create("scoreboard", this);
  endfunction

  function void connect_phase(uvm_connect_phase phase);
    super.connect_phase(phase);
    agent.monitor.item_collected_port.connect(scoreboard.item_collected_imp);
  endfunction
endclass

// ===================================================================
// Base Test
// ===================================================================
class uart_tx_base_test extends uvm_test;
  `uvm_component_utils(uart_tx_base_test)

  uart_tx_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_build_phase phase);
    super.build_phase(phase);
    env = uart_tx_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_run_phase phase);
    phase.raise_objection(this);
    #100 phase.drop_objection(this);
  endtask
endclass

// ===================================================================
// Simple Test
// ===================================================================
class uart_tx_simple_test extends uart_tx_base_test;
  `uvm_component_utils(uart_tx_simple_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_run_phase phase);
    uart_tx_simple_seq seq;
    phase.raise_objection(this);
    
    seq = uart_tx_simple_seq::type_id::create("seq");
    seq.start(env.agent.sequencer);
    
    #1000;
    phase.drop_objection(this);
  endtask
endclass

// ===================================================================
// Random Test
// ===================================================================
class uart_tx_random_test extends uart_tx_base_test;
  `uvm_component_utils(uart_tx_random_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_run_phase phase);
    uart_tx_random_seq seq;
    phase.raise_objection(this);
    
    seq = uart_tx_random_seq::type_id::create("seq");
    seq.num_trans = 10;
    seq.start(env.agent.sequencer);
    
    #5000;
    phase.drop_objection(this);
  endtask
endclass

// ===================================================================
// Top Level Testbench
// ===================================================================
module uart_tx_uvm_tb_top;
  logic clk;
  logic rst_n;

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Reset generation
  initial begin
    rst_n = 0;
    #20 rst_n = 1;
  end

  // Virtual interface instantiation
  uart_tx_if intf (clk, rst_n);

  // DUT instantiation
  uart_tx dut (
    .clk_i(clk),
    .rst_n_i(rst_n),
    .baud_tick_i(intf.baud_tick),
    .data_i(intf.data),
    .data_valid_i(intf.data_valid),
    .parity_i(intf.parity),
    .data_bits_i(intf.data_bits),
    .tx_o(intf.tx_out),
    .tx_ready_o(intf.tx_ready),
    .tx_busy_o(intf.tx_busy)
  );

  initial begin
    // Register virtual interface with config_db
    uvm_config_db#(virtual uart_tx_if)::set(null, "uvm_test_top", "vif", intf);
    
    // Run the test
    run_test();
  end

  initial begin
    // Waveform dump
    $dumpfile("uart_tx_uvm.vcd");
    $dumpvars(0, uart_tx_uvm_tb_top);
  end

endmodule
