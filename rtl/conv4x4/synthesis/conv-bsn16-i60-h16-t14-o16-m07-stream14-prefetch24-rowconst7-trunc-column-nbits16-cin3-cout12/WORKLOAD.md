# ASIC workload: Cin=3, Cout=12, NBITS=16

Source configuration: `rtl/conv4x4/synthesis/conv-bsn16-i60-h16-t14-o16-m07-stream14-prefetch24-rowconst7-trunc-column-nbits16`.

Workload package: `rtl/conv4x4/data/bsn16/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv`.

Top overrides: `NUM_MULT=7`, `NBITS=16`, `N_CHANNEL_IN=3`, `N_CHANNEL_OUT=12`.

This is a separate configuration so the original bsn16 NBITS=16 netlist, simulation, and power evidence remain unchanged. Run the full flow with `make flow ARCH=conv4x4 CONFIG=conv-bsn16-i60-h16-t14-o16-m07-stream14-prefetch24-rowconst7-trunc-column-nbits16-cin3-cout12` inside tmux.
