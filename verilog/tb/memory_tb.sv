
`include "modules/memory.sv"
`include "utils/utils.sv"

`default_nettype none

module memory_tb;
reg clk;
reg rst_n;

localparam ADDR = 4;
localparam DATA = 8;

reg t_a_wr;
reg [ADDR-1:0] t_a_addr;
reg [DATA-1:0] t_a_din;
wire [DATA-1:0] t_a_dout;

reg t_b_wr;
reg [ADDR-1:0] t_b_addr;
reg [DATA-1:0] t_b_din;
wire [DATA-1:0] t_b_dout;

memory #(.ADDR(ADDR), .DATA(DATA)) dut
(
    .rst_n (rst_n),
    .clk (clk),
    .a_wr(t_a_wr),
    .a_addr(t_a_addr),
    .a_din(t_a_din),
    .a_dout(t_a_dout),
    .b_wr(t_b_wr),
    .b_addr(t_b_addr),
    .b_din(t_b_din),
    .b_dout(t_b_dout)
);

localparam CLK_PERIOD = 10;
always #(CLK_PERIOD/2) clk=~clk;

// initial begin
//     $dumpfile("memory_tb.vcd");
//     $dumpvars(0, memory_tb);
// end


initial begin
    #1 rst_n<=1'bx;clk<=1'bx;
    #(CLK_PERIOD*3) rst_n<=1;
    #(CLK_PERIOD*3) rst_n<=0;clk<=0;
    repeat(5) @(posedge clk);
    rst_n<=1;
    
    $write("================== TEST memory_tb ==================\n");
    $write("TEST: basic write/read .... ");
    @(posedge clk); 

    t_a_wr <= 1; t_a_addr <= 3; t_a_din <= 234;
    @(posedge clk); 

    t_a_wr <= 1; t_a_addr <= 4; t_a_din <= 222;
    @(posedge clk); 

    t_a_wr <= 0; t_a_addr <= 3;

    @(posedge clk);
    @(posedge clk); 
    
    `assert(t_a_dout, 234)
    $write("PASS\n");

    $write("TEST: dual-port legal write/read .... ");
    @(posedge clk);
    t_a_wr <= 1; t_a_addr <= 3; t_a_din <= 234;
    t_b_wr <= 1; t_b_addr <= 15; t_b_din <= 255;
    @(posedge clk);
    t_a_wr <= 0; t_a_addr <= 15;
    t_b_wr <= 0; t_b_addr <= 3;

    @(posedge clk);
    @(posedge clk);
    `assert(t_a_dout, 255)
    `assert(t_b_dout, 234)
    $write("PASS\n");
    
    $write("TEST: dual-port conflicting read .... ");
    @(posedge clk);
    t_a_wr <= 1; t_a_addr <= 0; t_a_din <= 1;

    @(posedge clk);
    t_a_wr <= 0; t_a_addr <= 0;
    t_b_wr <= 0; t_b_addr <= 0;

    @(posedge clk);
    @(posedge clk);
    `assert(t_a_dout, 1)
    `assert(t_b_dout, 1)
    $write("PASS\n");
    
    $write("\n");
    repeat(2) @(posedge clk);
    $finish(2);
end

endmodule
`default_nettype wire