

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

    parameter ADDR_WIDTH = 16;
    parameter VALUE_WIDTH = 8;
    parameter NCONSUMERS = 8;
    parameter NBANKS = 4;
    parameter NPORTS = 2;

    localparam REQ_WIDTH = ADDR_WIDTH + VALUE_WIDTH + 1 + 1;
    localparam PLM_INPUT_WIDTH = (ADDR_WIDTH - $clog2(NBANKS)) + VALUE_WIDTH + 1;
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

    wire [ADDR_WIDTH-1:0] plm_0_addr;
    wire [VALUE_WIDTH-1:0] plm_0_val;
    wire plm_0_wr;
    wire [PLM_INPUT_WIDTH-1:0] plm_0;

    assign plm_0 = plm_inputs[0];
    assign plm_0_addr = plm_0[PLM_INPUT_WIDTH-1: PLM_INPUT_WIDTH - ADDR_WIDTH];

    initial begin

        for(i = 0; i < NCONSUMERS; i++) begin
            requests[i] = REQ_WIDTH'(0);
        end

        @(negedge rst); // wait for reset

        $write("================== TEST request selection ==================\n");
        $write("TEST: reset initializes pivots correctly .... ");

        requests[0] = {ADDR_WIDTH'(2), VALUE_WIDTH'(25), 1'b1, 1'b1}; /* Write 13 to addr 2 */
        @(posedge clk);
        `assert(plm_0_addr, ADDR_WIDTH'(2));
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        

        @(posedge clk);


        $write("PASS\n");

        repeat(200) @(posedge clk);
        repeat(1) @(posedge clk);

        $write("\n");

        repeat(2) @(posedge clk);
        $finish(2);
    end

endmodule
`default_nettype wire