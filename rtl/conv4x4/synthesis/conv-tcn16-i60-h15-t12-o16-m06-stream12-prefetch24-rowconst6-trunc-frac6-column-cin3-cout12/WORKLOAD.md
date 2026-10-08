# ASIC workload: Cin=3, Cout=12

Source configuration: `rtl/conv4x4/synthesis/conv-tcn16-i60-h15-t12-o16-m06-stream12-prefetch24-rowconst6-trunc-frac6-column`.

Workload package: `rtl/conv4x4/data/tcn16/sim/sim-032-3-12-normal-trunc-frac6-nbits20/pack_data.sv`.

Top overrides: `NBITS=20`, `N_CHANNEL_IN=3`, `N_CHANNEL_OUT=12`.

This is a separate configuration so the original Cin=3, Cout=3 netlist, simulation, and power evidence remain unchanged. Run the full flow with `make flow ARCH=conv4x4 CONFIG=conv-tcn16-i60-h15-t12-o16-m06-stream12-prefetch24-rowconst6-trunc-frac6-column-cin3-cout12` inside tmux.
