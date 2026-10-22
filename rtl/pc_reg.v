// pc_reg.v — program counter register with synchronous reset
module pc_reg #(
    parameter RESET_VECTOR = 32'h0000_0000
) (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] pc_next,
    output reg  [31:0] pc
);
    always @(posedge clk) begin
        if (rst) pc <= RESET_VECTOR ;
        else     pc <= pc_next ;
    end
endmodule
