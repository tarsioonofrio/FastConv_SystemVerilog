# ASIC workload: Cin=16, Cout=16, real ResNet-18 data

Copied from `conv-bsn16-i60-h16-t14-o16-m07-stream14-prefetch24-transformed-round-column-frac0-extra0-nbits16-cin3-cout12` (same RTL and scripts). Only the channel counts and the workload package change.

Workload package: `rtl/conv4x4/data/bsn16/sim/sim-032-16-16-l10c1-trunc-frac0-extra0-round-nbits16/pack_data.sv`: ResNet-18 `layer1.0.conv1`, image 0 of the
precision pilot (`fast-conv/frentes/precisao-quantizada/piloto/acts.npz`), first 16 input and 16 output
channels, 32x32 crop with the layer padding, scaled by the maximum to the `sim-032-3-12-normal` range and
quantized in Q8; golden from `gen_real_workload.py` (fast-convolution-rtl b10428b core).

Top overrides: `N_CHANNEL_IN=16`, `N_CHANNEL_OUT=16` (others as in the source configuration).
