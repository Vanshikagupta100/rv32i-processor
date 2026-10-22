`include "rv32i_defines.vh"
module imm_gen_tb;
    reg  [31:0] instr;
    reg  [2:0]  imm_src;
    wire [31:0] imm;

    imm_gen dut (.instr(instr), .imm_src(imm_src), .imm(imm));

    initial begin
        instr = 32'hFE008CE3; imm_src = `IMM_B; #1; $display("B: %h (expect fffffff8)", imm);
        instr = 32'h00512423; imm_src = `IMM_S; #1; $display("S: %h (expect 00000008)", imm);
        instr = 32'h010000EF; imm_src = `IMM_J; #1; $display("J: %h (expect 00000010)", imm);
        instr = 32'h00812283; imm_src = `IMM_I; #1; $display("I: %h (expect 00000008)", imm);
        instr = 32'h123452B7; imm_src = `IMM_U; #1; $display("U: %h (expect 12345000)", imm);
        $finish;
    end
endmodule