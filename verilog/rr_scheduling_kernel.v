module rr_scheduling_kernel #(
  parameter WIDTH = 8,
  parameter ADDR_WIDTH = 4,
  parameter VALUE_WIDTH = 8,
  parameter NCONSUMERS = 2,
  parameter NBANKS = 1,
  parameter NPORTS = 2)
  (
  output reg [WIDTH-1 : 0] out, 
  input [ADDR_WIDTH + VALUE_WIDTH + 1 - 1:0] requests [NCONSUMERS],
  input clk, 
  input reset);

  parameter REQ_WIDTH = ADDR_WIDTH + VALUE_WIDTH + 1;

  always @(posedge clk or posedge reset) begin
    if (reset)
      out <= 0;
    else
      out <= out + 1;
  end

endmodule // counter