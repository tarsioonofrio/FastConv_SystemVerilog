# ASIC workload: pretransformed Cin=3, Cout=12

Source RTL: `rtl/conv3x3/conv-ifn9-i40-h27-t36-o9-m18-stream12-prefetch15-pretransformed-column.sv`.

Dataset: `rtl/conv3x3/data/ifn9/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv`.

Parameters: NBITS=16, NUM_MULT=18, Cin=3, Cout=12.

The pretransformed weights are stored after the feature maps in the canonical package. The dedicated stream-column testbench checks every logical output word against the package golden. Run logical synthesis, SDF simulation, and Joules power in tmux.
