# Variables
RTL_DIR  := rtl
TB_DIR   := tb
SW_DIR   := sw
SIM_DIR  := sim

RTL := $(RTL_DIR)/rv32i_top.v \
       $(RTL_DIR)/rv32i_core.v \
       $(RTL_DIR)/pc_reg.v \
       $(RTL_DIR)/adder.v \
       $(RTL_DIR)/mux2.v \
       $(RTL_DIR)/mux4.v \
       $(RTL_DIR)/imem.v \
       $(RTL_DIR)/dmem.v \
       $(RTL_DIR)/regfile.v \
       $(RTL_DIR)/imm_gen.v \
       $(RTL_DIR)/alu.v \
       $(RTL_DIR)/control_unit.v \
       $(RTL_DIR)/alu_decoder.v \
       $(RTL_DIR)/branch_unit.v \
       $(RTL_DIR)/lsu.v \
       $(RTL_DIR)/next_pc.v

PROGRAMS := arith_loop p1_arraysum p2_gcd p3_fib p4_memcpy p5_coverage p6_gapfill

IVFLAGS  := -g2012 -I $(RTL_DIR)

# Colours (if terminal supports them)
GREEN  := \033[32m
RED    := \033[31m
RESET  := \033[0m

# ────────────────────────────────────────────────────────
# Default target: compile and run all test programs
# ────────────────────────────────────────────────────────
.PHONY: all clean help

all: $(SIM_DIR) $(PROGRAMS)
	@echo ""
	@echo "All done."

$(SIM_DIR):
	@mkdir -p $(SIM_DIR)

# Pattern rule: compile → simulate → check exit code
.PHONY: $(PROGRAMS)
$(PROGRAMS): %: $(SIM_DIR)
	@iverilog $(IVFLAGS) \
	    -DHEX_FILE=\"$(SW_DIR)/$*.hex\" \
	    -DEXPECT_FILE=\"$(SW_DIR)/$*.expect\" \
	    -o $(SIM_DIR)/$*.vvp \
	    $(TB_DIR)/tb_rv32i.v $(RTL) > $(SIM_DIR)/$*.log 2>&1 && \
	 vvp $(SIM_DIR)/$*.vvp >> $(SIM_DIR)/$*.log 2>&1 && \
	 printf "  $(GREEN)PASS$(RESET)  %s\n" "$*" || \
	 printf "  $(RED)FAIL$(RESET)  %s  — see $(SIM_DIR)/$*.log\n" "$*"

# ────────────────────────────────────────────────────────
# Run a single program:  make run P=p2_gcd
# ────────────────────────────────────────────────────────
.PHONY: run
run: $(SIM_DIR)
ifndef P
	$(error Usage: make run P=<program>   e.g. make run P=p2_gcd)
endif
	iverilog $(IVFLAGS) \
	    -DHEX_FILE=\"$(SW_DIR)/$(P).hex\" \
	    -DEXPECT_FILE=\"$(SW_DIR)/$(P).expect\" \
	    -o $(SIM_DIR)/$(P).vvp \
	    $(TB_DIR)/tb_rv32i.v $(RTL)
	vvp $(SIM_DIR)/$(P).vvp | tee $(SIM_DIR)/$(P).log
	@cp -f $(SIM_DIR)/rv32i.vcd $(SIM_DIR)/$(P).vcd 2>/dev/null || true
	@echo "Waveform saved: $(SIM_DIR)/$(P).vcd"

# ────────────────────────────────────────────────────────
# Cleanup
# ────────────────────────────────────────────────────────
clean:
	rm -rf $(SIM_DIR)/*.vvp $(SIM_DIR)/*.vcd $(SIM_DIR)/*.log

help:
	@echo "Targets:"
	@echo "  make            — run all 7 test programs"
	@echo "  make run P=xxx  — run a single program and save its waveform"
	@echo "  make clean      — delete simulation outputs"
	@echo ""
	@echo "Programs: $(PROGRAMS)"
