# Cin=3, Cout=12 workload package

Canonical workload: 32x32 input, Cin=3, Cout=12, 3x3 kernel, seed=0, NBITS=20, QUANT_BITS=8. The transformed weights use scale 576 with arithmetic-floor truncation. The TCN16 transformed weights retain 6 fractional bits.

`pack_data.sv` is the package consumed by Xcelium. `sim.txt` records the library simulation summary; `generation.json` stores the workload, generator revision, R2, and package SHA-256.

Library-reported R2: 0.9985242181493487.
