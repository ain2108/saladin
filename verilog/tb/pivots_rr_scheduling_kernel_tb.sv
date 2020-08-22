
`include "utils/utils.sv"
`include "modules/rr_scheduling_kernel.sv"

`default_nettype none

module pivots_rr_scheduling_kernel_tb;
    
    parameter NCONSUMERS = 8;
    parameter NBANKS = 4;
    parameter NPORTS = 2;
    localparam NKERNELS = NBANKS * NPORTS;

    reg clk;
    reg rst;

    localparam CLK_PERIOD = 10;
    always #(CLK_PERIOD/2) clk=~clk;

    rr_scheduling_kernel #(
        .NCONSUMERS(NCONSUMERS),
        .NBANKS(NBANKS),
        .NPORTS(NPORTS)
    ) rsk (
        .clk(clk),
        .reset(rst));

    initial begin
        #1 rst<=1'bx;clk<=1'bx;
        #(CLK_PERIOD*3) rst<=1;
        #(CLK_PERIOD*3) rst<=0;clk<=0;
        repeat(5) @(posedge clk);


        $write("================== TEST pivots ==================\n");
        $write("TEST: reset initializes pivots correctly .... ");

        @(posedge clk);
        rst <= 1;
        @(posedge clk);
        @(posedge clk);
        `assert(rsk.rr_pivots[0], 0);
        `assert(rsk.rr_pivots[1], 4);
        `assert(rsk.rr_pivots[2], 1);
        `assert(rsk.rr_pivots[3], 5);
        `assert(rsk.rr_pivots[4], 2);
        `assert(rsk.rr_pivots[5], 6);
        `assert(rsk.rr_pivots[6], 3);
        `assert(rsk.rr_pivots[7], 7);
        $write("PASS\n");
        
        $write("TEST: pivots get incremented correctly .... ");
        @(posedge clk);
        rst <= 0;
        @(posedge clk);
        @(posedge clk);
        `assert(rsk.rr_pivots[0], 1);
        `assert(rsk.rr_pivots[1], 5);
        `assert(rsk.rr_pivots[2], 2);
        `assert(rsk.rr_pivots[3], 6);
        `assert(rsk.rr_pivots[4], 3);
        `assert(rsk.rr_pivots[5], 7);
        `assert(rsk.rr_pivots[6], 4);
        `assert(rsk.rr_pivots[7], 0);
        
        @(posedge clk);
        `assert(rsk.rr_pivots[0], 2);
        `assert(rsk.rr_pivots[1], 6);
        `assert(rsk.rr_pivots[2], 3);
        `assert(rsk.rr_pivots[3], 7);
        `assert(rsk.rr_pivots[4], 4);
        `assert(rsk.rr_pivots[5], 0);
        `assert(rsk.rr_pivots[6], 5);
        `assert(rsk.rr_pivots[7], 1);

        $write("PASS\n");

        repeat(5) @(posedge clk);


        $write("\n");

        repeat(2) @(posedge clk);
        $finish(2);
    end

endmodule
`default_nettype wire