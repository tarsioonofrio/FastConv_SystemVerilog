#!/usr/bin/env bash
# Gera o tro16 (identidade do trn16 com sinais e ordem dos termos de sinais_ordem.py) pela receita do trn16, sem
# ferramentas EDA. Rode no tmux, na raiz do FastConv_SystemVerilog:  bash rtl/conv4x4/data/tro16/gera.sh
set -eu
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1
R=$PWD; HUB=$(cd ../.. && pwd)
FC=$HUB/submodules/fast-convolution-rtl/.venv/bin
PY=$HUB/frentes/precisao-quantizada/piloto/.venv/bin/python
D=$R/rtl/conv4x4/data/tro16; L=$R/rtl/conv4x4
N=conv-tro16-i60-h17-t16-o16-m08-stream16-prefetch24-rowconst8
W=conv-wpn16-i60-h17-t16-o16-m08-stream16-prefetch24-rowconst8-round-column.sv

# 0. identidade reescrita -> make_custom_build.py, com o do trn16 como molde (confere a identidade em frações)
python3 "$D/from_result.py" "$D/identidade.json" "$D/make_custom_build.py" manual_ternary_signorder_f4_3 \
  "Materialise the tro16 F(4,3) build (trn16 identity with term signs and order chosen by sinais_ordem.py for low
multiplier activity) from explicit matrices." "$R/rtl/conv4x4/data/trn16/make_custom_build.py"

# 1. build, CSA e SV pelo fast-conv
cd "$D"
rm -rf build clib config sv
"$FC/fast-conv" init 2d -o 4 -w 3 > /dev/null
"$FC/fast-conv" quant shift -b 8 > /dev/null
"$FC/python" make_custom_build.py > /dev/null
cp config/gen.json /tmp/tro16-gen.keep.$$
echo '{"generator": "tolimlin_4x3"}' > config/gen.json   # o CLI só aceita nomes de gerador conhecidos
"$FC/fast-conv" -p . build 2d bind nest > /dev/null
cp /tmp/tro16-gen.keep.$$ config/gen.json; rm -f /tmp/tro16-gen.keep.$$
for p in mult-matrices mux-mult pack-param; do mkdir -p "$L/$p/tro16"; done
cp sv/mult_matrices.sv sv/mult_matrices_csa.sv "$L/mult-matrices/tro16/"
cp sv/mux_mult_*.sv "$L/mux-mult/tro16/"
cp sv/pack_param.sv "$L/pack-param/tro16/"

# 2. RTL: gen_stream_column.py para as tabelas, sobre o RTL round do wpn16; subexpression
cd "$L"
"$PY" ../stream-column/gen_stream_column.py "$D/config/build.json" tro16 /tmp/tro16-gen.$$.sv 8 4 > /dev/null
"$PY" "$D/derive_rtl.py" "$W" /tmp/tro16-gen.$$.sv "$N-round-column.sv"; rm -f /tmp/tro16-gen.$$.sv
"$PY" ../stream-column/gen_subexpression.py "$N-round-column.sv" > /dev/null

# 3. configs ASIC
cd "$R"; bash "$D/derive_configs.sh"

# 4. golden da carga real (cin16-cout16-l10c1)
cd "$HUB/frentes/precisao-quantizada/piloto"
"$FC/python" gen_real_workload.py --alg tro16 --nbits 16 --cin 16 --cout 16 > /dev/null
echo "GERA OK"
