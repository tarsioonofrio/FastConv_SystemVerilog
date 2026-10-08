# TCN16 fractional truncated-weight workload, NBITS=16

Experimental package using the canonical 32x32 workload, 3 input channels,
3 output channels, and seed 0. Feature and raw spatial-weight memories remain
16-bit Q8. The transformed-weight representation retains eight additional
binary fractional bits.

For each exact transformed-weight numerator `s` and common scale 576, the
arithmetic contract is:

```text
weight_q = floor(s * 2^8 / 576)
```

The transformed weight is carried as a signed 24-bit value. The MAC discards
`QUANT_BITS + WEIGHT_TRANSFORM_FRAC_BITS` low product bits (16 total) and wraps
its result to the existing 16-bit datapath. Feature transforms, Hadamard
products, inverse transforms, and output accumulation retain their original
16-bit modular behavior. This package and its matching `trunc-frac8` RTL are
experimental; they do not replace the canonical truncated baseline.

The package hash is:

```text
7f3d5b9247f9c652c504aa2bd1e4872d5753e1f15758037eeb05983e4e5e5b84
```

Regenerate the simulation package from this repository root with the same
`fast-convolution-rtl` source revision (`5c021aabc87136efb03a329d86f3e833af1abd42`):

```bash
PYTHONPATH=/home/tarsio/gaph/fast-convolution-rtl/src \
  /home/tarsio/gaph/fast-convolution-rtl/.venv/bin/python \
  rtl/conv4x4/data/tcn16/generate_trunc_frac8_nbits16.py
```

The generator reuses the baseline configuration and deterministic seed. The
input, raw-weight, and floating-point reference files are identical to the
canonical 16-bit truncated package; only the fixed-point fast-path output and
its `const_feat_out` golden use the extra fractional weight precision.

The library R2 uses its quantized reference. MAE/RMSE/max-error comparisons in
the project report use `s_default.txt` as the floating-point golden and
`s.txt / 256` as the fixed-point result; do not mix the two R2 definitions.

On that floating-point comparison, the original 16-bit truncated package has
MAE 1.856319, RMSE 3.988129, and maximum absolute error 96.747997. This frac8
package has MAE 0.242878, RMSE 3.491646, and maximum absolute error 117.103466.
The library R2 improves from 0.494481 to 0.612551. Thus average error and RMSE
improve substantially, but the worst outlier becomes larger; the remaining
outlier is consistent with the unchanged 16-bit feature-transform wrapping.
