module unpack_tx_tb;

  // Testbench signals
  reg clk;
  reg rstn;
  reg start;
  reg [7:0] din;
  reg [1:0] datawidthsel;
  wire dout;

  unpack_tx DUT (
    .clk(clk),
    .rstn(rstn),
    .start(start),
    .din(din),
    .datawidthsel(datawidthsel),
    .dout(dout)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Test procedure
  initial begin
    // Initialize signals
    clk = 0;
    rstn = 1;
    start = 0;
    din = 8'b0;
    datawidthsel = 2'b00;

    // Monitor output
    $monitor("Time=%0t | clk=%b rstn=%b start=%b din=%h datawidthsel=%b | dout=%b", 
             $time, clk, rstn, start, din, datawidthsel, dout);

    // Reset
    #10 rstn = 0;
    #10 rstn = 1;

    // Test Case 1: 5-bit transmission (datawidthsel = 2'b00)
    $display("\n=== Test Case 1: 5-bit transmission ===");
    din = 8'b10101010;
    datawidthsel = 2'b00;
    start = 1;
    #10 start = 0;
    #100;

    /* Test Case 2: 6-bit transmission (datawidthsel = 2'b01)
    $display("\n=== Test Case 2: 6-bit transmission ===");
    din = 8'b11001100;
    datawidthsel = 2'b01;
    start = 1;
    #10 start = 0;
    #120;

    // Test Case 3: 7-bit transmission (datawidthsel = 2'b10)
    $display("\n=== Test Case 3: 7-bit transmission ===");
    din = 8'b11110000;
    datawidthsel = 2'b10;
    start = 1;
    #10 start = 0;
    #140;

    // Test Case 4: 8-bit transmission (datawidthsel = 2'b11)
    $display("\n=== Test Case 4: 8-bit transmission ===");
    din = 8'b10011001;
    datawidthsel = 2'b11;
    start = 1;
    #10 start = 0;
    #160;

    // Test Case 5: Interrupt mid-transmission
    $display("\n=== Test Case 5: Interrupt mid-transmission ===");
    din = 8'b11111111;
    datawidthsel = 2'b11;
    start = 1;
    #10 start = 0;
    #50;  // Interrupt after 50ns
    din = 8'b00000000;
    start = 1;
    #10 start = 0;
    #160;

*/

    $finish;
  end

endmodule
