# ASIC workload: Cin=3, Cout=12

Source configuration: `rtl/conv4x4/synthesis/conv-wpn16-i60-h41-t64-o16-m32-stream16-prefetch24-rowconst8-trunc-column-nbits16`.

Workload package: `rtl/conv4x4/data/wpn16/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv`.

Top overrides: `NBITS=16`, `N_CHANNEL_IN=3`, `N_CHANNEL_OUT=12`.

This is a separate configuration so the original Cin=3, Cout=3 netlist, simulation, and power evidence remain unchanged. Run the full flow with `make flow ARCH=conv4x4 CONFIG=conv-wpn16-i60-h41-t64-o16-m32-stream16-prefetch24-rowconst8-trunc-column-nbits16-cin3-cout12` inside tmux.
