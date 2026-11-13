#!/usr/bin/env bash
# Refaz em pasta temporária tudo o que o trn16 gera sem ferramentas EDA e compara com o que está versionado. Não altera a
# árvore, exceto o golden real, que é reescrito no lugar e conferido com git. Rode no tmux, na raiz do FastConv_SystemVerilog:
#   bash rtl/conv4x4/data/trn16/reproduz.sh
set -u
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1
R=$PWD; HUB=$(cd ../.. && pwd)
FC=$HUB/submodules/fast-convolution-rtl/.venv/bin
PY=$HUB/frentes/precisao-quantizada/piloto/.venv/bin/python
D=$R/rtl/conv4x4/data/trn16; L=$R/rtl/conv4x4
N=conv-trn16-i60-h17-t16-o16-m08-stream16-prefetch24-rowconst8
W=conv-wpn16-i60-h17-t16-o16-m08-stream16-prefetch24-rowconst8-round-column.sv
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
falhas=0
compara() { if cmp -s "$1" "$2"; then echo "igual     $3"; else echo "DIFERENTE $3"; falhas=$((falhas+1)); fi; }

# 1. matrizes -> build, CSA e SV
mkdir "$T/data"; cd "$T/data" || exit 1
"$FC/fast-conv" init 2d -o 4 -w 3 > /dev/null
"$FC/fast-conv" quant shift -b 8 > /dev/null
cp "$D/make_custom_build.py" .
"$FC/python" make_custom_build.py > /dev/null
cp config/gen.json "$T/gen.keep"
echo '{"generator": "tolimlin_4x3"}' > config/gen.json   # o CLI só aceita nomes de gerador conhecidos
"$FC/fast-conv" -p . build 2d bind nest > /dev/null
cp "$T/gen.keep" config/gen.json
for f in config/build.json config/gen.json sv/pack_param.sv sv/mux_mult_08.sv build/bind-nest/csa/c1p.txt; do compara "$f" "$D/$f" "$f"; done

# 2. RTL
cd "$L" || exit 1
"$PY" ../stream-column/gen_stream_column.py "$T/data/config/build.json" trn16 "$T/gen.sv" 8 4 > /dev/null
"$PY" "$D/derive_rtl.py" "$W" "$T/gen.sv" "$T/$N-round-column.sv"
"$PY" ../stream-column/gen_subexpression.py "$T/$N-round-column.sv" > /dev/null
compara "$T/$N-round-column.sv" "$N-round-column.sv" "RTL rowconst"
compara "$T/$N-subexpression-round-column.sv" "$N-subexpression-round-column.sv" "RTL subexpression"

# 3. configs ASIC
cd "$R" || exit 1
bash "$D/derive_configs.sh" "$T/cfg"
ruins=$(cd "$T/cfg" && find . -type f | while read -r f; do cmp -s "$f" "$L/synthesis/$f" || echo "$f"; done | wc -l)
total=$(find "$T/cfg" -type f | wc -l)
echo "configs: $total arquivos, $ruins diferentes"; falhas=$((falhas+ruins))

# 4. goldens
cd "$T/data" || exit 1
P=sim-032-3-12-normal-trunc-frac0-extra0-round-nbits16
"$FC/fast-conv" -p . sim normal --image-side 32 -i 3 -o 12 -d 0 --truncated-weight-transform --rounding nearest \
  --weight-frac-bits 0 --extra-frac-bits 0 --nbits 16 > /dev/null
compara sim/sim/pack_data.sv "$D/sim/$P/pack_data.sv" "golden aleatório (pack_data.sv)"
cd "$HUB/frentes/precisao-quantizada/piloto" || exit 1
"$FC/python" gen_real_workload.py --alg trn16 --nbits 16 --cin 16 --cout 16 > /dev/null
cd "$R" || exit 1
if git diff --quiet -- rtl/conv4x4/data/trn16/sim; then echo "igual     golden real"; else echo "DIFERENTE golden real"; falhas=$((falhas+1)); fi

echo "FALHAS: $falhas"; exit "$falhas"
