module branch_tb;
    reg  [31:0] a, b;
    reg  [2:0]  f3;
    reg         br;
    wire        taken;

    branch_unit dut (.rs1_data(a), .rs2_data(b), .funct3(f3), .branch(br), .branch_taken(taken));

    task t;
        input [31:0] x, y;
        input [2:0]  f;
        input        en, exp;
        input [79:0] name;
        begin
            a = x; b = y; f3 = f; br = en; #1;
            $display("%s: taken=%b exp=%b %s", name, taken, exp, (taken === exp) ? "PASS" : "FAIL");
        end
    endtask

    initial begin
        t(32'hFFFF_FFFF, 32'd1,         3'b100, 1, 1, "blt taken ");   // -1 < 1 signed
        t(32'hFFFF_FFFF, 32'd1,         3'b110, 1, 0, "bltu not  ");   // huge < 1 unsigned: no
        t(32'd1,         32'hFFFF_FFFF, 3'b100, 1, 0, "blt not   ");
        t(32'd1,         32'hFFFF_FFFF, 3'b110, 1, 1, "bltu taken");
        t(32'd5, 32'd5, 3'b101, 1, 1, "bge equal ");
        t(32'd5, 32'd5, 3'b111, 1, 1, "bgeu equal");
        t(32'd5, 32'd5, 3'b000, 1, 1, "beq       ");
        t(32'd5, 32'd6, 3'b001, 1, 1, "bne       ");
        t(32'd5, 32'd5, 3'b000, 0, 0, "branch=0  ");
        t(32'd5, 32'd5, 3'b010, 1, 0, "bad funct3");
        $finish;
    end
endmodule