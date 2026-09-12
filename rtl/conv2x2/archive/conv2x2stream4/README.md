# FastConv 2x2 streaming controller

This directory contains the dedicated streaming variant of the F(2x2, 3x3)
controller. The number in the directory name is the number of 20-bit
streaming state words used by the original `P=4` design. The controller
currently contains the fixed 4- and 8-MAC implementations. The former 2-MAC
implementation and its dedicated synthesis configuration were removed; the
historical measurements remain recorded in `REGISTER_REDUCTION.md`. The
baseline implementation in `rtl/conv2x2` remains unchanged.

The streaming RTL and inverse-row matrices are local to this directory. The
generated data, parameters, memories and CSA library are reused from the
baseline tree through the relative paths in
`sim-streaming.tcl`.

## Verification

Run the complete ModelSim/Questa regression with:

```bash
fish rtl/conv2x2stream4/test-streaming.fish
```

For Verilator, run the two supported fixed configurations:

```bash
make run-conv4mac
make run-conv8mac
```

Both variants must produce the same golden output; only the number of core
active cycles changes.

The fixed implementations are available as separate source files in this
directory. `conv4mac.sv` and `conv8mac.sv` each declare the module `Conv` and
contain only 4 and 8 MAC instances respectively; their
multiplier and inverse connections are written explicitly without `generate`
or `genvar`. Both use the single shared `testbench.sv`; the `Makefile` selects
the source file for each fixed target:

```bash
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
