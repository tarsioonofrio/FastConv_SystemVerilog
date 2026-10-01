# FPGA campaigns for Conv3x3

This directory holds the ZCU104/XCZU7EV FPGA configuration, per-algorithm
manifests, entry point, and campaign evidence for the Conv3x3 streaming-column
cores. The implementation scripts and testbench are shared from
`rtl/stream-column/fpga_zcu104/` so Conv2x2, Conv3x3, and Conv4x4 use the same
Vivado/Xcelium methodology.

Supported manifests:

| ID | Algorithm | RTL source |
| --- | --- | --- |
| `ifn9` | IFN9 | `conv-ifn9-i40-h15-t12-o9-m06-stream12-prefetch15-rowconst6-trunc-column.sv` |
| `tcn9` | TCN9 | `conv-tcn9-i40-h14-t10-o9-m05-stream10-prefetch15-rowconst5-trunc-column.sv` |

The common workload packages, XDC target, and P3F procedure are documented in
the shared flow README. Results for this family belong in `reports/`; curated
tables and campaign provenance belong in `results/`. Generated DCP, SAIF,
simulator databases, and UNISIM libraries are excluded from Git.

## Run

On Paxos, first verify the exact published commit and load Vivado 2023.2 and
Xcelium 23.03. Run from a `tmux` session and keep raw outputs outside the
checkout:

```bash
rtl/conv3x3/fpga_zcu104/scripts/run_campaign.sh \
  /sim/tarsio/reports-conv3x3-<commit> ifn9 tcn9
```

The campaign uses the local manifests and constraints in this directory while
calling the shared implementation engine.
