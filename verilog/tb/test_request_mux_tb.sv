`include "modules/request_mux.sv"
`include "utils/utils.sv"

`default_nettype none

module test_request_mux;
    
    reg clk;
    reg rst;

    localparam CLK_PERIOD = 10;
    initial begin
        clk = 1'b0;
        rst = 1'b1;
        repeat(4) #(CLK_PERIOD/2) clk = ~clk;
        rst = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk; // generate a clock
    end


    localparam REQ_WIDTH = 32;
    localparam NCONSUMERS = 8;

    reg [REQ_WIDTH-1:0] requests [NCONSUMERS];
    reg [$clog2(NCONSUMERS)-1:0] select;
    wire [REQ_WIDTH-1:0] selected_request;
    
    request_mux #(
        .REQ_NUMBER(NCONSUMERS),
        .REQ_WIDTH(REQ_WIDTH)
    ) rqm (
        .requests(requests),
        .select(select),
        .selected_request(selected_request)
        );

    // initial begin
    //     $dumpfile("test.vcd");
    //     $dumpvars;
    // end


    initial begin

        requests[0] = REQ_WIDTH'(0);
        requests[1] = REQ_WIDTH'(1000);
        requests[2] = REQ_WIDTH'(2000);
        requests[3] = REQ_WIDTH'(3000);
        requests[4] = REQ_WIDTH'(4000);
        requests[5] = REQ_WIDTH'(5000);
        requests[6] = REQ_WIDTH'(6000);
        requests[7] = REQ_WIDTH'(7000);
        
        @(negedge rst); // wait for reset

        $write("================== TEST request mux ==================\n");
        $write("TEST: mux selects the request correctly .... ");

        @(posedge clk);
        select = 0;
        @(posedge clk);
        `assert(selected_request, 0)

        @(posedge clk);
        select = 3;
        @(posedge clk);
        `assert(selected_request, 3000)
        
        @(posedge clk);
        select = 5;
        @(posedge clk);
        `assert(selected_request, 5000)
        
        @(posedge clk);
        select = 7;
        @(posedge clk);
        `assert(selected_request, 7000)
        
        @(posedge clk);
        select = 4;
        @(posedge clk);
        `assert(selected_request, 4000)

        $write("PASS\n");

        repeat(200) @(posedge clk);
        repeat(1) @(posedge clk);

        $write("\n");

        repeat(2) @(posedge clk);
        $finish(2);
    end

endmodule
`default_nettype wire