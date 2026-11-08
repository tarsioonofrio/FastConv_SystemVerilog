#!/usr/bin/env bash
# Simulação RTL (Xcelium) de uma config do conv4x4 com os mesmos defines da síntese (list-define.txt, inclusive
# ASIC_NUM_MULT), para comparar com a simulação de portas. run_flow_list.sh simula o RTL só com o NUM_MULT padrão.
# Uso, na raiz do repositório, no tmux com shell de login:  bash -l scripts/rtl_sim_config.sh <config> <log>
set -u
c=$1; log=$2; R=$PWD; S=rtl/conv4x4/synthesis
module load xcelium/2303 > /dev/null 2>&1
val() { grep -oP "^$1=\K.*" "$R/$S/$c/top-parameters.txt"; }
fr=$(val WEIGHT_FRAC_BITS); ex=$(val EXTRA_FRAC_BITS)
files=$(grep -v '^$' "$R/$S/$c/list-file.txt" | sed "s|^|$R/|")
defs=$(grep -v -e '^$' -e ASIC_CAPTURE_SHM "$R/$S/$c/list-define.txt" | tr '\n' ' ')
w=$(mktemp -d); cd "$w" || exit 1
xrun -sv -64bit -q -smartorder -top tb_stream_column -access +rw -timescale 1ns/1ps \
  -defparam tb_stream_column.WEIGHT_FRAC_BITS="$fr" -defparam tb_stream_column.EXTRA_FRAC_BITS="$ex" $files \
  "$R/$(cat "$R/$S/$c/testbench-file.txt")" $defs -run -exit > "$log" 2>&1
echo "$c: $(grep -cE 'simulation passed' "$log") passou, $(grep -c 'ERROR' "$log") erros"
cd /; rm -rf "$w"
