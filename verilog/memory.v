module memory #(
    parameter DATA = 72,
    parameter ADDR = 10
) (
    input   wire                clk,
    
    // Port A
    input   wire                a_wr,
    input   wire    [ADDR-1:0]  a_addr,
    input   wire    [DATA-1:0]  a_din,
    output  reg     [DATA-1:0]  a_dout,
     
    input   wire                b_wr,
    input   wire    [ADDR-1:0]  b_addr,
    input   wire    [DATA-1:0]  b_din,
    output  reg     [DATA-1:0]  b_dout
);
 
    // Shared memory
    reg [DATA-1:0] mem [(2**ADDR)-1:0];
    
    always @(posedge clk) begin
        a_dout      <= mem[a_addr];
        b_dout      <= mem[b_addr];
        if(a_wr) begin
            a_dout      <= a_din;
            mem[a_addr] <= a_din;
        end
        if(b_wr) begin
            b_dout      <= b_din;
            mem[b_addr] <= b_din;
        end
    end
endmodule