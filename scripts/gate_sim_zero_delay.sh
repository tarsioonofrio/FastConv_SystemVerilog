#!/usr/bin/env bash
# Simulação de portas da netlist de uma config do conv4x4 com atraso zero (sem SDF, -nospecify, -notimingchecks), para
# separar erro de lógica (a netlist difere do RTL) de erro de timing (SDF). Mesmo testbench e mesmos arquivos do
# sim/run.sh da config. Uso, na raiz do repositório, no tmux:  bash -l scripts/gate_sim_zero_delay.sh <config> <log>
set -u
c=$1; log=$2; R=$PWD; C=$R/rtl/conv4x4/synthesis/$c
module load xcelium/2303 > /dev/null 2>&1
TB=$R/$(awk 'NF && $1 !~ /^#/ {print $1; exit}' "$C/testbench-file.txt")
RTLTOP=$(awk 'NF && $1 !~ /^#/ {print $1; exit}' "$C/rtl-top-file.txt")
files=$(grep -v -e '^$' -e "^$RTLTOP\$" "$C/list-file.txt" | sed "s|^|$R/|" | tr '\n' ' ')
LIB=/pdk/tsmc/PDK28/PDK_TSMC28_bv/tcbn28hpcplusbwp30p140_190a/TSMCHOME/digital/Front_End/verilog/tcbn28hpcplusbwp30p140_110a/tcbn28hpcplusbwp30p140.v
w=$(mktemp -d); cd "$w" || exit 1
xrun -smartorder -work work -top tb_stream_column -access +rw -timescale 1ns/1ps -nospecify -notimingchecks $LIB \
  $files "$TB" "$C/logical/results/gate_level/Conv_logic_mapped.v" -f "$C/list-define.txt" -define GATE_LEVEL -define XRUN \
  -run -exit > "$log" 2>&1
echo "$c: $(grep -c 'simulation passed' "$log") passou, $(grep -c 'ERROR GATE' "$log") erros"
cd /; rm -rf "$w"
