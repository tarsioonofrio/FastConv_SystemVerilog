# ASIC workload: Cin=3, Cout=12

Source RTL: `rtl/conv4x4/conv-tcn16-i60-h27-t36-o16-m18-stream12-prefetch24-pretransformed-featurebank-column.sv`.

Workload package: `rtl/conv4x4/data/tcn16/sim/sim-032-3-12-normal-trunc-nbits20/pack_data.sv`.

Top overrides: `NBITS=20`, `N_CHANNEL_IN=3`, `N_CHANNEL_OUT=12`.

This is the integer pretransformed-weight and registered-feature-bank variant. It loads the floor-truncated scale-576 transformed weights as 20-bit integers, with no additional fractional weight bits. It computes all 36 input-feature transform values combinationally and captures them together in one cycle; an active 18-word register bank feeds each MAC batch. It contains no rowconst weight transform. This configuration is kept separate from the frac6 and online rowconst variants so each result has matching RTL and package provenance. Run the full flow inside tmux using the configuration directory basename.
