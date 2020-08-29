
module request_mux #(
  parameter REQ_WIDTH = 10,
  parameter REQ_NUMBER = 16)
  (
  input [REQ_WIDTH-1:0] requests [REQ_NUMBER],
  input [$clog2(REQ_NUMBER)-1: 0] select,
  output [REQ_WIDTH-1:0] selected_request
);
  assign selected_request = requests[select];
endmodule