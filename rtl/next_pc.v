// next_pc.v — decides what the next PC should be: PC+4, branch target, JAL target, or JALR target
module next_pc (
    input  wire [31:0] pc,
    input  wire [31:0] imm,
    input  wire [31:0] rs1_data,
    input  wire        jalr,
    input  wire        jump,
    input  wire        branch_taken,
    output wire [31:0] pc_plus4,
    output wire [31:0] pc_next
);
    wire [31:0] pc_target;     // pc + imm  (JAL and taken branches)
    wire [31:0] jalr_sum;      // rs1 + imm (JALR)
    wire [31:0] jalr_target;
    wire [31:0] pc_seq_or_tgt;

    adder u_add_plus4 (.a(pc),       .b(32'd4), .sum(pc_plus4));
    adder u_add_pctgt (.a(pc),       .b(imm),   .sum(pc_target));
    adder u_add_jalr  (.a(rs1_data), .b(imm),   .sum(jalr_sum));

    assign jalr_target = {jalr_sum[31:1], 1'b0};   // JALR clears bit 0

    // JAL or a taken branch both go to pc + imm; otherwise pc + 4
    mux2 u_mux_tgt  (.in0(pc_plus4),      .in1(pc_target),   .sel(jump | branch_taken), .out(pc_seq_or_tgt));
    // JALR overrides everything
    mux2 u_mux_jalr (.in0(pc_seq_or_tgt), .in1(jalr_target), .sel(jalr),                .out(pc_next));
endmodule
