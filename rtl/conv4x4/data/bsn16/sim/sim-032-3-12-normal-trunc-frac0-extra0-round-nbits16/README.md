# bsn16 Cin=3, Cout=12, NBITS=16, frac0/extra0

Canonical workload: 32x32 input, Cin=3, Cout=12, 3x3 kernel, seed=0,
NBITS=16, QUANT_BITS=8, weight-transform scale 16, nearest rounding.
Transformed weights keep WEIGHT_FRAC_BITS=0; the final output shift
removes EXTRA_FRAC_BITS=0.

Generated with `fast-conv sim normal --image-side 32 -i 3 -o 12 -d 0
--truncated-weight-transform --rounding nearest --weight-frac-bits 0
--extra-frac-bits 0 --nbits 16` and consumed by the matching
`rowconst7-round-column` RTL.

Library-reported R2: 0.9999686230817946.
SHA-256 of `pack_data.sv`: `e6a5a803094e96cc7b767536b59dd26813a5f94a751dbbfd5bae415d81a408ec`.
