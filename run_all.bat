@echo off
setlocal
if not exist sim mkdir sim

set RTL=rtl\rv32i_top.v rtl\rv32i_core.v rtl\pc_reg.v rtl\adder.v rtl\mux2.v rtl\mux4.v rtl\imem.v rtl\dmem.v rtl\regfile.v rtl\imm_gen.v rtl\alu.v rtl\control_unit.v rtl\alu_decoder.v rtl\branch_unit.v rtl\lsu.v rtl\next_pc.v
set FAILS=0

for %%P in (arith_loop p1_arraysum p2_gcd p3_fib p4_memcpy p5_coverage p6_gapfill) do (
  iverilog -g2012 -I rtl -DHEX_FILE=\"sw/%%P.hex\" -DEXPECT_FILE=\"sw/%%P.expect\" -o sim\%%P.vvp tb\tb_rv32i.v %RTL% > sim\%%P.log 2>&1
  if errorlevel 1 (
    echo %%P : COMPILE ERROR
    set /a FAILS+=1
  ) else (
    vvp sim\%%P.vvp >> sim\%%P.log 2>&1
    if errorlevel 1 (
      echo %%P : FAIL   - see sim\%%P.log
      set /a FAILS+=1
    ) else (
      echo %%P : PASS
    )
  )
)

echo.
echo Programs failed: %FAILS%