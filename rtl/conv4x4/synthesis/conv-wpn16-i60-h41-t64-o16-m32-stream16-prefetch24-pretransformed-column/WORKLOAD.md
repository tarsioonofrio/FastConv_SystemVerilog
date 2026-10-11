# ASIC workload: Cin=3, Cout=12

RTL: `rtl/conv4x4/conv-wpn16-i60-h41-t64-o16-m32-stream16-prefetch24-pretransformed-column.sv`.

Workload package: `rtl/conv4x4/data/wpn16/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv`.

Top overrides: `NBITS=16`, `N_CHANNEL_IN=3`, `N_CHANNEL_OUT=12`.
The RTL caches the package's pretransformed integer 8x8 WPN16 weight tile;
the testbench define `WPN16_PRETRANSFORMED_WEIGHTS` selects that packed region
and checks the expected number of column beats.

This configuration has its own synthesis, gate-level simulation, and power
artifacts. Run the full flow with
`make flow ARCH=conv4x4 CONFIG=conv-wpn16-i60-h41-t64-o16-m32-stream16-prefetch24-pretransformed-column`
inside tmux.
