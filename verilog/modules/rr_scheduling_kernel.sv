module rr_scheduling_kernel #(
  parameter ADDR_WIDTH = 4,
  parameter VALUE_WIDTH = 8,
  parameter NCONSUMERS = 2,
  parameter NBANKS = 1,
  parameter NPORTS = 1)
  (
  output reg [PLM_INPUT_WIDTH-1:0] out [NKERNELS-1:0], 
  input [REQ_WIDTH-1:0] requests [NCONSUMERS-1:0],
  input clk, 
  input reset);

  localparam REQ_WIDTH = ADDR_WIDTH + VALUE_WIDTH + 1 + 1;
  localparam PLM_INPUT_WIDTH = (ADDR_WIDTH >> $clog2(NBANKS)) + VALUE_WIDTH + 1;
  localparam NKERNELS = NBANKS * NPORTS;
  
  genvar j;
  generate
		for (j = 0; j < NKERNELS; j = j + 1) begin
      assign out[j] = j;
    end
  endgenerate

  // genvar i;
  // generate
	// 	for (i = 0; i < NKERNELS; i = i + 1) begin
  //     always @(posedge clk or posedge reset) begin
  //       if (reset) begin
  //         out[i] <= 0;
  //       end else begin
  //         out[i] <= out[i] + 1;
  //       end
  //     end
  //   end
  // endgenerate

endmodule // counter