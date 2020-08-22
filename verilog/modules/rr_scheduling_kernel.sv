`include "utils/utils.sv"

module rr_scheduling_kernel #(
  parameter ADDR_WIDTH = 4,
  parameter VALUE_WIDTH = 8,
  parameter NCONSUMERS = 2,
  parameter NBANKS = 1,
  parameter NPORTS = 1)
  (
  output reg [PLM_INPUT_WIDTH-1:0] out [NKERNELS], 
  input [REQ_WIDTH-1:0] requests [NCONSUMERS],
  input clk, 
  input reset);

  localparam REQ_WIDTH = ADDR_WIDTH + VALUE_WIDTH + 1 + 1;
  localparam PLM_INPUT_WIDTH = (ADDR_WIDTH >> $clog2(NBANKS)) + VALUE_WIDTH + 1;

  initial begin
    `assert_true((NPORTS == 1 || NPORTS == 2), "unspuported number of PLM ports")
  end

  // NOTE: Must be > 1. Otherwise barfs up "failed assertion prts[0]->unpacked_dimensions()==0"
  localparam NKERNELS = NBANKS * NPORTS;

  localparam PIVOT_DIFF = NCONSUMERS / NPORTS;

  /* Registers that remember the RR pivots. 
     Structure:
          bank_0_port_0
          bank_0_port_1
              ...
          bank_1_port_0
          bank_1_port_1
  */
  reg [$clog2(NCONSUMERS)-1:0] rr_pivots [NKERNELS];
  
  genvar j;
  generate
		for (j = 0; j < NKERNELS; j = j + 1) begin
      assign out[j] = j;
    end
  endgenerate


  /* rr_pivots control */
  genvar g_port_i;
  genvar g_bank_i;
  generate

    /* There is a rr_pivot register for each port of each bank */
		for (g_bank_i = 0; g_bank_i < NBANKS; g_bank_i = g_bank_i + 1) begin
      for (g_port_i = 0; g_port_i < NPORTS; g_port_i = g_port_i + 1) begin
        
        always @(posedge clk or posedge reset) begin
          if (reset) begin

            /* Maximize the spread of pivots */
            rr_pivots[g_bank_i * NPORTS + g_port_i] = g_bank_i + g_port_i * PIVOT_DIFF;

          end else begin

            /* Progress the pivot up, rely on wrapping */
            rr_pivots[g_bank_i * NPORTS + g_port_i] = rr_pivots[g_bank_i * NPORTS + g_port_i] + 1;

            /* Tell the response logic how to route the PLM output */
          end
        end
      end
    end
  endgenerate

endmodule // counter