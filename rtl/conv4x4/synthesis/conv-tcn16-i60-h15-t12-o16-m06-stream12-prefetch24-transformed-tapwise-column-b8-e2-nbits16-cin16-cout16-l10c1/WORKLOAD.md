# ASIC workload: TCN16 tap-wise, Cin=16, Cout=16, NBITS=16, b=8, e=2

Source RTL: `rtl/conv4x4/conv-tcn16-i60-h15-t12-o16-m06-stream12-prefetch24-transformed-tapwise-column.sv`
with `EXTRA_FRAC_BITS=2`, `TAP_BITS=8`, `TAP_SHIFT_V_BITS=4`,
`TAP_SHIFT_P_BITS=5` and `INPUT_TRANSFORM_BITS=18`. The 6x6 Toom-Cook transformed kernels of each kernel
are read from the package through the six-word input column port. Every
transformed position k has its own power-of-two V shift `sv[k]` and product
shift `s[k]`; the tables come from the `p_tap_shift_v`/`p_tap_shift_p` ports and
are captured on `p_start`, so the shifters stay variable in hardware. V is
requantized to 8 bits with rounding and symmetric saturation, Uq is the low
8 bits of each weight word, and the exact 16-bit product is shifted per position
and wrapped to `NBITS`. The final rounded shift of `EXTRA_FRAC_BITS` is applied
only on the last input channel write.

Workload package: `rtl/conv4x4/data/tcn16/sim/sim-032-16-16-l10c1-tapwise-b8-e2-nbits16/pack_data.sv`
(the ResNet-18 layer1.0.conv1 workload; tap-wise goldens from `gen_tapwise.py` +
`rtl_model.FixedPointConv.run_tapwise` of the precision pilot).

Top overrides: `NUM_MULT=6`, `NBITS=16`, `N_CHANNEL_IN=16`,
`N_CHANNEL_OUT=16`, `EXTRA_FRAC_BITS=2`, `ROUND=1`, `TAP_BITS=8`,
`TAP_SHIFT_V_BITS=4`, `TAP_SHIFT_P_BITS=5`,
`INPUT_TRANSFORM_BITS=18`.

Synthesis was not run for this configuration.
