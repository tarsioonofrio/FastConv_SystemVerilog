# ASIC workload: Cin=3, Cout=12

Source configuration: `rtl/conv3x3/archive/synthesis/conv-ifn9-i35-h15-t12-o9-m06-stream12-prefetch10-rowconst6-trunc-column-nbits16-cin3-cout12`.

Workload package: `rtl/conv3x3/data/ifn9/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv`.

Top overrides: `NBITS=16`, `N_CHANNEL_IN=3`, `N_CHANNEL_OUT=12`.

This archived configuration preserves the Cin=3, Cout=12 run artifacts separately from the original Cin=3, Cout=3 evidence. It is no longer included in the active synthesis sweep.
