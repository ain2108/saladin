
module rr_scheduling_kernel #(
  parameter ADDR_WIDTH = 4,
  parameter VALUE_WIDTH = 8,
  parameter NCONSUMERS = 2,
  parameter NBANKS = 1,
  parameter NPORTS = 1)
  (
  output reg [PLM_INPUT_WIDTH-1:0] out [NKERNELS], 
  output [PLM_INPUT_WIDTH-1:0] plm_inputs [NKERNELS], 
  input [PLM_OUTPUT_WIDTH-1:0] plm_outputs [NKERNELS], 
  input [REQ_WIDTH-1:0] requests [NCONSUMERS], 
  input clk, 
  input reset);

  localparam REQ_WIDTH = ADDR_WIDTH + VALUE_WIDTH + 1 + 1; /* addr, value, wr, valid */
  localparam NUM_BANK_BITS = $clog2(NBANKS);
  localparam PLM_INPUT_WIDTH = (ADDR_WIDTH - NUM_BANK_BITS) + VALUE_WIDTH + 1;
  localparam PLM_OUTPUT_WIDTH = VALUE_WIDTH;

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
  reg [$clog2(NCONSUMERS)-1:0] rr_response_pivots [NKERNELS];
  reg [$clog2(NCONSUMERS)-1:0] rr_response_valid_bits [NKERNELS];
  
  genvar j;
  generate
		for (j = 0; j < NKERNELS; j = j + 1) begin
      assign out[j] = j;
    end
  endgenerate

  wire [NKERNELS-1:0] _debug_kernel_statuses;


  /* rr_pivots control */
  genvar g_port_i;
  genvar g_bank_i;
  generate

    /* There is a rr_pivot register for each port of each bank */
		for (g_bank_i = 0; g_bank_i < NBANKS; g_bank_i = g_bank_i + 1) begin
      for (g_port_i = 0; g_port_i < NPORTS; g_port_i = g_port_i + 1) begin

        /****************************** REQUEST ROUTING ******************************/
        localparam K_ID = g_bank_i * NPORTS + g_port_i; /* ID of the scheduling kernel */

        /* Determine validity of the candidate that the pivot is pointing to */
        wire [REQ_WIDTH-1:0] lead_candidate; /* Bits of the request that pivot is pointing to */
        wire [$clog2(NCONSUMERS)-1:0] sel_candidate; /* Candidate select */
        wire [NUM_BANK_BITS-1:0] bank_address; /* Address bit of the said candidate */
        wire is_candidate_addr_in_range; /* Is the address in range of the bank? */
        wire is_valid_bit; /* Is the candidate valid bit set? */
        wire is_eligible_request; /* Is this a request eligible for scheduling? */

        assign sel_candidate = rr_pivots[K_ID];
        request_mux #( .REQ_WIDTH(REQ_WIDTH), .REQ_NUMBER(NCONSUMERS)) req_mux (
          .requests(requests), .select(sel_candidate), .selected_request(lead_candidate));

        assign bank_address = lead_candidate[REQ_WIDTH-1:REQ_WIDTH-NUM_BANK_BITS];

        assign is_candidate_addr_in_range = (bank_address == g_bank_i);
        assign is_valid_bit = lead_candidate[0];
        assign is_eligible_request = is_candidate_addr_in_range && is_valid_bit;

        assign plm_inputs[K_ID] = (is_eligible_request) ? 
          lead_candidate[REQ_WIDTH-1:1] /* not including request valid bit */
          : 0; /* All 0s is wr=0, this its a resource read */

        assign _debug_kernel_statuses[K_ID] = is_eligible_request;
        
        /****************************** RESPONSE ROUTING ******************************/

        /****************************** PIVOT UPDATE ******************************/
        always @(posedge clk or posedge reset) begin
          
          /* Progress the pivot up, rely on wrapping */
          rr_pivots[K_ID] <= rr_pivots[K_ID] + 1;

          /* Tell the response logic that next cycle will have a response */
          rr_response_valid_bits[K_ID] <= is_eligible_request;
          
          /* Tell the response logic how to route the PLM output */
          rr_response_pivots[K_ID] <= rr_pivots[K_ID];

          if (reset) begin
            /* Maximize the spread of pivots */
            rr_pivots[K_ID] <= g_bank_i + g_port_i * PIVOT_DIFF;
            rr_response_valid_bits[K_ID] <= 1'b0;
          end
        end
      end
    end
  endgenerate

endmodule