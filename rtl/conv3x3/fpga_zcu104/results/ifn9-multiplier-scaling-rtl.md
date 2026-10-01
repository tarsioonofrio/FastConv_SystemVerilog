# IFN9 multiplier scaling: RTL validation

This is a local Verilator functional-validation record, not an FPGA
implementation or power result. All variants use the canonical IFN9
`sim-032-3-3-normal-trunc` package and the shared column-interface testbench.

| MAC lanes | Hadamard rows/cycle | Cycles to `p_end` | Inverse tiles | Valid writes | Golden mismatches |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 6 | 1 | 11,046 | 900 | 8,100 | 0 |
| 12 | 2 | 8,346 | 900 | 8,100 | 0 |
| 18 | 3 | 7,446 | 900 | 8,100 | 0 |

Commands, run from `rtl/conv3x3/`:

```bash
make run-stream-column CONFIG=ifn9 NUM_MULT=6
make run-stream-column CONFIG=ifn9 NUM_MULT=12
make run-stream-column CONFIG=ifn9 NUM_MULT=18
```

The top-level testbench parameter and each generated RTL source default were
checked for all three values. The Makefile uses a distinct `obj_dir` and source
selection for each MAC count so a previous binary cannot be reused silently.
Vivado synthesis, place-and-route, Xcelium post-route functional simulation,
SAIF mapping, and power have not yet been run for these three variants.
