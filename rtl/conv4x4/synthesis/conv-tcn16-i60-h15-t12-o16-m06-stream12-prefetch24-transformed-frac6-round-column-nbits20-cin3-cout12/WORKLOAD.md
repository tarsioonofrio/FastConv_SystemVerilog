# ASIC workload: TCN16 m06, Cin=3, Cout=12, NBITS=20, product rounding

Source RTL: `rtl/conv4x4/conv-tcn16-i60-h27-t36-o16-m18-stream12-prefetch24-transformed-frac6-column.sv`
with `-define PRODUCT_ROUND` (each wide product gets half an LSB added before the `QUANT + 6` low bits are
dropped). The RTL is unchanged from the m18 transformed variant; only `NUM_MULT=6` and the workload
package differ.

Workload package: `rtl/conv4x4/data/tcn16/sim/sim-032-3-12-normal-trunc-frac6-round-nbits20/pack_data.sv`
(fast-convolution-rtl `--rounding nearest`: transformed weights and products rounded).

Top overrides: `NUM_MULT=6`, `NBITS=20`, `N_CHANNEL_IN=3`, `N_CHANNEL_OUT=12`.

This is a separate configuration so the original m18 netlist, simulation and power evidence remain
unchanged. Synthesis was not run for this configuration.
