# ASIC workload: pretransformed Cin=3, Cout=12

Source RTL: `rtl/conv3x3/conv-tcn9-i40-h14-t10-o9-m05-stream10-prefetch15-pretransformed-frac6-column.sv`.

Dataset: `rtl/conv3x3/data/tcn9/sim/sim-032-3-12-normal-trunc-frac6-nbits20/pack_data.sv`.

Parameters: NBITS=20, NUM_MULT=5, Cin=3, Cout=12.

The pretransformed weights are stored after the feature maps in the canonical package. The dedicated stream-column testbench checks every logical output word against the package golden. Run logical synthesis, SDF simulation, and Joules power in tmux.
