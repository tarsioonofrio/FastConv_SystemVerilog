# ASIC workload: Cin=3, Cout=12, NBITS=20, F=4, G=4, nearest rounding

Source RTL: `rtl/conv4x4/conv-bsn16-i60-h16-t14-o16-m07-stream14-prefetch24-rowconst7-round-column.sv` with `ROUND=1`, `WEIGHT_FRAC_BITS=4`, `EXTRA_FRAC_BITS=4`, `ROUND=1`.

Workload package: `rtl/conv4x4/data/bsn16/sim/sim-032-3-12-normal-trunc-frac4-extra4-round-nbits20/pack_data.sv`
(fast-convolution-rtl `--rounding nearest`; transformed weights keep 4 fractional bits and
4 deferred bits are removed by the final output shift).

Top overrides: `NUM_MULT=7`, `NBITS=20`, `N_CHANNEL_IN=3`, `N_CHANNEL_OUT=12`,
`WEIGHT_FRAC_BITS=4`, `EXTRA_FRAC_BITS=4`, `ROUND=1`.

This is a separate configuration so the original netlist, simulation and power evidence remain
unchanged. Synthesis was not run for this configuration.
