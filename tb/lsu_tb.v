module lsu_tb;
    reg         mem_write;
    reg  [2:0]  funct3;
    reg  [1:0]  addr_lsb;
    reg  [31:0] store_data, mem_rdata;
    wire [31:0] mem_wdata, load_data;
    wire [3:0]  wstrb;

    lsu dut (.mem_write(mem_write), .funct3(funct3), .addr_lsb(addr_lsb),
             .store_data(store_data), .mem_rdata(mem_rdata),
             .mem_wdata(mem_wdata), .wstrb(wstrb), .load_data(load_data));

    reg [31:0] old, mask, newword;

    task store;
        input [2:0] f3; input [1:0] lsb; input [31:0] d; input [79:0] name;
        begin
            mem_write = 1; funct3 = f3; addr_lsb = lsb; store_data = d; #1;
            mask    = {{8{wstrb[3]}}, {8{wstrb[2]}}, {8{wstrb[1]}}, {8{wstrb[0]}}};
            newword = (old & ~mask) | (mem_wdata & mask);
            $display("%s: wstrb=%b mem_wdata=%h resulting word=%h", name, wstrb, mem_wdata, newword);
        end
    endtask

    task load;
        input [2:0] f3; input [1:0] lsb; input [31:0] exp; input [79:0] name;
        begin
            mem_write = 0; funct3 = f3; addr_lsb = lsb; mem_rdata = old; #1;
            $display("%s: load_data=%h exp=%h %s", name, load_data, exp, (load_data === exp) ? "PASS" : "FAIL");
        end
    endtask

    initial begin
        old = 32'hAABBCCDD;
        store(3'b000, 2'b01, 32'h000000EE, "SB lane1 ");   // expect wstrb 0010, AABBEEDD
        store(3'b001, 2'b10, 32'h00001234, "SH hi     ");   // expect wstrb 1100, 1234CCDD
        store(3'b010, 2'b00, 32'h11223344, "SW        ");   // expect wstrb 1111, 11223344
        mem_write = 0; #1; $display("write off: wstrb=%b (expect 0000)", wstrb);

        load(3'b000, 2'b00, 32'hFFFFFFDD, "LB        ");
        load(3'b100, 2'b00, 32'h000000DD, "LBU       ");
        load(3'b001, 2'b10, 32'hFFFFAABB, "LH        ");
        load(3'b101, 2'b10, 32'h0000AABB, "LHU       ");
        load(3'b010, 2'b00, 32'hAABBCCDD, "LW        ");
        $finish;
    end
endmodule