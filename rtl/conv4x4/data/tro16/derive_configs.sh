#!/usr/bin/env bash
# Cria as 4 configs ASIC do tro16 copiando as entradas (não os resultados) das configs wpn16 equivalentes.
# Uso, na raiz do FastConv_SystemVerilog: derive_configs.sh [pasta de destino]
set -eu
S=rtl/conv4x4/synthesis
OUT=${1:-$S}
WP=conv-wpn16-i60-h17-t16-o16-m08-stream16-prefetch24-rowconst8
TR=conv-tro16-i60-h17-t16-o16-m08-stream16-prefetch24-rowconst8
for v in "" "twopass-"; do for load in cin3-cout12 cin16-cout16-l10c1; do
  s=$WP-${v}round-column-frac0-extra0-nbits16-$load
  d=$OUT/$TR-${v}round-column-frac0-extra0-nbits16-$load
  git ls-files "$S/$s" | grep -v -E '/logical/results|/logical/reports|xrun\.log|power_evaluation|execution_time|access_counts' |
  while read -r f; do r=${f#"$S/$s/"}; mkdir -p "$d/$(dirname "$r")"; cp "$f" "$d/$r"; done
  grep -rl wpn16 "$d" | xargs -r sed -i 's/wpn16/tro16/g'
done; done
