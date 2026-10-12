# WPN16 transformed row-stream column: Cin=3, Cout=12

RTL: `rtl/conv4x4/conv-wpn16-i60-h41-t64-o16-m32-stream16-prefetch24-transformed-rowstream-column.sv`.

Workload package: `rtl/conv4x4/data/wpn16/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv`.

Overrides: `NUM_MULT=32`, `STATE_MULT=2`, `NBITS=16`, `N_CHANNEL_IN=3`, `N_CHANNEL_OUT=12`, `QUANT=8`. WPN weights are pretransformed integer values; there is no fractional-weight extension.

RTL simulation was run with Verilator 5.050 and passed the golden checks. No Genus synthesis, Xcelium gate-level simulation, or power flow has been run for this configuration yet.
