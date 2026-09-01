# FastConv 3x3 streaming controller - 21 register words

This directory contains the dedicated streaming variant of the IF3x3
controller. The number in the directory name is the number of 20-bit
transform-domain register words (`r_transform_row + r_inverse_row + r_output_accumulator`). The
baseline implementation in `rtl/conv3x3` remains unchanged.

The streaming RTL and inverse-row matrices are local to this directory. The
generated data, parameters, multiplier muxes, memories and CSA library are
reused from the baseline tree through the relative paths in
`sim-streaming.tcl`.

## Verification

Run the complete ModelSim/Questa regression with:

```bash
fish rtl/conv3x3stream21/test-streaming.fish
```

The row-level unit test is in `streaming_row_testbench.sv` and compares the
incremental inverse against the full `Inverse` reference.
