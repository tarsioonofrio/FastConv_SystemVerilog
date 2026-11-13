#!/usr/bin/env bash
# Cria as configs de 2 estados do bsh16 (25 multiplicadores e, para comparar, 28) copiando as entradas das configs de 7 multiplicadores
# subexpression, sem resultados nem logs. Uso, na raiz do repositório: derive_configs_m25.sh
set -eu
S=rtl/conv4x4/synthesis
B=conv-bsh16-i60-h16-t14-o16-m07-stream14-prefetch24-rowconst7-subexpression-round-column-frac0-extra0-nbits16
M25=conv-bsh16-i60-h16-t14-o16-m25-2state-prefetch24-rowconst7-subexpression-round-column-frac0-extra0-nbits16
for load in cin3-cout12 cin16-cout16-l10c1; do
  for var in m25 m28; do
    s=$B-$load
    if [ $var = m25 ]; then d=$M25-$load; n=25; else d=$B-mult28-$load; n=28; fi
    git ls-files "$S/$s" |
      grep -v -E '/logical/results|/logical/reports|genus\.(log|cmd)|xrun\.log|power_evaluation|execution_time|access_counts' |
    while read -r f; do r=${f#"$S/$s/"}; mkdir -p "$S/$d/$(dirname "$r")"; cp "$f" "$S/$d/$r"; done
    grep -rl "$s" "$S/$d" | xargs -r sed -i "s/$s/$d/g"
    sed -i "s/^NUM_MULT=.*/NUM_MULT=$n/" "$S/$d/top-parameters.txt"
    sed -i "s/ASIC_NUM_MULT=.*/ASIC_NUM_MULT=$n/" "$S/$d/list-define.txt"
    [ $var = m25 ] && sed -i 's/m07-stream14-prefetch24/m25-2state-prefetch24/' "$S/$d/list-file.txt" "$S/$d/rtl-top-file.txt"
  done
done
