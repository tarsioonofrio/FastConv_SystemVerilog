# wpn16 Cin=3, Cout=12, NBITS=16, frac0/extra0

Canonical workload: 32x32 input, Cin=3, Cout=12, 3x3 kernel, seed=0,
NBITS=16, QUANT_BITS=8, weight-transform scale 4, nearest rounding.
Transformed weights keep WEIGHT_FRAC_BITS=0; the final output shift
removes EXTRA_FRAC_BITS=0.

Generated with `fast-conv sim normal --image-side 32 -i 3 -o 12 -d 0
--truncated-weight-transform --rounding nearest --weight-frac-bits 0
--extra-frac-bits 0 --nbits 16` and consumed by the matching
`rowconst8-round-column` RTL.

Library-reported R2: 0.999974168096348.
SHA-256 of `pack_data.sv`: `4f014f5b591da1d9ad6b0870af51ca9897b69f65205cf06ab875182ee7a06058`.
