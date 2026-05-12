#!/bin/bash
set -e

echo "Compiling..."
iverilog -o sim/ntt_sim.vvp rtl/ntt_8.v tb/tb_ntt_8.v

echo "Running..."
vvp sim/ntt_sim.vvp
