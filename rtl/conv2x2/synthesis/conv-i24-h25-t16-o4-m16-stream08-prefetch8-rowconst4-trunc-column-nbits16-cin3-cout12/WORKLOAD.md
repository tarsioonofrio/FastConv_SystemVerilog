# ASIC workload: Cin=3, Cout=12

Source RTL: `rtl/conv2x2/conv-i24-h25-t16-o4-m16-stream08-prefetch8-rowconst4-trunc-column.sv`.

Workload package: `rtl/conv2x2/data/tcn4/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv`.

Top overrides: `NBITS=16`, `N_CHANNEL_IN=3`, `N_CHANNEL_OUT=12`.

This is the 16-MAC variant of the prefetch8 truncated column design. It uses the canonical 16-bit Cin=3, Cout=12 package and retains its ASIC results separately from the 8-MAC configuration. Run the full flow inside tmux using this configuration directory basename.
