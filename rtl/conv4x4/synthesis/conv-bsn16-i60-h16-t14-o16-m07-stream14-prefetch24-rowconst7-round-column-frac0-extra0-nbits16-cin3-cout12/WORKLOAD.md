# ASIC workload: Cin=3, Cout=12, NBITS=16, F=0, G=0, nearest rounding

Source RTL: `rtl/conv4x4/conv-bsn16-i60-h16-t14-o16-m07-stream14-prefetch24-rowconst7-round-column.sv` with `ROUND=1`, `WEIGHT_FRAC_BITS=0`, `EXTRA_FRAC_BITS=0`, `ROUND=1`.

Workload package: `rtl/conv4x4/data/bsn16/sim/sim-032-3-12-normal-trunc-frac0-extra0-round-nbits16/pack_data.sv`
(fast-convolution-rtl `--rounding nearest`; transformed weights keep 0 fractional bits and
0 deferred bits are removed by the final output shift).

Top overrides: `NUM_MULT=7`, `NBITS=16`, `N_CHANNEL_IN=3`, `N_CHANNEL_OUT=12`,
`WEIGHT_FRAC_BITS=0`, `EXTRA_FRAC_BITS=0`, `ROUND=1`.

This is a separate configuration so the original netlist, simulation and power evidence remain
unchanged. Synthesis was not run for this configuration.
