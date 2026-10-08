# Cin=3, Cout=12 workload package

Canonical workload: 32x32 input, Cin=3, Cout=12, 3x3 kernel, seed=0, NBITS=16, QUANT_BITS=8. The transformed weights use scale 4 with arithmetic-floor truncation.

`pack_data.sv` is the package consumed by Xcelium. `sim.txt` records the library simulation summary; `generation.json` stores the workload, generator revision, R2, and package SHA-256.

Library-reported R2: 0.9999615852158655.
