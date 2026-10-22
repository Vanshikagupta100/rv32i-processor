// alu_decoder.v — picks the right ALU operation based on alu_op, funct3, and funct7
`include "rv32i_defines.vh"

module alu_decoder (
    input  wire [1:0] alu_op,
    input  wire [2:0] funct3,
    input  wire       funct7_5,
    input  wire       opcode_5,
    output reg  [3:0] alu_ctrl
);
    always @(*) begin
        alu_ctrl = `ALU_ADD;   // safe default

        case (alu_op)
            `ALUOP_ADD:   alu_ctrl = `ALU_ADD;
            `ALUOP_PASSB: alu_ctrl = `ALU_PASS_B;
            `ALUOP_FUNCT: begin
                case (funct3)
                    3'b000: alu_ctrl = (opcode_5 && funct7_5) ? `ALU_SUB : `ALU_ADD;
                    3'b001: alu_ctrl = `ALU_SLL;
                    3'b010: alu_ctrl = `ALU_SLT;
                    3'b011: alu_ctrl = `ALU_SLTU;
                    3'b100: alu_ctrl = `ALU_XOR;
                    3'b101: alu_ctrl = funct7_5 ? `ALU_SRA : `ALU_SRL;
                    3'b110: alu_ctrl = `ALU_OR;
                    3'b111: alu_ctrl = `ALU_AND;
                endcase
            end
        endcase
    end
endmodule
