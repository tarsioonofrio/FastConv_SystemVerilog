# ASIC synthesis configuration: TCN16 std-column, 18 MACs

RTL: `rtl/conv4x4/conv-tcn16-std-column.sv`.

Workload/package: Cin=3, Cout=12, NBITS=20, six fractional weight bits; see
`rtl/conv4x4/data/tcn16/sim/sim-032-3-12-normal-trunc-frac6-nbits20/pack_data.sv`.

This directory is currently configured for logical synthesis. Gate-level
simulation and power scripts are intentionally not copied until their
testbench/provenance are validated for this std-column RTL.
