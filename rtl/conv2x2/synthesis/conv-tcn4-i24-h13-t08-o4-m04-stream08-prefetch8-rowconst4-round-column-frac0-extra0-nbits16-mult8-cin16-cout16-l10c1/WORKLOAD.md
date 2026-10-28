# ASIC workload: Cin=16, Cout=16, NBITS=16, F=0, G=0, nearest rounding

Source RTL: `rtl/conv2x2/conv-tcn4-i24-h13-t08-o4-m04-stream08-prefetch8-rowconst4-round-column.sv` with `ROUND=1`, `WEIGHT_FRAC_BITS=0`, `EXTRA_FRAC_BITS=0`, `ROUND=1`.

Workload package: `rtl/conv2x2/data/tcn4/sim/sim-032-16-16-l10c1-trunc-frac0-extra0-round-nbits16/pack_data.sv`
(fast-convolution-rtl `--rounding nearest`; transformed weights keep 0 fractional bits and
0 deferred bits are removed by the final output shift).

Top overrides: `NUM_MULT=4`, `NBITS=16`, `N_CHANNEL_IN=16`, `N_CHANNEL_OUT=16`,
`WEIGHT_FRAC_BITS=0`, `EXTRA_FRAC_BITS=0`, `ROUND=1`.

This is a separate configuration so the original netlist, simulation and power evidence remain
unchanged. Synthesis was not run for this configuration.

Throughput sweep: same RTL with `NUM_MULT=8` (Hadamard rows per cycle = NUM_MULT / HADAMARD_SIZE).
