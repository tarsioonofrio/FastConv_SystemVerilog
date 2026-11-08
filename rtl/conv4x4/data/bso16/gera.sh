#!/usr/bin/env bash
# Gera o bso16 (identidade do bsn16 com sinais e ordem dos termos de sinais_ordem.py) pela receita do bsc16, sem ferramentas EDA.
# Rode no tmux, na raiz do FastConv_SystemVerilog:  bash rtl/conv4x4/data/bso16/gera.sh
set -eu
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1
R=$PWD; HUB=$(cd ../.. && pwd)
FC=$HUB/submodules/fast-convolution-rtl/.venv/bin
PY=$HUB/frentes/precisao-quantizada/piloto/.venv/bin/python
D=$R/rtl/conv4x4/data/bso16; L=$R/rtl/conv4x4
RES=$D/identidade.json
N=conv-bso16-i60-h16-t14-o16-m07-stream14-prefetch24-rowconst7
BSN=conv-bsn16-i60-h16-t14-o16-m07-stream14-prefetch24-rowconst7-round-column.sv

# 0. matrizes da busca -> make_custom_build.py (confere a identidade em frações)
python3 "$D/from_result.py" "$RES" "$D/make_custom_build.py" manual_bitshift_signorder_f4_3 \
  "Materialise the bso16 F(4,3) build (bsn16 identity with term signs and order chosen by
sinais_ordem.py for low multiplier activity) from explicit matrices."

# 1-2. build, CSA e SV pelo fast-conv
cd "$D"
rm -rf build clib config sv
"$FC/fast-conv" init 2d -o 4 -w 3 > /dev/null
"$FC/fast-conv" quant shift -b 8 > /dev/null
"$FC/python" make_custom_build.py > /dev/null
cp config/gen.json /tmp/bso16-gen.keep.$$
echo '{"generator": "tolimlin_4x3"}' > config/gen.json   # o CLI só aceita nomes de gerador conhecidos
"$FC/fast-conv" -p . build 2d bind nest > /dev/null
cp /tmp/bso16-gen.keep.$$ config/gen.json; rm -f /tmp/bso16-gen.keep.$$

# 3. SV gerado nas pastas do RTL
for p in mult-matrices mux-mult pack-param; do mkdir -p "$L/$p/bso16"; done
cp sv/mult_matrices.sv sv/mult_matrices_csa.sv "$L/mult-matrices/bso16/"
cp sv/mux_mult_*.sv "$L/mux-mult/bso16/"
cp sv/pack_param.sv "$L/pack-param/bso16/"

# 4-5. RTL rowconst (tabelas trocadas no bsn16) e duas passadas
cd "$L"
"$PY" "$D/derive_rtl.py" "$BSN" "$D/make_custom_build.py" "$N-round-column.sv"
"$PY" ../stream-column/gen_twopass.py "$N-round-column.sv" > /dev/null

# 6. configs ASIC
cd "$R"; bash "$D/derive_configs.sh"

# 7. goldens: aleatório (cin3-cout12) e carga real (cin16-cout16-l10c1)
cd "$D"
P=sim-032-3-12-normal-trunc-frac0-extra0-round-nbits16
rm -rf sim/sim "sim/$P"
"$FC/fast-conv" -p . sim normal --image-side 32 -i 3 -o 12 -d 0 --truncated-weight-transform --rounding nearest \
  --weight-frac-bits 0 --extra-frac-bits 0 --nbits 16 > /dev/null
mv sim/sim "sim/$P"
cd "$HUB/frentes/precisao-quantizada/piloto"
"$FC/python" gen_real_workload.py --alg bso16 --nbits 16 --cin 16 --cout 16 > /dev/null
echo "GERA OK"
