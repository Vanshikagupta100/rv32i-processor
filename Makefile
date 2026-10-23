# RV32I single-cycle processor: build and test with Icarus Verilog
#
#   make                 same as make test
#   make test            run every program in sw/ through the self-checking testbench
#   make run P=p2_gcd    run one program and keep its waveform in sim/p2_gcd.vcd
#   make unit            run the module-level testbenches in tb/
#   make lint            Verilator lint (optional tool)
#   make synth           Yosys elaboration + structural checks (optional tool)
#   make all             test + unit + lint + synth (what CI runs)
#   make clean

IVERILOG ?= iverilog
VVP      ?= vvp
IFLAGS   := -g2012 -I rtl

RTL := rtl/rv32i_top.v rtl/rv32i_core.v rtl/pc_reg.v rtl/adder.v rtl/mux2.v rtl/mux4.v \
       rtl/imem.v rtl/dmem.v rtl/regfile.v rtl/imm_gen.v rtl/alu.v rtl/control_unit.v \
       rtl/alu_decoder.v rtl/branch_unit.v rtl/lsu.v rtl/next_pc.v

PROGS := arith_loop p1_arraysum p2_gcd p3_fib p4_memcpy p5_coverage p6_gapfill p7_edge
PROG  ?= $(if $(P),$(P),p1_arraysum)

# The core only (memories are external), used for the synthesis checks
CORE := $(filter-out rtl/rv32i_top.v rtl/imem.v rtl/dmem.v,$(RTL))

.PHONY: default all test run unit lint synth clean help
default: test
all: test unit lint synth

sim:
	mkdir -p sim

test: | sim
	@fail=0; \
	for p in $(PROGS); do \
	  if $(IVERILOG) $(IFLAGS) -DHEX_FILE=\"sw/$$p.hex\" -DEXPECT_FILE=\"sw/$$p.expect\" \
	       -o sim/$$p.vvp tb/tb_rv32i.v $(RTL) > sim/$$p.log 2>&1 \
	     && $(VVP) sim/$$p.vvp >> sim/$$p.log 2>&1; then \
	    printf '%-14s PASS   %s\n' $$p "$$(grep SUMMARY sim/$$p.log | sed 's/SUMMARY: //')"; \
	  else \
	    printf '%-14s FAIL   (see sim/%s.log)\n' $$p $$p; fail=1; \
	  fi; \
	done; \
	echo; \
	if [ $$fail -eq 0 ]; then echo "All programs passed."; else echo "Some programs FAILED."; exit 1; fi

run: | sim
	$(IVERILOG) $(IFLAGS) -DHEX_FILE=\"sw/$(PROG).hex\" -DEXPECT_FILE=\"sw/$(PROG).expect\" \
	  -o sim/$(PROG).vvp tb/tb_rv32i.v $(RTL)
	$(VVP) sim/$(PROG).vvp
	cp sim/rv32i.vcd sim/$(PROG).vcd
	@echo "Waveform: sim/$(PROG).vcd (open with GTKWave)"

unit: | sim
	@fail=0; \
	run() { name=$$1; shift; \
	  if ! $(IVERILOG) $(IFLAGS) -o sim/$$name.vvp "$$@" 2> sim/$$name.err; then \
	    echo "$$name: COMPILE ERROR"; cat sim/$$name.err; fail=1; return; fi; \
	  out=$$($(VVP) sim/$$name.vvp 2>&1); \
	  if echo "$$out" | grep -q FAIL; then echo "$$name: FAIL"; echo "$$out" | grep FAIL; fail=1; \
	  else n=$$(echo "$$out" | grep -c PASS); \
	       if [ $$n -gt 0 ]; then echo "$$name: ok ($$n checks)"; else echo "$$name: ran (prints values, no automatic check)"; fi; fi; }; \
	run alu_tb      tb/alu_tb.v      rtl/alu.v; \
	run aludec_tb   tb/aludec_tb.v   rtl/alu_decoder.v; \
	run branch_tb   tb/branch_tb.v   rtl/branch_unit.v; \
	run next_pc_tb  tb/next_pc_tb.v  rtl/next_pc.v rtl/adder.v rtl/mux2.v; \
	run lsu_tb      tb/lsu_tb.v      rtl/lsu.v; \
	run mem_tb      tb/mem_tb.v      rtl/imem.v rtl/dmem.v; \
	run regfile_tb  tb/regfile_tb.v  rtl/regfile.v; \
	run imm_gen_tb  tb/imm_gen_tb.v  rtl/imm_gen.v; \
	run control_tb  tb/control_tb.v  rtl/control_unit.v; \
	exit $$fail

# Warnings switched off are the benign ones: deliberately unused bits (instruction
# fields, byte-offset address bits) and word-address indexing into the 1024-word memories.
lint:
	verilator --lint-only -Wall -Irtl -sv --top-module rv32i_top $(RTL) \
	  -Wno-UNUSEDSIGNAL -Wno-WIDTHTRUNC -Wno-CASEINCOMPLETE -Wno-EOFNEWLINE -Wno-DECLFILENAME

synth: | sim
	@printf '%s\n' \
	  'read_verilog -sv -Irtl $(CORE)' \
	  'hierarchy -check -top rv32i_core' \
	  'proc' \
	  'check -assert' \
	  'stat' > sim/synth.ys
	yosys -q -l sim/synth.log sim/synth.ys
	@echo "Yosys elaboration and structural checks passed (see sim/synth.log)."

clean:
	rm -rf sim *.vcd

help:
	@echo "make            run all test programs"
	@echo "make run P=xxx  run one program and keep its waveform in sim/xxx.vcd"
	@echo "make unit       module-level testbenches"
	@echo "make lint       Verilator lint     (needs verilator)"
	@echo "make synth      Yosys checks       (needs yosys)"
	@echo "make all        everything above"
	@echo "Programs: $(PROGS)"
