# TCN16 truncated-weight workload with six fractional transform bits

Canonical workload: 32x32 input, Cin=3, Cout=3, seed=0, NBITS=20,
QUANT_BITS=8, and weight-transform scale 576. The transformed weights retain
six additional fractional bits after floor division by 576. The MAC discards
`QUANT_BITS + 6` product bits so the output remains in the canonical scale.

The package was generated with `data/tcn16/generate_trunc_frac8_nbits16.py`
using `NBITS=20` and `WEIGHT_FRAC_BITS=6`. It is intended for the matching
`trunc-frac6-column` RTL variants, not the unmodified TCN16 `trunc-column` RTL.

Compared with `s_default.txt`, after dequantizing `s.txt` by 2^8:

| Metric | Result |
| --- | ---: |
| Samples | 2,700 |
| MAE | 0.132176 |
| RMSE | 0.204602 |
| Maximum absolute error | 0.835101 |
| R² against canonical float output | 0.998677 |
| Library R² | 0.998684 |

This is the lowest tested fractional precision satisfying both the requested
maximum absolute error `< 1` and R² `> 0.99`: five fractional bits produced a
maximum absolute error of 1.118785.
