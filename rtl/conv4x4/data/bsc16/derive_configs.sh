#!/usr/bin/env bash
# Cria as 4 configs ASIC do bsc16 copiando as entradas (não os resultados nem os logs) das configs bsn16 equivalentes.
# Uso, na raiz do FastConv_SystemVerilog: derive_configs.sh [pasta de destino]
set -eu
S=rtl/conv4x4/synthesis
OUT=${1:-$S}
BS=conv-bsn16-i60-h16-t14-o16-m07-stream14-prefetch24-rowconst7
BC=conv-bsc16-i60-h16-t14-o16-m07-stream14-prefetch24-rowconst7
for v in "" "twopass-"; do for load in cin3-cout12 cin16-cout16-l10c1; do
  s=$BS-${v}round-column-frac0-extra0-nbits16-$load
  d=$OUT/$BC-${v}round-column-frac0-extra0-nbits16-$load
  git ls-files "$S/$s" |
    grep -v -E '/logical/results|/logical/reports|xrun\.log|power_evaluation|execution_time|access_counts|genus\.(log|cmd)' |
  while read -r f; do r=${f#"$S/$s/"}; mkdir -p "$d/$(dirname "$r")"; cp "$f" "$d/$r"; done
  grep -rl bsn16 "$d" | xargs -r sed -i 's/bsn16/bsc16/g'
done; done
