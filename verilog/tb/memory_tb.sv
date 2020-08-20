

`default_nettype none

module memory_tb;
reg clk;
reg rst_n;

localparam ADDR = 4;
localparam DATA = 8;

wire a_wr;
wire [ADDR-1:0] a_addr;
wire [DATA-1:0] a_din;
wire [DATA-1:0] a_dout;

wire b_wr;
wire [ADDR-1:0] b_addr;
wire [DATA-1:0] b_din;
wire [DATA-1:0] b_dout;

memory #(.ADDR(ADDR), .DATA(DATA)) dut
(
    .rst_n (rst_n),
    .clk (clk),
    .a_wr(a_wr),
    .a_addr(a_addr),
    .a_din(a_din),
    .a_dout(a_dout),
    .b_wr(b_wr),
    .b_addr(b_addr),
    .b_din(b_din),
    .b_dout(b_dout)
);

localparam CLK_PERIOD = 10;
always #(CLK_PERIOD/2) clk=~clk;

initial begin
    $dumpfile("memory_tb.vcd");
    $dumpvars(0, tb_memory);
end

initial begin
    #1 rst_n<=1'bx;clk<=1'bx;
    #(CLK_PERIOD*3) rst_n<=1;
    #(CLK_PERIOD*3) rst_n<=0;clk<=0;
    repeat(5) @(posedge clk);
    rst_n<=1;
    @(posedge clk);
    repeat(2) @(posedge clk);
    $finish(2);
end

endmodule
`default_nettype wire