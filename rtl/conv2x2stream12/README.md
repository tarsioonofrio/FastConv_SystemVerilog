# FastConv 2x2 streaming controller - 12 register words

This directory contains the dedicated streaming variant of the F(2x2, 3x3)
controller. The number in the directory name is the number of 20-bit
transform-domain register words (`r_d_row + r_s_row + r_out_acc`). The
baseline implementation in `rtl/conv2x2` remains unchanged.

The streaming RTL and inverse-row matrices are local to this directory. The
generated data, parameters, multiplier muxes, memories and CSA library are
reused from the baseline tree through the relative paths in
`sim-streaming.tcl`.

## Verification

Run the complete ModelSim/Questa regression with:

```bash
fish rtl/conv2x2stream12/test-streaming.fish
```

The row-level unit test is in `streaming_row_testbench.sv` and compares the
incremental inverse against the full `Inverse` reference.
