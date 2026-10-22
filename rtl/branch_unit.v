// branch_unit.v — evaluates branch conditions (BEQ, BNE, BLT, BGE, BLTU, BGEU)
module branch_unit (
    input  wire [31:0] rs1_data,
    input  wire [31:0] rs2_data,
    input  wire [2:0]  funct3,
    input  wire        branch,
    output wire        branch_taken
);
    wire eq  = (rs1_data == rs2_data);
    wire lt  = ($signed(rs1_data) < $signed(rs2_data));
    wire ltu = (rs1_data < rs2_data);

    reg cond;
    always @(*) begin
        case (funct3)
            3'b000:  cond = eq;     // BEQ
            3'b001:  cond = ~eq;    // BNE
            3'b100:  cond = lt;     // BLT
            3'b101:  cond = ~lt;    // BGE
            3'b110:  cond = ltu;    // BLTU
            3'b111:  cond = ~ltu;   // BGEU
            default: cond = 1'b0;   // 010 and 011 don't exist for branches
        endcase
    end

    assign branch_taken = branch & cond;   // low whenever branch is low
endmodule
