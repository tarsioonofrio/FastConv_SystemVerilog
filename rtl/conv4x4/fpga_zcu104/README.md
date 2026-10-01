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

WPN16 m16 and m32 use the canonical WPN16 parameter, matrix, and workload
packages. The common workload packages, clock, and P3F procedure are documented
in the shared flow README. Raw reports go in `reports/`; curated tables and
provenance go in `results/`. DCP, SAIF, simulator databases, and compiled
UNISIM libraries are excluded from Git.

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
