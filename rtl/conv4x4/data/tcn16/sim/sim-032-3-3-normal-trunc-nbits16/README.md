# TCN16 truncated workload, NBITS=16

This package was generated from the TCN16 configuration with the canonical
32x32 image, 3 input channels, 3 output channels, seed 0, truncated weight
transform, and signed 16-bit datapath. The command used was:

```bash
python -m fast_convolution.cli \
  -p rtl/conv4x4/data/tcn16 sim normal \
  --image-side 32 -i 3 -o 3 -d 0 \
  --truncated-weight-transform --nbits 16 --no-c -n trunc-nbits16
```

The generated pack declares both `NBITS` and `WEIGHT_NBITS` as 16 and stores
the finite-width simulation's golden outputs. Do not produce this package by
only narrowing the declarations of the 20-bit pack: the 16-bit model is
recomputed with 16-bit arithmetic.

SHA-256 of `pack_data.sv`:

```text
3900f1f4da01c290e8a126103a718db29269a564aa0dfa35264159519c774363
```
