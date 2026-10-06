# IFN9 truncated workload, NBITS=16

Canonical 32x32 workload with 3 input and 3 output channels, seed 0,
truncated weight transform, and signed 16-bit feature/weight samples. Golden
outputs were regenerated using finite-width 16-bit arithmetic.

Generated with:

```bash
python -m fast_convolution.cli \
  -p rtl/conv3x3/data/ifn9 sim normal \
  --image-side 32 -i 3 -o 3 -d 0 \
  --truncated-weight-transform --nbits 16 --no-c -n trunc-nbits16
```

SHA-256 of `pack_data.sv`:

```text
3b75d8c27fbe4e3f82bc11d3285b67bb85fcb0501237bd06c90306f72b153421
```
