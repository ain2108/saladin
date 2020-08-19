module rr_scheduling_kernel_tb;

  /* Make a reset that pulses once. */
  reg reset = 0;
  initial begin
    $dumpfile("test.vcd");
    $dumpvars(0,rr_scheduling_kernel_tb);

    # 17 reset = 1;
    # 11 reset = 0;
    # 29 reset = 1;
    # 11 reset = 0;
    # 100 $stop;
  end

  /* Make a regular pulsing clock. */
  reg clk = 0;
  always #5 clk = !clk;

  parameter COUNTER_WIDTH = 8;
  parameter ADDR_WIDTH = 4;
  parameter VALUE_WIDTH = 8;
  parameter NCONSUMERS = 2;
  parameter NBANKS = 1;
  parameter NPORTS = 1;

  parameter REQ_WIDTH = ADDR_WIDTH + VALUE_WIDTH + 1;

  wire [COUNTER_WIDTH - 1:0] value;

  reg [REQ_WIDTH - 1:0] requests [NCONSUMERS];
  
  initial begin
    requests[0][REQ_WIDTH-1:0] = 0;
    requests[1][REQ_WIDTH-1:0] = 0;
  end

  rr_scheduling_kernel #(
    .WIDTH(8),
    .ADDR_WIDTH(ADDR_WIDTH),
    .VALUE_WIDTH(VALUE_WIDTH),
    .NCONSUMERS(NCONSUMERS),
    .NBANKS(NBANKS),
    .NPORTS(NPORTS)
  )
  c1 (value, requests, clk, reset);

  initial
    $monitor("At time %t, value = %h (%0d)", $time, value, value);
endmodule // test