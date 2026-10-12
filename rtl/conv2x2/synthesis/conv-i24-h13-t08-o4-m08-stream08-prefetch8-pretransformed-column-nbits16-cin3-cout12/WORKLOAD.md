# ASIC workload: pretransformed Cin=3, Cout=12

Source RTL: `rtl/conv2x2/conv-i24-h13-t08-o4-m08-stream08-prefetch8-pretransformed-column.sv`.

Dataset: `rtl/conv2x2/data/tcn4/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv`.

Parameters: NBITS=16, NUM_MULT=8, Cin=3, Cout=12.

The pretransformed weights are stored after the feature maps in the canonical package. The dedicated stream-column testbench checks every logical output word against the package golden. Run logical synthesis, SDF simulation, and Joules power in tmux.
