# ASIC workload: Cin=3, Cout=12, product rounding

Source RTL: `rtl/conv4x4/conv-tcn16-i60-h27-t36-o16-m18-stream12-prefetch24-transformed-frac6-column.sv`
with `-define PRODUCT_ROUND` (each wide product gets half an LSB added before the `QUANT + 6` low bits are
dropped).

Workload package: `rtl/conv4x4/data/tcn16/sim/sim-032-3-12-normal-trunc-frac6-round-nbits20/pack_data.sv`
(fast-convolution-rtl `--rounding nearest`: transformed weights and products rounded).

Top overrides: `NBITS=20`, `N_CHANNEL_IN=3`, `N_CHANNEL_OUT=12`.

Same flow, constraints and scripts as
`conv-tcn16-i60-h27-t36-o16-m18-stream12-prefetch24-transformed-frac6-column-cin3-cout12` (the floor baseline);
only the define and the workload package differ. Run the full flow inside tmux using the configuration directory
basename.
