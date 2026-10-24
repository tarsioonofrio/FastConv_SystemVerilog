# ASIC workload: Cin=3, Cout=12, NBITS=20, nearest rounding

Source configuration: `rtl/conv4x4/synthesis/conv-tcn16-i60-h15-t12-o16-m06-stream12-prefetch24-rowconst6-trunc-frac6-column-cin3-cout12`.

Source RTL: `rtl/conv4x4/conv-tcn16-i60-h15-t12-o16-m06-stream12-prefetch24-rowconst6-trunc-frac6-round-column.sv`
with `ROUND = 1` (transformed-weight division and wide products round to nearest).

Workload package: `rtl/conv4x4/data/tcn16/sim/sim-032-3-12-normal-trunc-frac6-round-nbits20/pack_data.sv`.

Top overrides: `NUM_MULT=6`, `NBITS=20`, `N_CHANNEL_IN=3`, `N_CHANNEL_OUT=12`.

This is a separate configuration so the original m06 rowconst floor configuration, netlist,
simulation, and power evidence remain unchanged. Run the full flow with
`make flow ARCH=conv4x4 CONFIG=conv-tcn16-i60-h15-t12-o16-m06-stream12-prefetch24-rowconst6-trunc-frac6-round-column-nbits20-cin3-cout12`
inside tmux.
