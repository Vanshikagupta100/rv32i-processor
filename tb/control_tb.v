`include "rv32i_defines.vh"
module control_tb;
    reg  [6:0] opcode;
    wire       reg_write, alu_src_a, alu_src_b, mem_write, mem_read, branch, jump, jalr;
    wire [2:0] imm_src;
    wire [1:0] result_src, alu_op;

    control_unit dut (.opcode(opcode), .reg_write(reg_write), .imm_src(imm_src),
        .alu_src_a(alu_src_a), .alu_src_b(alu_src_b), .mem_write(mem_write),
        .mem_read(mem_read), .result_src(result_src), .branch(branch),
        .jump(jump), .jalr(jalr), .alu_op(alu_op));

    task show;
        input [6:0] op;
        begin
            opcode = op; #1;
            $display("op=%b rw=%b imm=%b a=%b b=%b mw=%b mr=%b res=%b br=%b j=%b jr=%b aluop=%b",
                op, reg_write, imm_src, alu_src_a, alu_src_b, mem_write, mem_read,
                result_src, branch, jump, jalr, alu_op);
        end
    endtask

    initial begin
        show(`OP_AUIPC);   // only row with a=1
        show(`OP_STORE);   // rw=0, mw=1, imm=S
        show(`OP_JALR);    // res=PC4, j=1, jr=1
        show(7'b1111111);  // unknown opcode: must look like a NOP
        $finish;
    end
endmodule