@echo off
setlocal
if not exist sim mkdir sim
set RTL=rtl\rv32i_top.v rtl\rv32i_core.v rtl\pc_reg.v rtl\adder.v rtl\mux2.v rtl\mux4.v rtl\imem.v rtl\dmem.v rtl\regfile.v rtl\imm_gen.v rtl\alu.v rtl\control_unit.v rtl\alu_decoder.v rtl\branch_unit.v rtl\lsu.v rtl\next_pc.v
iverilog -g2012 -I rtl -DHEX_FILE=\"sw/%1.hex\" -DEXPECT_FILE=\"sw/%1.expect\" -o sim\%1.vvp tb\tb_rv32i.v %RTL% || exit /b 1
vvp sim\%1.vvp
copy /y sim\rv32i.vcd sim\%1.vcd >nul
echo Waveform saved: sim\%1.vcd