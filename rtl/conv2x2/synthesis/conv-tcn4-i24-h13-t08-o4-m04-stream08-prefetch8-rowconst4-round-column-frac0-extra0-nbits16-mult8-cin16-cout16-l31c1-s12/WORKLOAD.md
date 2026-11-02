# ASIC workload: ResNet-18 l31c1 at full size (12×12 with padding, output 10×10), Cin=16, Cout=16, NBITS=16, F=0, G=0, nearest rounding

Source RTL: `rtl/conv2x2/conv-tcn4-i24-h13-t08-o4-m04-stream08-prefetch8-rowconst4-round-column.sv`.

Workload package: `rtl/conv2x2/data/tcn4/sim/sim-012-16-16-l31c1-trunc-frac0-extra0-round-nbits16/pack_data.sv` (fast-conv hub, `frentes/precisao-quantizada/piloto/gen_real_workload.py --alg tcn4 --nbits 16 --side 0`: channel crop 16 × 16 of the layer, scaled by the maximum to the ISCAS 2027 dataset range, Q8).

Top overrides: `NUM_MULT=8`, `NBITS=16`, `N_CHANNEL_IN=16`, `N_CHANNEL_OUT=16`, `WEIGHT_FRAC_BITS=0`, `EXTRA_FRAC_BITS=0`, `ROUND=1`, `FEAT_INPUT_SIZE=12`, `FEAT_INPUT_WIDTH=12`.

Copied from `conv-tcn4-i24-h13-t08-o4-m04-stream08-prefetch8-rowconst4-round-column-frac0-extra0-nbits16-mult8-cin16-cout16-l10c1` (layer sweep, `prep_camadas.py`); only the workload and the image size differ.
