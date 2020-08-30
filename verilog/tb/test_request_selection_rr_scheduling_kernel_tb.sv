

`default_nettype none

module test_request_selection_rr_scheduling_kernel_tb;
    
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

    parameter ADDR_WIDTH = 10;
    parameter VALUE_WIDTH = 8;
    parameter NCONSUMERS = 8;
    parameter NBANKS = 4;
    parameter NPORTS = 2;

    localparam REQ_WIDTH = ADDR_WIDTH + VALUE_WIDTH + 1 + 1;
    localparam PLM_ADDR_WIDTH = ADDR_WIDTH - $clog2(NBANKS);
    localparam PLM_INPUT_WIDTH = PLM_ADDR_WIDTH + VALUE_WIDTH + 1;
    localparam NKERNELS = NBANKS * NPORTS;

    reg [REQ_WIDTH-1:0] requests [NCONSUMERS];
    wire [PLM_INPUT_WIDTH-1:0] plm_inputs[NKERNELS];
    
    rr_scheduling_kernel #(
        .NCONSUMERS(NCONSUMERS),
        .NBANKS(NBANKS),
        .NPORTS(NPORTS),
        .ADDR_WIDTH(ADDR_WIDTH),
        .VALUE_WIDTH(VALUE_WIDTH)
    ) rsk (
        .clk(clk),
        .reset(rst),
        .requests(requests),
        .plm_inputs(plm_inputs)
        );

    integer i = 0;
    initial begin
        $dumpfile("test.vcd");
        for(i = 0; i < NCONSUMERS; i++) begin
            $dumpvars(0, rsk.requests[i]);
        end
        
        for(i = 0; i < NKERNELS; i++) begin
            $dumpvars(0, rsk.plm_inputs[i]);
        end
        $dumpvars;
    end

    wire [PLM_ADDR_WIDTH-1:0] plm_0_addr;
    wire [VALUE_WIDTH-1:0] plm_0_val;
    wire plm_0_wr;
    wire [PLM_INPUT_WIDTH-1:0] plm_0;

    assign plm_0 = plm_inputs[0];
    assign plm_0_addr = plm_0[PLM_INPUT_WIDTH-1-: PLM_ADDR_WIDTH];
    assign plm_0_val = plm_0[PLM_INPUT_WIDTH-PLM_ADDR_WIDTH-1 -: VALUE_WIDTH];
    assign plm_0_wr = plm_0[PLM_INPUT_WIDTH-PLM_ADDR_WIDTH-VALUE_WIDTH-1 -: 1];

    wire [PLM_ADDR_WIDTH-1:0] plm_1_addr;
    wire [VALUE_WIDTH-1:0] plm_1_val;
    wire plm_1_wr;
    wire [PLM_INPUT_WIDTH-1:0] plm_1;

    assign plm_1 = plm_inputs[1];
    assign plm_1_addr = plm_1[PLM_INPUT_WIDTH-1-: PLM_ADDR_WIDTH];
    assign plm_1_val = plm_1[PLM_INPUT_WIDTH-PLM_ADDR_WIDTH-1 -: VALUE_WIDTH];
    assign plm_1_wr = plm_1[PLM_INPUT_WIDTH-PLM_ADDR_WIDTH-VALUE_WIDTH-1 -: 1];
    
    wire [PLM_ADDR_WIDTH-1:0] plm_2_addr;
    wire [VALUE_WIDTH-1:0] plm_2_val;
    wire plm_2_wr;
    wire [PLM_INPUT_WIDTH-1:0] plm_2;
    assign plm_2 = plm_inputs[2];
    assign plm_2_addr = plm_2[PLM_INPUT_WIDTH-1-: PLM_ADDR_WIDTH];
    assign plm_2_val = plm_2[PLM_INPUT_WIDTH-PLM_ADDR_WIDTH-1 -: VALUE_WIDTH];
    assign plm_2_wr = plm_2[PLM_INPUT_WIDTH-PLM_ADDR_WIDTH-VALUE_WIDTH-1 -: 1];

    wire [PLM_ADDR_WIDTH-1:0] plm_4_addr;
    wire [VALUE_WIDTH-1:0] plm_4_val;
    wire plm_4_wr;
    wire [PLM_INPUT_WIDTH-1:0] plm_4;
    assign plm_4 = plm_inputs[4];
    assign plm_4_addr = plm_4[PLM_INPUT_WIDTH-1-: PLM_ADDR_WIDTH];
    assign plm_4_val = plm_4[PLM_INPUT_WIDTH-PLM_ADDR_WIDTH-1 -: VALUE_WIDTH];
    assign plm_4_wr = plm_4[PLM_INPUT_WIDTH-PLM_ADDR_WIDTH-VALUE_WIDTH-1 -: 1];

    wire [PLM_ADDR_WIDTH-1:0] plm_6_addr;
    wire [VALUE_WIDTH-1:0] plm_6_val;
    wire plm_6_wr;
    wire [PLM_INPUT_WIDTH-1:0] plm_6;
    assign plm_6 = plm_inputs[6];
    assign plm_6_addr = plm_6[PLM_INPUT_WIDTH-1-: PLM_ADDR_WIDTH];
    assign plm_6_val = plm_6[PLM_INPUT_WIDTH-PLM_ADDR_WIDTH-1 -: VALUE_WIDTH];
    assign plm_6_wr = plm_6[PLM_INPUT_WIDTH-PLM_ADDR_WIDTH-VALUE_WIDTH-1 -: 1];

    initial begin

        for(i = 0; i < NCONSUMERS; i++) begin
            requests[i] = REQ_WIDTH'(0);
        end

        @(negedge rst); // wait for reset
        
        $write("================== TEST request selection ==================\n");
        $write("TEST: a valid requests is routed to all ports eventually .... ");
        
        @(posedge clk); // reset
        rst = 1'b1;
        @(posedge clk);
        rst = 1'b0;
        requests[0] = {ADDR_WIDTH'(2), VALUE_WIDTH'(25), 1'b1, 1'b1}; 

        @(posedge clk); // pivots 1-5
        `assert(plm_0_addr, ADDR_WIDTH'(0));
        `assert(plm_0_val, ADDR_WIDTH'(0));
        `assert(plm_0_wr, ADDR_WIDTH'(0));
        `assert(plm_1_addr, ADDR_WIDTH'(0));
        `assert(plm_1_val, ADDR_WIDTH'(0));
        `assert(plm_1_wr, ADDR_WIDTH'(0));
        @(posedge clk); // pivot 2-6
        `assert(plm_0_addr, ADDR_WIDTH'(0));
        `assert(plm_0_val, ADDR_WIDTH'(0));
        `assert(plm_0_wr, ADDR_WIDTH'(0));
        `assert(plm_1_addr, ADDR_WIDTH'(0));
        `assert(plm_1_val, ADDR_WIDTH'(0));
        `assert(plm_1_wr, ADDR_WIDTH'(0));
        @(posedge clk); // pivot 3-7
        `assert(plm_0_addr, ADDR_WIDTH'(0));
        `assert(plm_0_val, ADDR_WIDTH'(0));
        `assert(plm_0_wr, ADDR_WIDTH'(0));
        `assert(plm_1_addr, ADDR_WIDTH'(0));
        `assert(plm_1_val, ADDR_WIDTH'(0));
        `assert(plm_1_wr, ADDR_WIDTH'(0));
        @(posedge clk); // pivot 4-0 +
        `assert(plm_0_addr, ADDR_WIDTH'(0));
        `assert(plm_0_val, ADDR_WIDTH'(0));
        `assert(plm_0_wr, ADDR_WIDTH'(0));
        `assert(plm_1_addr, ADDR_WIDTH'(2));
        `assert(plm_1_val, ADDR_WIDTH'(25));
        `assert(plm_1_wr, ADDR_WIDTH'(1));
        @(posedge clk); // pivot 5-1 
        `assert(plm_0_addr, ADDR_WIDTH'(0));
        `assert(plm_0_val, ADDR_WIDTH'(0));
        `assert(plm_0_wr, ADDR_WIDTH'(0));
        `assert(plm_1_addr, ADDR_WIDTH'(0));
        `assert(plm_1_val, ADDR_WIDTH'(0));
        `assert(plm_1_wr, ADDR_WIDTH'(0));
        @(posedge clk); // pivot 6-2 
        `assert(plm_0_addr, ADDR_WIDTH'(0));
        `assert(plm_0_val, ADDR_WIDTH'(0));
        `assert(plm_0_wr, ADDR_WIDTH'(0));
        `assert(plm_1_addr, ADDR_WIDTH'(0));
        `assert(plm_1_val, ADDR_WIDTH'(0));
        `assert(plm_1_wr, ADDR_WIDTH'(0));
        @(posedge clk); // pivot 7-3 
        `assert(plm_0_addr, ADDR_WIDTH'(0));
        `assert(plm_0_val, ADDR_WIDTH'(0));
        `assert(plm_0_wr, ADDR_WIDTH'(0));
        `assert(plm_1_addr, ADDR_WIDTH'(0));
        `assert(plm_1_val, ADDR_WIDTH'(0));
        `assert(plm_1_wr, ADDR_WIDTH'(0));
        @(posedge clk); // pivot 0-4 
        `assert(plm_0_addr, ADDR_WIDTH'(2));
        `assert(plm_0_val, ADDR_WIDTH'(25));
        `assert(plm_0_wr, ADDR_WIDTH'(1));
        `assert(plm_1_addr, ADDR_WIDTH'(0));
        `assert(plm_1_val, ADDR_WIDTH'(0));
        `assert(plm_1_wr, ADDR_WIDTH'(0));
        $write("PASS\n");
        repeat(20) @(posedge clk);

        $write("TEST: two valid requests for bank0 are routed to respective ports .... ");
        @(posedge clk); // reset
        rst = 1'b1;
        @(posedge clk);
        rst = 1'b0;
        requests[0] = {ADDR_WIDTH'(3), VALUE_WIDTH'(25), 1'b1, 1'b1};
        requests[4] = {ADDR_WIDTH'(5), VALUE_WIDTH'(50), 1'b1, 1'b1};

        @(posedge clk); // pivots 1-5
        `assert(plm_0_addr, ADDR_WIDTH'(0));
        `assert(plm_0_val, ADDR_WIDTH'(0));
        `assert(plm_0_wr, ADDR_WIDTH'(0));
        `assert(plm_1_addr, ADDR_WIDTH'(0));
        `assert(plm_1_val, ADDR_WIDTH'(0));
        `assert(plm_1_wr, ADDR_WIDTH'(0));
        @(posedge clk); // pivot 2-6
        `assert(plm_0_addr, ADDR_WIDTH'(0));
        `assert(plm_0_val, ADDR_WIDTH'(0));
        `assert(plm_0_wr, ADDR_WIDTH'(0));
        `assert(plm_1_addr, ADDR_WIDTH'(0));
        `assert(plm_1_val, ADDR_WIDTH'(0));
        `assert(plm_1_wr, ADDR_WIDTH'(0));
        @(posedge clk); // pivot 3-7
        `assert(plm_0_addr, ADDR_WIDTH'(0));
        `assert(plm_0_val, ADDR_WIDTH'(0));
        `assert(plm_0_wr, ADDR_WIDTH'(0));
        `assert(plm_1_addr, ADDR_WIDTH'(0));
        `assert(plm_1_val, ADDR_WIDTH'(0));
        `assert(plm_1_wr, ADDR_WIDTH'(0));
        @(posedge clk); // pivot 4-0 +
        `assert(plm_0_addr, ADDR_WIDTH'(5));
        `assert(plm_0_val, ADDR_WIDTH'(50));
        `assert(plm_0_wr, ADDR_WIDTH'(1));
        `assert(plm_1_addr, ADDR_WIDTH'(3));
        `assert(plm_1_val, ADDR_WIDTH'(25));
        `assert(plm_1_wr, ADDR_WIDTH'(1));
        @(posedge clk); // pivot 5-1 
        `assert(plm_0_addr, ADDR_WIDTH'(0));
        `assert(plm_0_val, ADDR_WIDTH'(0));
        `assert(plm_0_wr, ADDR_WIDTH'(0));
        `assert(plm_1_addr, ADDR_WIDTH'(0));
        `assert(plm_1_val, ADDR_WIDTH'(0));
        `assert(plm_1_wr, ADDR_WIDTH'(0));
        @(posedge clk); // pivot 6-2 
        `assert(plm_0_addr, ADDR_WIDTH'(0));
        `assert(plm_0_val, ADDR_WIDTH'(0));
        `assert(plm_0_wr, ADDR_WIDTH'(0));
        `assert(plm_1_addr, ADDR_WIDTH'(0));
        `assert(plm_1_val, ADDR_WIDTH'(0));
        `assert(plm_1_wr, ADDR_WIDTH'(0));
        @(posedge clk); // pivot 7-3 
        `assert(plm_0_addr, ADDR_WIDTH'(0));
        `assert(plm_0_val, ADDR_WIDTH'(0));
        `assert(plm_0_wr, ADDR_WIDTH'(0));
        `assert(plm_1_addr, ADDR_WIDTH'(0));
        `assert(plm_1_val, ADDR_WIDTH'(0));
        `assert(plm_1_wr, ADDR_WIDTH'(0));
        @(posedge clk); // pivot 0-4 
        `assert(plm_0_addr, ADDR_WIDTH'(3));
        `assert(plm_0_val, ADDR_WIDTH'(25));
        `assert(plm_0_wr, ADDR_WIDTH'(1));
        `assert(plm_1_addr, ADDR_WIDTH'(5));
        `assert(plm_1_val, ADDR_WIDTH'(50));
        `assert(plm_1_wr, ADDR_WIDTH'(1));

        $write("PASS\n");
        
        $write("TEST: requests are routed to different banks based on address .... ");
        @(posedge clk); // reset
        rst = 1'b1;
        @(posedge clk);
        rst = 1'b0;
        requests[0] = {ADDR_WIDTH'(255), VALUE_WIDTH'(0), 1'b1, 1'b1};
        requests[1] = {ADDR_WIDTH'(511), VALUE_WIDTH'(1), 1'b1, 1'b1};
        requests[2] = {ADDR_WIDTH'(767), VALUE_WIDTH'(2), 1'b1, 1'b1};
        requests[3] = {ADDR_WIDTH'(1023), VALUE_WIDTH'(3), 1'b1, 1'b1};
        requests[4] = {ADDR_WIDTH'(0), VALUE_WIDTH'(0), 1'b0, 1'b0};
        
        @(posedge clk); // pivot 1-5
        @(posedge clk); // pivot 2-6
        @(posedge clk); // pivot 3-7
        @(posedge clk); // pivot 4-0
        @(posedge clk); // pivot 5-1
        @(posedge clk); // pivot 6-2
        @(posedge clk); // pivot 7-3
        @(posedge clk); // pivot 0-4
        repeat(20) @(posedge clk);
        `assert(plm_0_addr, ADDR_WIDTH'(255));
        `assert(plm_0_val, ADDR_WIDTH'(0));
        `assert(plm_0_wr, ADDR_WIDTH'(1));
        `assert(plm_2_addr, ADDR_WIDTH'(255));
        `assert(plm_2_val, ADDR_WIDTH'(1));
        `assert(plm_2_wr, ADDR_WIDTH'(1));
        `assert(plm_4_addr, ADDR_WIDTH'(255));
        `assert(plm_4_val, ADDR_WIDTH'(2));
        `assert(plm_4_wr, ADDR_WIDTH'(1));
        `assert(plm_6_addr, ADDR_WIDTH'(255));
        `assert(plm_6_val, ADDR_WIDTH'(3));
        `assert(plm_6_wr, ADDR_WIDTH'(1));
        @(posedge clk); // pivot 1-5

        $write("PASS\n");

        repeat(20) @(posedge clk);
        repeat(1) @(posedge clk);

        $write("\n");

        repeat(2) @(posedge clk);
        $finish(2);
    end

endmodule
`default_nettype wire