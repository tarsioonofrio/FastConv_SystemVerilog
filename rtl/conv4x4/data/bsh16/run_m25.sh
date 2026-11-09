#!/usr/bin/env bash
# Simulação RTL e fluxo ASIC das configs de 2 estados (25 e 28 multiplicadores). A simulação usa os defines da síntese, porque
# run_flow_list.sh simula com o NUM_MULT padrão (7), que o RTL de 25 rejeita.
# Uso, na raiz do repositório, no tmux, com shell de login: bash -l rtl/conv4x4/data/bsh16/run_m25.sh <lista> <pasta de logs>
set -u
LIST=$1; LOGS=$2; mkdir -p "$LOGS"; LOGS=$(cd "$LOGS" && pwd); ST=$LOGS/status
module load xcelium/2303 > /dev/null 2>&1
for c in $(cat "$LIST"); do
  bash -l scripts/rtl_sim_config.sh "$c" "$LOGS/rtl-$c.log" >> "$ST" 2>&1
  grep -q "simulation passed" "$LOGS/rtl-$c.log" || { echo "RTLFAIL $c" >> "$ST"; continue; }
  make flow ARCH=conv4x4 CONFIG="$c" > "$LOGS/flow-$c.log" 2>&1
  echo "$c exit $? $(date +%F_%H:%M)" >> "$ST"
done
echo ALLDONE >> "$ST"
