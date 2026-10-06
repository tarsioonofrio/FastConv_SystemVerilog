# TCN9 truncated workload, NBITS=16

Canonical 32x32 workload with 3 input and 3 output channels, seed 0,
truncated weight transform, and signed 16-bit feature/weight samples. Golden
outputs were regenerated using finite-width 16-bit arithmetic.

Generated with:

```bash
python -m fast_convolution.cli \
  -p rtl/conv3x3/data/tcn9 sim normal \
  --image-side 32 -i 3 -o 3 -d 0 \
  --truncated-weight-transform --nbits 16 --no-c -n trunc-nbits16
```

SHA-256 of `pack_data.sv`:

```text
c323cedc4e8b108a865553c50447d1f402bcecae71a9e29b5cc724738fdab9ce
```
