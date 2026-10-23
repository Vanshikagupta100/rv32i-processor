# RV32I Single-Cycle Processor

[![CI](https://github.com/Vanshikagupta100/rv32i-processor/actions/workflows/ci.yml/badge.svg)](https://github.com/Vanshikagupta100/rv32i-processor/actions/workflows/ci.yml)

A single-cycle RISC-V processor written in Verilog, implementing the complete **RV32I base integer instruction set**. Built as a learning project during the RISE cohort, developed with AI assistance for implementation, testbench design, and verification.

![Top-level block diagram](docs/block_diagram_top.png)

## Features

- **Single-cycle execution** - one instruction completes every clock cycle
- **Harvard architecture** - separate instruction and data memories
- **Full RV32I support** - all 37 base integer instructions:
  - Arithmetic: `ADD`, `SUB`, `ADDI`
  - Logic: `AND`, `OR`, `XOR`, `ANDI`, `ORI`, `XORI`
  - Shifts: `SLL`, `SRL`, `SRA`, `SLLI`, `SRLI`, `SRAI`
  - Comparisons: `SLT`, `SLTU`, `SLTI`, `SLTIU`
  - Loads: `LB`, `LBU`, `LH`, `LHU`, `LW`
  - Stores: `SB`, `SH`, `SW`
  - Branches: `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`
  - Jumps: `JAL`, `JALR`
  - Upper immediates: `LUI`, `AUIPC`
  - `FENCE`, `ECALL`, `EBREAK` treated as NOPs
- **Byte-granular memory** - the load-store unit handles sub-word alignment with write strobes
- **8 test programs** with automated pass/fail verification
- **9 unit testbenches** (6 self-checking, 3 visual)

## Architecture

The core is structured into clean, single-responsibility modules:

![Core datapath](docs/block_diagram_core.png)

**Datapath flow:** PC -> instruction memory -> decode -> register file -> ALU -> data memory -> writeback

| Module | What it does |
|---|---|
| `pc_reg` | Program counter with synchronous reset |
| `control_unit` | Decodes opcode into control signals |
| `alu_decoder` | Picks ALU operation from funct3/funct7 |
| `imm_gen` | Generates sign-extended immediates (I/S/B/U/J) |
| `regfile` | 32x32-bit register file, x0 hardwired to zero |
| `alu` | 11 operations: add, sub, shifts, comparisons, logic, pass-through |
| `branch_unit` | Evaluates all six branch conditions |
| `next_pc` | Chooses between PC+4, branch target, JAL, or JALR |
| `lsu` | Byte-lane alignment for loads and stores |
| `mux2` / `mux4` | Parameterised multiplexers |
| `adder` | 32-bit adder (used for PC+4, PC+imm, rs1+imm) |

### Instruction Formats

![RV32I instruction formats](docs/instruction_formats.png)

## Design Notes

- **Harvard Architecture:** Instruction and data memories occupy separate address spaces (each 1024 words in this implementation), enabling simultaneous instruction fetch and data memory access in the same clock cycle without contention.
- **Critical Path:** In a single-cycle RV32I processor, the longest combinational path is typically the load instruction: `PC -> imem -> decode -> regfile read -> ALU (effective address) -> dmem read -> LSU (byte extraction / sign extension) -> writeback MUX -> regfile setup`. This path sets the maximum clock frequency.
- **x0 Protection:** Register `x0` is guarded in two ways: writes to `rd = 0` are suppressed in the synchronous write block, and combinational reads from `rs1 = 0` or `rs2 = 0` are hardwired to return `32'd0`.

## Directory Structure

```
rtl/           Synthesisable Verilog (the processor itself)
tb/            Testbenches - 1 integration + 9 unit
sw/            Test programs: assembly (.s), machine code (.hex), expected results (.expect)
docs/          Block diagrams and waveform screenshots
sim/           Simulation outputs (generated, gitignored)
.github/       CI workflows (automated simulation, linting, and synthesis checks)
Makefile       Build/run for Linux and macOS
run_all.bat    Build/run for Windows
run_one.bat    Run a single test on Windows
```

## Getting Started

### Prerequisites

You need [Icarus Verilog](http://iverilog.icarus.com/) to simulate. For linting and synthesis checks, [Verilator](https://www.veripool.org/verilator/) and [Yosys](https://yosyshq.net/yosys/) are optional.

- **Linux:** `sudo apt install iverilog verilator yosys`
- **macOS:** `brew install icarus-verilog verilator yosys`
- **Windows:** download the Icarus Verilog installer from the [official site](http://bleyer.org/icarus/)

### Run all tests

**Linux / macOS:**
```bash
make test
```

**Windows:**
```cmd
run_all.bat
```

### Run a single test (with waveform)

**Linux / macOS:**
```bash
make run P=p2_gcd
```

**Windows:**
```cmd
run_one.bat p2_gcd
```

This saves a `.vcd` waveform file you can open in [GTKWave](http://gtkwave.sourceforge.net/) or any VCD viewer.

### Example waveform

Here is a snippet from the `p4_memcpy` test showing the PC advancing, instructions being fetched, and data memory writes:

![Waveform from p4_memcpy](docs/waveform_p4_memcpy.png)

## Test Programs

| # | Program | What it exercises | Cycles |
|---|---|---|---|
| 1 | `arith_loop` | R-type and I-type arithmetic (ADD, SUB, shifts, SLT, etc.) | 18 |
| 2 | `p1_arraysum` | Loops, array loads and stores | 163 |
| 3 | `p2_gcd` | GCD algorithm with heavy branching | 52 |
| 4 | `p3_fib` | Fibonacci sequence using memory + loops | 131 |
| 5 | `p4_memcpy` | Memory copy with byte-width loads and stores | 116 |
| 6 | `p5_coverage` | All branch types, LUI, AUIPC, JAL, JALR, all load/store widths | 45 |
| 7 | `p6_gapfill` | Register-operand shifts (SLL/SRL/SRA), SLTI, SLTIU, XORI | 14 |
| 8 | `p7_edge` | Edge cases: BGE/BGEU equal operands, JALR odd target, LUI non-zero rs1, invalid branch funct3 | 25 |

Each program includes:
- `.s` - commented RISC-V assembly source
- `.hex` - machine code (loaded by `$readmemh`)
- `.expect` - expected register and memory values, validated automatically

## Verification

Testing is automated at multiple levels:

1. **Integration Testbench (`tb/tb_rv32i.v`):**
   - Loads each `.hex` into instruction memory
   - Holds reset for 3 cycles, then releases
   - Monitors the PC until it stops changing (program terminates in a self-loop `done: beq x0, x0, done`)
   - Compares architectural registers and memory locations against the corresponding `.expect` file
   - Prints PASS/FAIL per checked address and a cycle summary
2. **Bug Injection Validation:**
   - 18 deliberate bugs were injected into the RTL (e.g. inverted branch comparisons, faulty sign-extensions, JALR bit-0 not cleared, write-enable errors). All 18 bugs are caught by the test suite with `p7_edge` included.
3. **Linting and Elaboration:**
   - **Verilator Lint:** `make lint` checks for undeclared nets, width mismatches, and syntax issues.
   - **Yosys Synthesis Check:** `make synth` elaborates `rv32i_core` through Yosys to confirm there are no inferred latches, combinational feedback loops, or multi-driven nets.
4. **CI Pipeline:**
   - GitHub Actions runs `make all` on every push and pull request, executing test programs, unit tests, Verilator lint, and Yosys checks on a fresh Ubuntu runner.

## Limitations

- **Single-cycle design:** Instruction latency is 1 cycle; clock frequency is limited by the critical load path.
- **No privilege architecture:** No CSRs, traps, exceptions, or interrupts.
- **FENCE / SYSTEM:** `FENCE`, `ECALL`, and `EBREAK` are decoded as NOPs.
- **Unaligned accesses:** Misaligned loads/stores are not hardware-trapped (ignored or wrapped).
- **Memory size:** Instruction and data memories are 1024 words each (4 KB each). Reads past this range return `x` in simulation.
- **Simulation focus:** Verified in simulation with Icarus Verilog; not yet placed/routed onto an FPGA board.

> **Note on `program.hex`:** `imem` and `rv32i_top` have default parameter `INIT_FILE = "program.hex"`. A minimal dummy file is kept at the project root so top-level instantiation without overriding `INIT_FILE` does not fail with a missing file error.

## Adding a Test Program

1. Write your RISC-V assembly in `sw/<name>.s`. End with a halt loop:
   ```assembly
   done:
       beq x0, x0, done
   ```
2. Assemble and produce a 32-bit hex file (`sw/<name>.hex`). Using the GNU RISC-V toolchain:
   ```bash
   riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 -o <name>.o <name>.s
   riscv64-unknown-elf-objcopy -O binary <name>.o <name>.bin
   od -An -tx4 -v -w4 <name>.bin > sw/<name>.hex
   ```
3. Create `sw/<name>.expect` with expected register (`R <reg> <hex>`) and memory (`M <word_addr> <hex>`) values.
4. Add the program name to `PROGS` in the `Makefile` and `run_all.bat`.

## Future Ideas

- **Pipelining:** Convert to a 5-stage pipeline (IF, ID, EX, MEM, WB) with hazard detection and forwarding
- **CSRs & Traps:** Support machine-mode trap handling (mtvec, mepc, mcause)
- **M Extension:** Implement hardware multiplication and division (`MUL`, `DIV`, `REM`)
- **FPGA Implementation:** Target a development board (e.g., IceStick / Basys 3) with a seven-segment display or UART interface
- **Caches:** Add direct-mapped or set-associative I/D caches

## License

MIT - see [LICENSE](LICENSE) for details.

---

Built by [@Vanshikagupta100](https://github.com/Vanshikagupta100)
