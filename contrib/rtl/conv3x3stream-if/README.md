# FastConv 3x3 streaming IF variants

This directory contains the IF3x3 streaming sources with fixed MAC counts:

- `conv6mac.sv`: 6 MACs
- `conv12mac.sv`: 12 MACs
- `conv18mac.sv`: 18 MACs

Every source declares the module `Conv`, so the shared `testbench.sv` can be
used by all three targets. The `Makefile` selects the source file and passes
the corresponding multiply/state parameters.

The 6-MAC source consumes one IF3x3 transform row per Hadamard cycle. The
12-MAC and 18-MAC sources consume two and three rows per cycle, respectively,
and rotate the weight bank by the packed row count.

```bash
make run-conv6mac
make run-conv12mac
make run-conv18mac
```

The generated IFN9 data and IF inverse matrices are reused from `rtl/conv3x3`.
