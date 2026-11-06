#!/usr/bin/env bash
# Simulação RTL e fluxo ASIC de uma lista de configs do conv4x4, uma por linha. Se alguma simulação RTL falhar, o fluxo
# não começa. Rode dentro do tmux com shell de login, na raiz do repositório:
#   bash -l scripts/run_flow_list.sh <lista> <pasta de logs>
# DRY=1 só imprime os comandos. <pasta de logs>/status guarda o resultado de cada etapa.
set -u
LIST=$1; LOGS=$2; R=$PWD; S=rtl/conv4x4/synthesis
mkdir -p "$LOGS"; LOGS=$(cd "$LOGS" && pwd); ST=$LOGS/status
[ -n "${DRY:-}" ] || module load xcelium/2303 > /dev/null 2>&1
val() { grep -oP "^$1=\K.*" "$R/$S/$2/top-parameters.txt"; }
for c in $(cat "$LIST"); do
  fr=$(val WEIGHT_FRAC_BITS "$c"); ex=$(val EXTRA_FRAC_BITS "$c"); nb=$(val NBITS "$c")
  files=$(grep -v '^$' "$R/$S/$c/list-file.txt" | sed "s|^|$R/|")
  cmd="xrun -sv -64bit -q -smartorder -top tb_stream_column -access +rw -timescale 1ns/1ps \
-defparam tb_stream_column.WEIGHT_FRAC_BITS=$fr -defparam tb_stream_column.EXTRA_FRAC_BITS=$ex $(echo $files) \
$R/$(cat "$R/$S/$c/testbench-file.txt") -define NADDR=16 -define LATENCY=1 -define QUANT=8 -define NBITS=$nb -run -exit"
  if [ -n "${DRY:-}" ]; then echo "$cmd" | sed "s|$R/||g"; continue; fi
  w=$(mktemp -d -p "$LOGS")
  ( cd "$w" && $cmd > x.log 2>&1
    echo "rtl $c $(grep -E 'simulation passed|mismatch|\*E|\*F' x.log | head -2 | cut -c1-130)" >> "$ST" )
  rm -rf "$w"
done
[ -z "${DRY:-}" ] || { for c in $(cat "$LIST"); do echo "make flow ARCH=conv4x4 CONFIG=$c"; done; exit 0; }
n=$(grep -c . "$LIST")
[ "$(grep -c 'simulation passed' "$ST")" -ge "$n" ] || { echo 'RTLFAIL ALLDONE' >> "$ST"; exit 1; }
for c in $(cat "$LIST"); do
  make flow ARCH=conv4x4 CONFIG="$c" > "$LOGS/flow-$c.log" 2>&1
  echo "$c exit $? $(date +%F_%H:%M)" >> "$ST"
done
echo ALLDONE >> "$ST"
