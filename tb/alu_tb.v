`include "rv32i_defines.vh"
`timescale 1ns/1ps

module alu_tb;

    reg  [31:0] a;
    reg  [31:0] b;
    reg  [3:0]  alu_ctrl;
    wire [31:0] result;

    alu dut (
        .a(a),
        .b(b),
        .alu_ctrl(alu_ctrl),
        .result(result)
    );

task check;
    input [3:0]  ctrl;
    input [31:0] in_a;
    input [31:0] in_b;
    input [31:0] expected;
    begin
        alu_ctrl = ctrl;
        a = in_a;
        b = in_b;
        #10;
        if (result === expected)
            $display("PASS: ctrl=%b a=%h b=%h result=%h", ctrl, a, b, result);
        else
            $display("FAIL: ctrl=%b a=%h b=%h result=%h expected=%h", ctrl, a, b, result, expected);
    end
endtask


    initial begin
        $dumpfile("alu_tb.vcd");
        $dumpvars(0, alu_tb);

        check(`ALU_ADD, 32'd10, 32'd4, 32'd14);
        check(`ALU_SUB, 32'd10, 32'd4, 32'd6);
	check(`ALU_AND, 32'b1100, 32'b1010, 32'b1000);
	check(`ALU_OR,  32'b1100, 32'b1010, 32'b1110);
	check(`ALU_XOR,  32'b1100, 32'b1010, 32'b0110);
	check(`ALU_PASS_B,  32'b1100, 32'b1010, 32'b1010);
	check(`ALU_SLL,  32'b0110, 32'd2, 32'b11000);
	check(`ALU_SRL,  32'b1100, 32'd2, 32'b0011);

	check(`ALU_ADD,  32'h7FFF_FFFF, 32'd1, 32'h8000_0000);
	check(`ALU_SUB,  32'h0000_0000, 32'd1, 32'hFFFFFFFF);
	check(`ALU_SRL,  32'h8000_0000, 32'd1, 32'h4000_0000);
	check(`ALU_SRA,  32'h8000_0000, 32'd1, 32'hc000_0000);

	check(`ALU_SLT,  32'hFFFF_FFFF, 32'h0000_0001, 32'h0000_0001);
	check(`ALU_SLTU, 32'hFFFF_FFFF, 32'h0000_0001, 32'h0000_0000);
	check(`ALU_SLL, 32'h0000_0001, 32'd33, 32'h0000_0002);
	check(4'b1111, 32'h1234_5678, 32'h0000_0001, 32'h0000_0000);

	check(`ALU_ADD,  32'hFFFF_FFFF, 32'h8000_0000, 32'h7FFF_FFFF);
	check(`ALU_XOR,  32'hFFFF_FFFF, 32'hFFFF_FFFF, 32'h0000_0000);
	check(`ALU_SRA,  32'h7FFF_FFFF, 32'd1, 32'h3FFF_FFFF);
        $finish;
    end


endmodule