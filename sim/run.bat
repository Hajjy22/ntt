@echo off
echo Compiling...
iverilog -o sim\ntt_sim.vvp rtl\ntt_8.v tb\tb_ntt_8.v
if %errorlevel% neq 0 exit /b %errorlevel%

echo Running...
vvp sim\ntt_sim.vvp
