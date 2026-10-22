// control_unit.v — main decoder: maps opcode to all the control signals
`include "rv32i_defines.vh"

module control_unit (
    input  wire [6:0] opcode,
    output reg        reg_write,
    output reg [2:0]  imm_src,
    output reg        alu_src_a,
    output reg        alu_src_b,
    output reg        mem_write,
    output reg        mem_read,
    output reg [1:0]  result_src,
    output reg        branch,
    output reg        jump,
    output reg        jalr,
    output reg [1:0]  alu_op
);
    always @(*) begin
        // safe defaults — unrecognised opcodes behave as NOPs
        reg_write  = 1'b0;
        imm_src    = `IMM_I;
        alu_src_a  = 1'b0;
        alu_src_b  = 1'b0;
        mem_write  = 1'b0;
        mem_read   = 1'b0;
        result_src = `RES_ALU;
        branch     = 1'b0;
        jump       = 1'b0;
        jalr       = 1'b0;
        alu_op     = `ALUOP_ADD;

        case (opcode)
            `OP_R: begin
                reg_write = 1'b1;
                alu_op    = `ALUOP_FUNCT;
            end
            `OP_I: begin
                reg_write = 1'b1;
                alu_src_b = 1'b1;
                alu_op    = `ALUOP_FUNCT;
            end
            `OP_LOAD: begin
                reg_write  = 1'b1;
                alu_src_b  = 1'b1;
                mem_read   = 1'b1;
                result_src = `RES_MEM;
            end
            `OP_STORE: begin
                imm_src   = `IMM_S;
                alu_src_b = 1'b1;
                mem_write = 1'b1;
            end
            `OP_BRANCH: begin
                imm_src = `IMM_B;
                branch  = 1'b1;
            end
            `OP_JAL: begin
                reg_write  = 1'b1;
                imm_src    = `IMM_J;
                result_src = `RES_PC4;
                jump       = 1'b1;
            end
            `OP_JALR: begin
                reg_write  = 1'b1;
                alu_src_b  = 1'b1;
                result_src = `RES_PC4;
                jump       = 1'b1;
                jalr       = 1'b1;
            end
            `OP_LUI: begin
                reg_write = 1'b1;
                imm_src   = `IMM_U;
                alu_src_b = 1'b1;
                alu_op    = `ALUOP_PASSB;
            end
            `OP_AUIPC: begin
                reg_write = 1'b1;
                imm_src   = `IMM_U;
                alu_src_a = 1'b1;
                alu_src_b = 1'b1;
            end
            // FENCE, ECALL/EBREAK and anything else: defaults already act as NOP
        endcase
    end
endmodule
