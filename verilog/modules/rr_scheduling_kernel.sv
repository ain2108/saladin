
module rr_scheduling_kernel #(
  parameter ADDR_WIDTH = 4,
  parameter VALUE_WIDTH = 8,
  parameter NCONSUMERS = 2,
  parameter NBANKS = 1,
  parameter NPORTS = 1)
  (
  input [REQ_WIDTH-1:0] requests [NCONSUMERS], 
  output [PLM_INPUT_WIDTH-1:0] plm_inputs [NKERNELS], 
  input [PLM_OUTPUT_WIDTH-1:0] plm_outputs [NKERNELS], 
  output reg [PLM_INPUT_WIDTH-1:0] out [NKERNELS],
  output [RES_WIDTH-1:0] responses [NCONSUMERS], 

  input clk, 
  input reset);

  localparam REQ_WIDTH = ADDR_WIDTH + VALUE_WIDTH + 1 + 1; /* addr, value, wr, valid */
  localparam RES_WIDTH = PLM_OUTPUT_WIDTH + 1; /* value, valid */
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
  reg rr_response_valid_bits [NKERNELS];
  
  reg [$clog2(NCONSUMERS)-1:0] rr_response_pivots [NKERNELS];
  
  wire [PLM_OUTPUT_WIDTH-1+1:0] augumented_plm_outputs[NKERNELS];
  
  /* rr_pivots control */
  genvar g_port_i;
  genvar g_bank_i;
  generate

    /* There is a rr_pivot register for each port of each bank */
		for (g_bank_i = 0; g_bank_i < NBANKS; g_bank_i = g_bank_i + 1) begin
      for (g_port_i = 0; g_port_i < NPORTS; g_port_i = g_port_i + 1) begin
        localparam K_ID = g_bank_i * NPORTS + g_port_i; /* ID of the scheduling kernel */

        /****************************** REQUEST ROUTING ******************************/

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
        
        /****************************** PLM OUTPUT AUGUMENTATION ******************************/

        /* Need to augument the outputs with the validity bits */
        assign augumented_plm_outputs[K_ID] = {plm_outputs[K_ID], rr_response_valid_bits[K_ID]};

        /****************************** PIVOT UPDATE ******************************/
        always @(posedge clk or posedge reset) begin
          
          /* Progress the pivot up, rely on wrapping */
          rr_pivots[K_ID] <= rr_pivots[K_ID] + 1;

          /* Tell the response logic for what consumer is the request being served */
          rr_response_valid_bits[K_ID] <= is_eligible_request;
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

  /****************************** RESPONSE ROUTING ******************************/

  genvar consumer_id;
  generate
    for(consumer_id = 0; consumer_id < NCONSUMERS; consumer_id = consumer_id + 1) begin

      wire [RES_WIDTH-1:0] selected_response;
      
      response_mux #(
        .RES_WIDTH(RES_WIDTH),
        .NKERNELS(NKERNELS),
        .NCONSUMERS(NCONSUMERS),
        .C_ID(consumer_id)
      ) res_mux (
        .augumented_plm_outputs(augumented_plm_outputs),
        .response_pivots(rr_response_pivots),
        .selected_response(selected_response)
      );

      assign responses[consumer_id] = selected_response;

    end
  endgenerate

endmodule