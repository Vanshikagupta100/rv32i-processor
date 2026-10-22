// rv32i_core.v — single-cycle RV32I datapath: fetch, decode, execute, memory, writeback
`include "rv32i_defines.vh"

module rv32i_core #(
    parameter RESET_VECTOR = 32'h0000_0000
) (
    input  wire        clk,
    input  wire        rst,
    // instruction memory interface (memory sits outside the core)
    output wire [31:0] imem_addr,
    input  wire [31:0] imem_rdata,
    // data memory interface
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    output wire [3:0]  dmem_wstrb,
    output wire        dmem_write,
    input  wire [31:0] dmem_rdata
);
    // ---------- instruction fetch ----------
    wire [31:0] pc, pc_next, pc_plus4;
    wire [31:0] instr = imem_rdata;

    pc_reg #(.RESET_VECTOR(RESET_VECTOR)) u_pc (
        .clk(clk), .rst(rst), .pc_next(pc_next), .pc(pc)
    );
    assign imem_addr = pc;

    // ---------- field extraction ----------
    wire [6:0] opcode   = instr[6:0];
    wire [4:0] rd       = instr[11:7];
    wire [2:0] funct3   = instr[14:12];
    wire [4:0] rs1      = instr[19:15];
    wire [4:0] rs2      = instr[24:20];
    wire [6:0] funct7   = instr[31:25];

    // ---------- control ----------
    wire        reg_write, alu_src_a, alu_src_b, mem_write, mem_read;
    wire        branch, jump, jalr;
    wire [2:0]  imm_src;
    wire [1:0]  result_src, alu_op;
    wire [3:0]  alu_ctrl;

    control_unit u_ctrl (
        .opcode(opcode), .reg_write(reg_write), .imm_src(imm_src),
        .alu_src_a(alu_src_a), .alu_src_b(alu_src_b),
        .mem_write(mem_write), .mem_read(mem_read), .result_src(result_src),
        .branch(branch), .jump(jump), .jalr(jalr), .alu_op(alu_op)
    );

    alu_decoder u_aludec (
        .alu_op(alu_op), .funct3(funct3), .funct7_5(funct7[5]),
        .opcode_5(opcode[5]), .alu_ctrl(alu_ctrl)
    );

    // ---------- register file, immediate, ALU ----------
    wire [31:0] imm, rs1_data, rs2_data, alu_a, alu_b, alu_result, wb_data;

    imm_gen u_imm (.instr(instr), .imm_src(imm_src), .imm(imm));

    regfile u_regfile (
        .clk(clk), .rst(rst), .reg_write(reg_write),
        .rs1_addr(rs1), .rs2_addr(rs2), .rd_addr(rd), .rd_data(wb_data),
        .rs1_data(rs1_data), .rs2_data(rs2_data)
    );

    mux2 u_mux_a (.in0(rs1_data), .in1(pc),  .sel(alu_src_a), .out(alu_a));
    mux2 u_mux_b (.in0(rs2_data), .in1(imm), .sel(alu_src_b), .out(alu_b));

    alu u_alu (.a(alu_a), .b(alu_b), .alu_ctrl(alu_ctrl), .result(alu_result));

    // ---------- branches and next PC ----------
    wire branch_taken;

    branch_unit u_branch (
        .rs1_data(rs1_data), .rs2_data(rs2_data), .funct3(funct3),
        .branch(branch), .branch_taken(branch_taken)
    );

    next_pc u_next_pc (
        .pc(pc), .imm(imm), .rs1_data(rs1_data),
        .jalr(jalr), .jump(jump), .branch_taken(branch_taken),
        .pc_plus4(pc_plus4), .pc_next(pc_next)
    );

    // ---------- load/store unit ----------
    wire [31:0] load_data;

    lsu u_lsu (
        .mem_write(mem_write), .funct3(funct3), .addr_lsb(alu_result[1:0]),
        .store_data(rs2_data), .mem_rdata(dmem_rdata),
        .mem_wdata(dmem_wdata), .wstrb(dmem_wstrb), .load_data(load_data)
    );

    assign dmem_addr  = alu_result;
    assign dmem_write = mem_write;

    // ---------- writeback ----------
    mux4 u_mux_wb (
        .in0(alu_result),   // RES_ALU
        .in1(load_data),    // RES_MEM
        .in2(pc_plus4),     // RES_PC4
        .in3(32'd0),        // unused
        .sel(result_src), .out(wb_data)
    );
endmodule
