# FastConv 2x2 controller

This folder contains the F(2x2, 3x3) FastConv controller. Each input window is
4x4, the Winograd transform domain is 4x4, and the inverse transform emits a
2x2 output tile. The controller keeps the same external memory contract as the
3x3 implementation:

- `p_input_addr` reads feature-map samples and transformed kernel weights from
  the shared input ROM;
- `p_output_addr`, `p_output_wr` and `p_output_data_write` accumulate tiles in
  the output RAM;
- `p_start` starts the traversal and `p_end` marks the final output write.

The 4x4 input bank reads four complete rows (`READ_IN_10A`, `READ_IN_10B`,
`READ_IN_8C`, `READ_IN_8D`) in row-major order. The tile base advances by the
2-pixel stride in the input map, while the normal-form package layout is
addressed explicitly (`header -> transformed weights -> feature maps`). The
output stream emits the four values of each 2x2 tile with incremental offsets;
no lookup table is needed.

The transform and inverse matrices are in
`mult-matrices/tcn4/mult_matrices.sv`; the serial multiplier choices are in
`mux-mult/tcn4/`; generated test data and parameters are in `data/tcn4/` and
`pack-param/tcn4/`.

## Verification

The focused smoke test can be run with Verilator:

```bash
make -C rtl/conv2x2 run
```

The ModelSim/Questa flow is the project-standard wrapper:

```bash
fish rtl/conv2x2/test.fish
```

The testbench checks completion, output address bounds, the expected number of
accumulation writes (`N_CHANNEL_IN * N_CHANNEL_OUT * 30 * 30`) and every value
against `const_feat_out` from the selected generated package. It also produces
`dump.vcd` for waveform inspection.
