# FastConv 3x3 streaming TC variant

This directory contains the TCN9 streaming source with a fixed five-MAC
design point:

- `conv5mac.sv`: 5 MACs, with the TC9-point transform (`HADAMARD_SIZE=5`)

The source declares the module `Conv`, and the shared `testbench.sv` is used by
the target below. The datapath consumes one five-element transform row per
Hadamard cycle and uses the TC-specific row inverse and incremental output
accumulation.

```bash
make run-conv5mac
```

The generated TCN9 data, parameters and inverse matrices are reused from
`rtl/conv3x3`.
