# ASIC workload: Cin=3, Cout=12

Source RTL: `rtl/conv4x4/conv-tcn16-i60-h27-t36-o16-m18-stream12-prefetch24-transformed-frac6-column.sv`.

Workload package: `rtl/conv4x4/data/tcn16/sim/sim-032-3-12-normal-trunc-frac6-nbits20/pack_data.sv`.

Top overrides: `NBITS=20`, `N_CHANNEL_IN=3`, `N_CHANNEL_OUT=12`.

This is the transformed-weight fractional-six-bit variant restored from FastConv commit `2e8a3804`. The RTL content hash is `f680e4910362f47db3a0d38929ae09ef3bfec11b`; the existing synthesis, SDF simulation, and power artifacts were produced for this source content on 2026-10-10. Run the full flow inside tmux using the configuration directory basename.
