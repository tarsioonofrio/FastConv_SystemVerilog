# TCN4 workload, NBITS=16

Canonical 32x32 workload with 3 input and 3 output channels, seed 0, and
signed 16-bit feature/weight samples. The finite-width golden data was
regenerated for 16-bit arithmetic; this is not a narrowed copy of the 20-bit
package.

Generated from the `fast-convolution-rtl` package with:

```bash
python -m fast_convolution.cli \
  -p rtl/conv2x2/data/tcn4 sim normal \
  --image-side 32 -i 3 -o 3 -d 0 --nbits 16 --no-c -n nbits16
```

SHA-256 of `pack_data.sv`:

```text
cb904b24ce196b723856fa4556757f4e51aecf3eb7fdaddd37aefd9de5fb2a67
```
