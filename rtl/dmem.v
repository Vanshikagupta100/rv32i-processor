// dmem.v — byte-addressable data memory with per-byte write strobes
module dmem #(
    parameter DEPTH = 256
) (
    input  wire        clk,
    input  wire        mem_write,
    input  wire [3:0]  wstrb,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    output wire [31:0] rdata
);
    reg [31:0] mem [0:DEPTH-1];
    integer i;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 32'b0;
    end

    assign rdata = mem[addr[31:2]];

    always @(posedge clk) begin
        if (mem_write) begin
            if (wstrb[0]) mem[addr[31:2]][7:0]   <= wdata[7:0];
            if (wstrb[1]) mem[addr[31:2]][15:8]  <= wdata[15:8];
            if (wstrb[2]) mem[addr[31:2]][23:16] <= wdata[23:16];
            if (wstrb[3]) mem[addr[31:2]][31:24] <= wdata[31:24];
        end
    end
endmodule
