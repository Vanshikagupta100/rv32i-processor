// mem_tb.v — quick sanity check for imem reads and dmem byte-lane writes
module mem_tb;
    reg         clk = 0;
    always #5 clk = ~clk;

    reg  [31:0] iaddr;
    wire [31:0] instr;
    imem #(.DEPTH(64), .INIT_FILE("sw/arith.hex")) u_imem (.addr(iaddr), .instr(instr));

    reg         mem_write;
    reg  [3:0]  wstrb;
    reg  [31:0] daddr, wdata;
    wire [31:0] rdata;
    dmem #(.DEPTH(64)) u_dmem (.clk(clk), .mem_write(mem_write), .wstrb(wstrb),
                               .addr(daddr), .wdata(wdata), .rdata(rdata));

    integer passed = 0, failed = 0;

    task check;
        input [255:0] label;
        input [31:0]  got, expected;
        begin
            if (got === expected) begin
                $display("PASS %0s = %h", label, got);
                passed = passed + 1;
            end else begin
                $display("FAIL %0s = %h (expected %h)", label, got, expected);
                failed = failed + 1;
            end
        end
    endtask

    initial begin
        // imem reads — first two instructions of arith.hex
        iaddr = 0;  #1; check("imem[0]", instr, 32'h00f00093);
        iaddr = 4;  #1; check("imem[1]", instr, 32'hffd00113);

        // dmem: full word write
        mem_write = 1; wstrb = 4'b1111; daddr = 0; wdata = 32'hAABBCCDD;
        @(posedge clk); #1;
        check("full word ", rdata, 32'haabbccdd);

        // dmem: single byte lane 1
        wstrb = 4'b0010; wdata = 32'h0000EE00;
        @(posedge clk); #1;
        check("byte lane 1", rdata, 32'haabbeedd);

        // dmem: write disabled — data should stay unchanged
        mem_write = 0; wstrb = 4'b0000; wdata = 32'h11111111;
        @(posedge clk); #1;
        check("write off  ", rdata, 32'haabbeedd);

        $display("SUMMARY: %0d passed, %0d failed", passed, failed);
        if (failed != 0) $fatal(1, "%0d check(s) failed", failed);
        $finish;
    end
endmodule
