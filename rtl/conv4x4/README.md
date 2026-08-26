# FastConv 4x4 TCN16 tile core

This folder contains the F(4x4, 3x3) TCN16 Winograd tile core. The core
accepts one 6x6 input tile and one 6x6 transformed weight tile, then emits one
4x4 output tile. The generated package uses 20-bit samples with 8 fractional
quantization bits.

The testbench follows the existing TCN16 direct-tile flow. It maps the 192
input tiles as three input-channel banks of 64 tiles, maps the 192 golden
output tiles as three output-channel banks, accumulates the three input-channel
partial tiles for every output channel, and compares the 16 accumulated values
against `const_feat_out_batch`. It also counts all 576 tile transactions and
emits `dump.vcd`.

Run the focused simulation and lint with:

```bash
make -C rtl/conv4x4 run
make -C rtl/conv4x4 lint
```

This directory does not use the 3x3/2x2 external feature-map memory protocol;
the existing TCN16 synthesis flow is a direct tile interface (`p_input`,
`p_weight`, `p_output`).
