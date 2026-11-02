# ASIC workload: ResNet-18 l41c1 at full size (7×7 with padding, output 5×5), Cin=16, Cout=16, NBITS=16, F=0, G=0, nearest rounding

Source RTL: `rtl/conv4x4/conv-bsn16-i60-h16-t14-o16-m07-stream14-prefetch24-rowconst7-round-column.sv`.

Workload package: `rtl/conv4x4/data/bsn16/sim/sim-007-16-16-l41c1-trunc-frac0-extra0-round-nbits16/pack_data.sv` (fast-conv hub, `frentes/precisao-quantizada/piloto/gen_real_workload.py --alg bsn16 --nbits 16 --side 0`: channel crop 16 × 16 of the layer, scaled by the maximum to the ISCAS 2027 dataset range, Q8).

Top overrides: `NUM_MULT=7`, `NBITS=16`, `N_CHANNEL_IN=16`, `N_CHANNEL_OUT=16`, `WEIGHT_FRAC_BITS=0`, `EXTRA_FRAC_BITS=0`, `ROUND=1`, `FEAT_INPUT_SIZE=7`, `FEAT_INPUT_WIDTH=7`.

Copied from `conv-bsn16-i60-h16-t14-o16-m07-stream14-prefetch24-rowconst7-round-column-frac0-extra0-nbits16-cin16-cout16-l10c1` (layer sweep, `prep_camadas.py`); only the workload and the image size differ.
