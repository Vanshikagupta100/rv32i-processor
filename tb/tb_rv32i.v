`timescale 1ns/1ps

`ifndef HEX_FILE
  `define HEX_FILE "arith.hex"
`endif
`ifndef EXPECT_FILE
  `define EXPECT_FILE "arith.expect"
`endif

module tb_rv32i;
    // 20000 cycles is far above what any of our programs needs (a few hundred),
    // yet a runaway program still gets stopped in well under a second of sim time.
    parameter MAX_CYCLES   = 20000;
    parameter STABLE_EDGES = 3;     // PC unchanged this many edges in a row = done

    reg clk = 0;
    reg rst = 1;
    always #5 clk = ~clk;

    rv32i_top #(.INIT_FILE(`HEX_FILE)) dut (.clk(clk), .rst(rst));

    // ---------- completion detector ----------
    wire [31:0] pc = dut.u_core.u_pc.pc;
    reg  [31:0] pc_prev = 32'hx;
    integer     stable  = 0;
    integer     cycles  = 0;

    always @(posedge clk) begin
        if (!rst) begin
            cycles = cycles + 1;
            if (pc === pc_prev) stable = stable + 1;
            else                stable = 0;
            pc_prev <= pc;
        end
    end

    // ---------- checking ----------
    integer passed = 0, failed = 0;

    task check_reg;
        input integer r;
        input [31:0]  expv;
        begin
            if (dut.u_core.u_regfile.regs[r] === expv) begin
                $display("PASS x%0d = %h", r, dut.u_core.u_regfile.regs[r]);
                passed = passed + 1;
            end else begin
                $display("FAIL x%0d = %h (expected %h)", r, dut.u_core.u_regfile.regs[r], expv);
                failed = failed + 1;
            end
        end
    endtask

    task check_mem;
        input integer w;
        input [31:0]  expv;
        begin
            if (dut.u_dmem.mem[w] === expv) begin
                $display("PASS mem[%0d] = %h", w, dut.u_dmem.mem[w]);
                passed = passed + 1;
            end else begin
                $display("FAIL mem[%0d] = %h (expected %h)", w, dut.u_dmem.mem[w], expv);
                failed = failed + 1;
            end
        end
    endtask

    integer     fd, idx, rc;
    reg [31:0]  val;
    reg [1023:0] line;

    initial begin
        $dumpfile("sim/rv32i.vcd");
        $dumpvars(0, tb_rv32i);

        repeat (3) @(posedge clk);          // reset held for 3 cycles
        #1 rst = 0;

        while (stable < STABLE_EDGES && cycles < MAX_CYCLES) begin
            @(posedge clk);
            #1;
        end

        if (stable < STABLE_EDGES) begin
            $display("TIMEOUT after %0d cycles (pc = %h)", cycles, pc);
            $fatal(1, "TIMEOUT");
        end

        // x0 must always be zero, whatever the program did
        check_reg(0, 32'd0);

        // every line of the expect file: "R <reg> <hex>" or "M <word> <hex>"
        fd = $fopen(`EXPECT_FILE, "r");
        if (fd == 0) begin
            $display("ERROR: cannot open %s", `EXPECT_FILE);
            $fatal(1, "missing expect file");
        end
        while (!$feof(fd)) begin
            line = 0;
            rc = $fgets(line, fd);
            if ($sscanf(line, "R %d %h", idx, val) == 2)      check_reg(idx, val);
            else if ($sscanf(line, "M %d %h", idx, val) == 2) check_mem(idx, val);
        end
        $fclose(fd);

        $display("SUMMARY: %0d cycles, %0d passed, %0d failed", cycles, passed, failed);
        if (failed != 0) $fatal(1, "%0d check(s) failed", failed);
        $finish;
    end
endmodule