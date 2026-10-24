# bsn16 Cin=3, Cout=12, NBITS=20, frac4/extra4

Canonical workload: 32x32 input, Cin=3, Cout=12, 3x3 kernel, seed=0,
NBITS=20, QUANT_BITS=8, weight-transform scale 16, nearest rounding.
Transformed weights keep WEIGHT_FRAC_BITS=4; the final output shift
removes EXTRA_FRAC_BITS=4.

Generated with `fast-conv sim normal --image-side 32 -i 3 -o 12 -d 0
--truncated-weight-transform --rounding nearest --weight-frac-bits 4
--extra-frac-bits 4 --nbits 20` and consumed by the matching
`rowconst7-round-column` RTL.

Library-reported R2: 0.9999999417625046.
SHA-256 of `pack_data.sv`: `7124352aadae9003f0a2a85001be9b1f20cf9c0eb0f348c2fc9210f1d467b6c7`.
