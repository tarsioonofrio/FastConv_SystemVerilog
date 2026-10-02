# FPGA campaigns for Conv4x4

This directory holds the ZCU104/XCZU7EV FPGA configuration, per-algorithm
manifests, entry point, and campaign evidence for the Conv4x4 streaming-column
cores. The implementation scripts and testbench are shared from
`rtl/stream-column/fpga_zcu104/` to keep the FPGA methodology identical across
the supported convolution sizes.

Supported manifests:

| ID | Algorithm/configuration | RTL source |
| --- | --- | --- |
| `tcn16` | TCN16, 6 MACs | `conv-tcn16-i60-h15-t12-o16-m06-stream12-prefetch24-rowconst6-trunc-column.sv` |
| `wpn16` | WPN16, 8 MACs | `conv-wpn16-i60-h17-t16-o16-m08-stream16-prefetch24-rowconst8-trunc-column.sv` |
| `wpn16_m16` | WPN16, 16 MACs | `conv-wpn16-i60-h25-t32-o16-m16-stream16-prefetch24-rowconst8-trunc-column.sv` |
| `wpn16_m32` | WPN16, 32 MACs | `conv-wpn16-i60-h41-t64-o16-m32-stream16-prefetch24-rowconst8-trunc-column.sv` |
| `wpn16_pipe` | WPN16, 8 MACs, registered feature-transform boundary | `conv-wpn16-pipe-i60-h17-t16-o16-m08-stream16-prefetch24-rowconst8-trunc-column.sv` |
| `wpn16_pipe_both` | WPN16, 8 MACs, registered feature- and weight-transform boundaries | same RTL, `PIPE_WEIGHT_TRANSFORM=1` |

`wpn16_pipe` is an experimental timing variant of the standard WPN16 m08
core. It registers the `MatrixC0` partial results before `MatrixC1`, adding one
cycle per spatial tile while leaving the canonical RTL and the weight transform
unchanged. The first 32-core trial at 16 bits passed functional simulation but
failed post-route timing at 317 MHz; its exact result and critical path are
preserved in [wpn16-n32-featurepipe-5dad37b9.md](results/wpn16-n32-featurepipe-5dad37b9.md).

`wpn16_pipe_both` retains that feature-transform boundary and additionally
registers the first axis of the separable weight transform before evaluating
the second axis. This preserves the full-precision numerator until the final
arithmetic shift, so it is intended to preserve the truncation contract. Its
16-bit / 32-core flow uses algorithm `wpn16_pipe_both_nbits16` in the shared
`synth_replicas.tcl` engine. The canonical 16-bit RTL golden passed, and the
32-core OOC post-route implementation passed timing at 317 MHz with WNS
`+0.043 ns`. The result, critical path, OOC clock-constraint caveat, and reports
are preserved in
[wpn16-n32-pipeboth-317mhz-94eb5f85.md](results/wpn16-n32-pipeboth-317mhz-94eb5f85.md).
This is an IP-level OOC timing result; replicated post-route functional
simulation and power analysis have not been run.

WPN16 m16 and m32 use the canonical WPN16 parameter, matrix, and workload
packages. The common workload packages, clock, and P3F procedure are documented
in the shared flow README. Raw reports go in `reports/`; curated tables and
provenance go in `results/`. DCP, SAIF, simulator databases, and compiled
UNISIM libraries are excluded from Git.

The standard WPN16 configuration is 8 MACs. To run it with the FPGA-standard
16-bit datapath, select the matching 16-bit workload pack and set both flow
overrides (the RTL source itself retains its 20-bit default):

```bash
STREAM_COLUMN_NBITS=16 \
STREAM_COLUMN_DATASET=sim-032-3-3-normal-trunc-nbits16 \
rtl/conv4x4/fpga_zcu104/scripts/run_campaign.sh \
  /sim/tarsio/reports-wpn16-nbits16-<commit> wpn16
```

## Run

On Paxos, verify the exact published commit and load Vivado 2023.2 and Xcelium
23.03. Run the full campaign from a `tmux` session with outputs outside the
checkout:

```bash
rtl/conv4x4/fpga_zcu104/scripts/run_campaign.sh \
  /sim/tarsio/reports-conv4x4-<commit> tcn16 wpn16 wpn16_m16 wpn16_m32
```

The campaign uses the local manifests and constraints in this directory while
calling the shared implementation engine.
