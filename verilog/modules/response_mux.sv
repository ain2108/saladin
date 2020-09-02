module response_mux #(
  parameter RES_WIDTH = 20,
  parameter NKERNELS = 4,
  parameter NCONSUMERS = 8,
  parameter C_ID = 0)
  (
  input [RES_WIDTH-1:0] augumented_plm_outputs [NKERNELS],
  input [$clog2(NCONSUMERS)-1:0] response_pivots [NKERNELS],
  output reg [RES_WIDTH-1:0] selected_response);

  /* 
    Produce a 1-hot where the asserted bit represents the k_id of the port where the respone is for this C_ID.
  */

  wire [NKERNELS-1:0] one_hot_selector; 
  genvar k_id;
  generate
      for(k_id = 0; k_id < NKERNELS; k_id = k_id + 1) begin
          /* A request can only be handled by one port, so RHS will only be 1 for a single k_id if any */
          assign one_hot_selector[k_id] = (response_pivots[k_id] == C_ID);         
      end
  endgenerate

  /*
    One-hot mux
    https://stackoverflow.com/questions/19875899/how-to-define-a-parameterized-multiplexer-using-systemverilog
  */
  always @(*) begin
      selected_response = 0;
      for(int i = 0; i < NKERNELS; i++) begin
          if (one_hot_selector == (1 << i))
            selected_response = augumented_plm_outputs[i];
      end
  end
endmodule