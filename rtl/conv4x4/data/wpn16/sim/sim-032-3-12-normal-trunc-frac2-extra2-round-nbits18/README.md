# wpn16 Cin=3, Cout=12, NBITS=18, frac2/extra2

Canonical workload: 32x32 input, Cin=3, Cout=12, 3x3 kernel, seed=0,
NBITS=18, QUANT_BITS=8, weight-transform scale 4, nearest rounding.
Transformed weights keep WEIGHT_FRAC_BITS=2; the final output shift
removes EXTRA_FRAC_BITS=2.

Generated with `fast-conv sim normal --image-side 32 -i 3 -o 12 -d 0
--truncated-weight-transform --rounding nearest --weight-frac-bits 2
--extra-frac-bits 2 --nbits 18` and consumed by the matching
`rowconst8-round-column` RTL.

Library-reported R2: 0.9999997614484069.
SHA-256 of `pack_data.sv`: `9fe5d1fd52d983e3a2cb243c1472b6b8636f82542f0d29562c3d09165167e8bc`.
