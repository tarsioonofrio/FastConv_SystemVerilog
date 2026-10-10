# ASIC workload: Cin=3, Cout=12

Source RTL: `rtl/conv4x4/conv-tcn16-i60-h15-t12-o16-m06-stream12-prefetch24-pretransformed-frac6-column.sv`.

Workload package: `rtl/conv4x4/data/tcn16/sim/sim-032-3-12-normal-trunc-frac6-nbits20/pack_data.sv`.

Top overrides: `NBITS=20`, `N_CHANNEL_IN=3`, `N_CHANNEL_OUT=12`.

This is the pretransformed-weight fractional-six-bit variant. It is kept separate from the integer pretransformed and rowconst frac6 families so each result has matching RTL and package provenance. Run the full flow inside tmux using the configuration directory basename.
