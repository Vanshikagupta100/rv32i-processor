// lsu.v — load/store unit: handles byte/half/word alignment for SB/SH/SW and LB/LBU/LH/LHU/LW
module lsu (
    input  wire        mem_write,
    input  wire [2:0]  funct3,
    input  wire [1:0]  addr_lsb,
    input  wire [31:0] store_data,    // rs2_data
    input  wire [31:0] mem_rdata,     // full aligned word from dmem
    output reg  [31:0] mem_wdata,
    output reg  [3:0]  wstrb,
    output reg  [31:0] load_data
);
    // ---------------- store side ----------------
    always @(*) begin
        mem_wdata = 32'd0;
        wstrb     = 4'b0000;           // stays 0000 whenever mem_write is low
        if (mem_write) begin
            case (funct3)
                3'b000: begin          // SB
                    mem_wdata = {24'b0, store_data[7:0]} << {addr_lsb, 3'b000};
                    wstrb     = 4'b0001 << addr_lsb;
                end
                3'b001: begin          // SH
                    mem_wdata = {16'b0, store_data[15:0]} << {addr_lsb[1], 4'b0000};
                    wstrb     = addr_lsb[1] ? 4'b1100 : 4'b0011;
                end
                3'b010: begin          // SW
                    mem_wdata = store_data;
                    wstrb     = 4'b1111;
                end
                default: begin end
            endcase
        end
    end

    // ---------------- load side ----------------
    wire [31:0] shifted = mem_rdata >> {addr_lsb, 3'b000};   // shift the wanted byte down to [7:0]

    always @(*) begin
        case (funct3)
            3'b000:  load_data = {{24{shifted[7]}},  shifted[7:0]};    // LB  (sign-extend)
            3'b001:  load_data = {{16{shifted[15]}}, shifted[15:0]};   // LH  (sign-extend)
            3'b010:  load_data = mem_rdata;                            // LW
            3'b100:  load_data = {24'b0, shifted[7:0]};                // LBU (zero-extend)
            3'b101:  load_data = {16'b0, shifted[15:0]};               // LHU (zero-extend)
            default: load_data = 32'd0;
        endcase
    end
endmodule
