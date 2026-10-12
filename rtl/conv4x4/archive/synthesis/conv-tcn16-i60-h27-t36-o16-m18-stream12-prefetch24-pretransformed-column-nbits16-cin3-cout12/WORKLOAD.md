# ASIC workload: TCN16, Cin=3, Cout=12, NBITS=16

Source RTL: `rtl/conv4x4/archive/tcn16-pretransformed/conv-tcn16-i60-h27-t36-o16-m18-stream12-prefetch24-pretransformed-column.sv`.

Workload package: `rtl/conv4x4/data/tcn16/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv`.

Top overrides: `NUM_MULT=18`, `NBITS=16`, `N_CHANNEL_IN=3`, `N_CHANNEL_OUT=12`.

This is the integer pretransformed-weight variant: the package contains floor-truncated scale-576 transformed weights with zero additional fractional bits. The dataset reports library R2 = 0.5014 against the floating-point reference; this is an accuracy limitation of this 16-bit/no-frac dataset, not a claim made by the ASIC implementation flow. The gate-level flow checks the RTL against the integer package's golden values.

Keep this configuration separate from the 20-bit integer and frac6 variants. Run the complete ASIC flow inside `tmux` using this directory basename.
