// adder.v — simple 32-bit adder, used for PC+4, PC+imm, and rs1+imm
module adder (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [31:0] sum
);
    assign sum = a + b ;
endmodule
