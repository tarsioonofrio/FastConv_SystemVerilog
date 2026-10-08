# ASIC workload: Cin=3, Cout=12

Source configuration: `rtl/conv2x2/synthesis/conv-i24-h13-t08-o4-m04-stream08-prefetch8-rowconst4-trunc-column-nbits16`.

Workload package: `rtl/conv2x2/data/tcn4/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv`.

Top overrides: `NBITS=16`, `N_CHANNEL_IN=3`, `N_CHANNEL_OUT=12`.

This is a separate configuration so the original Cin=3, Cout=3 netlist, simulation, and power evidence remain unchanged. Run the full flow with `make flow ARCH=conv2x2 CONFIG=conv-i24-h13-t08-o4-m04-stream08-prefetch8-rowconst4-trunc-column-nbits16-cin3-cout12` inside tmux.
