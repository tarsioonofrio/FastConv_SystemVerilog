# TCN16 Cin=3, Cout=16 dataset

Canonical workload: 32x32 input, Cin=3, Cout=16, 3x3 kernel, seed=0, NBITS=16, QUANT_BITS=8. The TCN16 weight transform uses scale 576 with arithmetic-floor truncation and no fractional-weight extension (`weight_transform_frac_bits=0`).

`pack_data.sv` is the SystemVerilog package for simulation. The package was generated with the `fast-convolution-rtl` normal-distribution flow and its default TCN16 configuration. `sim.txt` records the library summary; `generation.json` records workload parameters, generator revision, R2, and the package SHA-256.

Library-reported R2 against the canonical floating-point output: 0.5122033364880372.
