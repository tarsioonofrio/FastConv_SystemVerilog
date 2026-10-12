# ASIC synthesis configuration: WPN16 std-column, 32 MACs

RTL: `rtl/conv4x4/conv-wpn16-std-column.sv`.

Workload/package: Cin=3, Cout=12, NBITS=16, integer pretransformed weights;
see `rtl/conv4x4/data/wpn16/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv`.

This directory is currently configured for logical synthesis. Gate-level
simulation and power scripts are intentionally not copied until their
testbench/provenance are validated for this std-column RTL.
