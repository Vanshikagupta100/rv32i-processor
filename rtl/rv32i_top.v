// rv32i_top.v — top-level wrapper: ties the core to instruction and data memories
module rv32i_top #(
    parameter INIT_FILE = "program.hex"
) (
    input wire clk,
    input wire rst
);
    wire [31:0] imem_addr, imem_rdata;
    wire [31:0] dmem_addr, dmem_wdata, dmem_rdata;
    wire [3:0]  dmem_wstrb;
    wire        dmem_write;

    rv32i_core u_core (
        .clk(clk), .rst(rst),
        .imem_addr(imem_addr),   .imem_rdata(imem_rdata),
        .dmem_addr(dmem_addr),   .dmem_wdata(dmem_wdata),
        .dmem_wstrb(dmem_wstrb), .dmem_write(dmem_write),
        .dmem_rdata(dmem_rdata)
    );

    imem #(.DEPTH(1024), .INIT_FILE(INIT_FILE)) u_imem (
        .addr(imem_addr), .instr(imem_rdata)
    );

    dmem #(.DEPTH(1024)) u_dmem (
        .clk(clk), .mem_write(dmem_write), .wstrb(dmem_wstrb),
        .addr(dmem_addr), .wdata(dmem_wdata), .rdata(dmem_rdata)
    );
endmodule
