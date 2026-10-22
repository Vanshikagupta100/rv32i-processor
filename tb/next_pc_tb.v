module next_pc_tb;
    reg  [31:0] pc, imm, rs1;
    reg         jalr, jump, bt;
    wire [31:0] p4, pn;

    next_pc dut (.pc(pc), .imm(imm), .rs1_data(rs1), .jalr(jalr), .jump(jump),
                 .branch_taken(bt), .pc_plus4(p4), .pc_next(pn));

    task t;
        input [31:0] exp;
        input [79:0] name;
        begin
            #1;
            $display("%s: pc_next=%h exp=%h %s", name, pn, exp, (pn === exp) ? "PASS" : "FAIL");
        end
    endtask

    initial begin
        pc = 32'h40; imm = 32'hFFFF_FFE0; rs1 = 32'h101;       // imm = -32
        jalr = 0; jump = 0; bt = 0;  t(32'h44,  "sequential");
        bt = 1;                      t(32'h20,  "branch    ");   // 0x40 - 32
        bt = 0; jump = 1;            t(32'h20,  "jal       ");
        jump = 0; jalr = 1; imm = 32'd4;
                                     t(32'h104, "jalr      ");   // (0x101+4) with bit 0 cleared
        $display("pc_plus4 = %h (expect 00000044)", p4);
        $finish;
    end
endmodule