# FastConv 2x2 streaming controller - 12 register words

This directory contains the dedicated streaming variant of the F(2x2, 3x3)
controller. The number in the directory name is the number of 20-bit
streaming state words used by the original `P=4` design. The controller
accepts the valid factorizations of the 16 Hadamard products: `NUM_MULT = 2`,
`4` or `8`. `NUM_MULT=2` packs two products per row over two cycles,
`NUM_MULT=4` processes one row per cycle, and `NUM_MULT=8` processes two rows
per cycle. The baseline implementation in `rtl/conv2x2` remains unchanged.

The streaming RTL and inverse-row matrices are local to this directory. The
generated data, parameters, memories and CSA library are reused from the
baseline tree through the relative paths in
`sim-streaming.tcl`.

## Verification

Run the complete ModelSim/Questa regression with:

```bash
fish rtl/conv2x2stream4/test-streaming.fish
```

For Verilator, select the factorization at elaboration time:

```bash
make NUM_MULT=2
make NUM_MULT=4
make NUM_MULT=8
```

All three values must produce the same golden output; only the number of core
active cycles changes.

The fixed implementations are also available as separate source files in this
directory. `conv2mac.sv`, `conv4mac.sv` and `conv8mac.sv` each declare the
module `Conv` and contain only 2, 4 and 8 MAC instances respectively; their
multiplier and inverse connections are written explicitly without `generate`
or `genvar`. All three use the single shared `testbench.sv`; the `Makefile`
selects the source file for each fixed target:

```bash
make run-conv2mac
make run-conv4mac
make run-conv8mac
```

The row-level unit test is in `streaming_row_testbench.sv` and compares the
incremental inverse against the full `Inverse` reference.

## Register-reduction procedure

The step-by-step register inventory, motivation, dependency analysis and
acceptance criteria are documented in
[`REGISTER_REDUCTION.md`](REGISTER_REDUCTION.md). Apply one numbered change at
a time and rerun the corresponding verification before moving to the next
candidate.
