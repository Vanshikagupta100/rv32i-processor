`include "rv32i_defines.vh"
module aludec_tb;
    reg  [1:0] alu_op;
    reg  [2:0] funct3;
    reg        funct7_5, opcode_5;
    wire [3:0] alu_ctrl;

    alu_decoder dut (.alu_op(alu_op), .funct3(funct3), .funct7_5(funct7_5),
                     .opcode_5(opcode_5), .alu_ctrl(alu_ctrl));

    task t;
        input [1:0] op; input [2:0] f3; input f7, o5; input [3:0] exp; input [63:0] name;
        begin
            alu_op = op; funct3 = f3; funct7_5 = f7; opcode_5 = o5; #1;
            $display("%s: got %b exp %b %s", name, alu_ctrl, exp, (alu_ctrl === exp) ? "PASS" : "FAIL");
        end
    endtask

    initial begin
        t(`ALUOP_FUNCT, 3'b000, 0, 1, `ALU_ADD,    "add     ");
        t(`ALUOP_FUNCT, 3'b000, 1, 1, `ALU_SUB,    "sub     ");
        t(`ALUOP_FUNCT, 3'b000, 1, 0, `ALU_ADD,    "addi neg");   // the bug case
        t(`ALUOP_FUNCT, 3'b101, 0, 0, `ALU_SRL,    "srli    ");
        t(`ALUOP_FUNCT, 3'b101, 1, 0, `ALU_SRA,    "srai    ");
        t(`ALUOP_ADD,   3'b111, 1, 1, `ALU_ADD,    "load/st ");
        t(`ALUOP_PASSB, 3'b000, 0, 0, `ALU_PASS_B, "lui     ");
        $finish;
    end
endmodule