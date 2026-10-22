`timescale 1ns/1ps

module regfile_tb;

    reg         clk;
    reg         rst;
    reg         reg_write;
    reg  [4:0]  rs1_addr;
    reg  [4:0]  rs2_addr;
    reg  [4:0]  rd_addr;
    reg  [31:0] rd_data;
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;

    regfile dut (
        .clk(clk), .rst(rst), .reg_write(reg_write),
        .rs1_addr(rs1_addr), .rs2_addr(rs2_addr),
        .rd_addr(rd_addr), .rd_data(rd_data),
        .rs1_data(rs1_data), .rs2_data(rs2_data)
    );

    // clock: flips every 5 ns, so one full cycle is 10 ns
    initial clk = 0;
    always #5 clk = ~clk;

     initial begin
        $dumpfile("regfile_tb.vcd");
        $dumpvars(0, regfile_tb);

        // start with everything off
        rst = 0; reg_write = 0;
        rs1_addr = 0; rs2_addr = 0; rd_addr = 0; rd_data = 0;

        // RESET at the start (new)
        rst = 1;
        @(posedge clk);
        #1;
        rst = 0;

        // TEST 1: write DEAD_BEEF into x5
        rd_addr = 5'd5;
        rd_data = 32'hDEAD_BEEF;
        reg_write = 1;
        @(posedge clk);
        #1;
        reg_write = 0;

        rs1_addr = 5'd5;
        #1;
        $display("x5 = %h (expected deadbeef)", rs1_data);

        // read x5 on port 2 as well (new)
        rs2_addr = 5'd5;
        #1;
        $display("rs2 reads x5 = %h (expected deadbeef)", rs2_data);

        // TEST 2: try to write into x0
        rd_addr = 5'd0;
        rd_data = 32'h1234_5678;
        reg_write = 1;
        @(posedge clk);
        #1;
        reg_write = 0;

        rs1_addr = 5'd0;
        #1;
        $display("x0 = %h (expected 00000000)", rs1_data);
        $display("regs[0] inside = %h (expected 00000000)", dut.regs[0]);

        // TEST 3: reset clears x5 (new)
        rst = 1;
        @(posedge clk);
        #1;
        rst = 0;
        rs1_addr = 5'd5;
        #1;
        $display("x5 after reset = %h (expected 00000000)", rs1_data);

        $finish;
    end
endmodule