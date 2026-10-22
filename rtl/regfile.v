// regfile.v — 32x32 register file; x0 is hardwired to zero
module regfile (
    input  wire        clk,
    input  wire        rst,
    input  wire        reg_write,
    input  wire [4:0]  rs1_addr,
    input  wire [4:0]  rs2_addr,
    input  wire [4:0]  rd_addr,
    input  wire [31:0] rd_data,
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data
);

    reg [31:0] regs [0:31];

    assign rs1_data = (rs1_addr == 5'd0) ? 32'd0 : regs[rs1_addr];
    assign rs2_data = (rs2_addr == 5'd0) ? 32'd0 : regs[rs2_addr];

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'h00000000;
        end
        else if (reg_write && rd_addr != 5'd0)
            regs[rd_addr] <= rd_data;
    end

endmodule
