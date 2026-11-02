# ASIC workload: ResNet-18 l10c1 at full size (42×42 with padding, output 40×40), Cin=16, Cout=16, NBITS=16, F=0, G=0, nearest rounding

Source RTL: `rtl/conv4x4/conv-wpn16-i60-h17-t16-o16-m08-stream16-prefetch24-rowconst8-round-column.sv`.

Workload package: `rtl/conv4x4/data/wpn16/sim/sim-042-16-16-l10c1-trunc-frac0-extra0-round-nbits16/pack_data.sv` (fast-conv hub, `frentes/precisao-quantizada/piloto/gen_real_workload.py --alg wpn16 --nbits 16 --side 0`: channel crop 16 × 16 of the layer, scaled by the maximum to the ISCAS 2027 dataset range, Q8).

Top overrides: `NUM_MULT=32`, `NBITS=16`, `N_CHANNEL_IN=16`, `N_CHANNEL_OUT=16`, `WEIGHT_FRAC_BITS=0`, `EXTRA_FRAC_BITS=0`, `ROUND=1`, `FEAT_INPUT_SIZE=42`, `FEAT_INPUT_WIDTH=42`.

Copied from `conv-wpn16-i60-h17-t16-o16-m08-stream16-prefetch24-rowconst8-round-column-frac0-extra0-nbits16-mult32-cin16-cout16-l10c1` (layer sweep, `prep_camadas.py`); only the workload and the image size differ.
