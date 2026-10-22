// imem.v — read-only instruction memory, loaded from a hex file at start
module imem #(
    parameter DEPTH     = 256,
    parameter INIT_FILE = "program.hex"
) (
    input  wire [31:0] addr,
    output wire [31:0] instr
);
    reg [31:0] mem [0:DEPTH-1];

    initial begin
        $readmemh(INIT_FILE, mem);
    end

    assign instr = mem[addr[31:2]];
endmodule
