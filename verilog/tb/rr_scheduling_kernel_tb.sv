`include "utils/utils.sv"
`include "modules/rr_scheduling_kernel.sv"

module rr_scheduling_kernel_tb;

  /* Make a reset that pulses once. */
  reg reset = 0;
  /* Make a regular pulsing clock. */
  reg clk = 0;
  reg hello = 0;
  always #5 clk = !clk;

  parameter COUNTER_WIDTH = 8;
  parameter ADDR_WIDTH = 4;
  parameter VALUE_WIDTH = 8;
  parameter NCONSUMERS = 2;
  parameter NBANKS = 1;
  parameter NPORTS = 2;

  localparam REQ_WIDTH = ADDR_WIDTH + VALUE_WIDTH + 1 + 1;
  localparam PLM_INPUT_WIDTH = (ADDR_WIDTH >> $clog2(NBANKS)) + VALUE_WIDTH + 1;
  localparam NKERNELS = NBANKS * NPORTS;


  reg [REQ_WIDTH - 1:0] requests [NCONSUMERS-1:0];
  wire [PLM_INPUT_WIDTH - 1:0] value [NKERNELS-1:0];
  
  integer j = 0;
  initial begin
    for (j =0; j < NKERNELS; j++) begin
      requests[j]= 0;
    end
  end

  rr_scheduling_kernel #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .VALUE_WIDTH(VALUE_WIDTH),
    .NCONSUMERS(NCONSUMERS),
    .NBANKS(NBANKS),
    .NPORTS(NPORTS)
  )
  c1 (
    .out(value),
    .requests(requests),
    .clk(clk),
    .reset(reset));

  initial begin
    $monitor("At time %t, value = %h (%0d)", $time, value[0], value[0]);
  end

  integer i = 0;
  initial begin
    $dumpfile("test.vcd");
    $dumpvars;
    for (i = 0; i < NKERNELS; i++) begin
      $dumpvars(0, value[i]);
    end
  end
  
  initial begin
    
    # 5
    reset = 1;
    # 15
    reset = 0;

    # 5
    // `assert(value[0], 0)
    # 5
    // `assert(value[0], 1)
    $display("%h", value[0]);
    # 5

    # 100 $stop;
  
  end
endmodule // test