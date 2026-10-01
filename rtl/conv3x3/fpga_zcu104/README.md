# FPGA campaigns for Conv3x3

This directory holds the ZCU104/XCZU7EV FPGA configuration, per-algorithm
manifests, entry point, and campaign evidence for the Conv3x3 streaming-column
cores. The implementation scripts and testbench are shared from
`rtl/stream-column/fpga_zcu104/` so Conv2x2, Conv3x3, and Conv4x4 use the same
Vivado/Xcelium methodology.

Supported manifests:

| ID | Algorithm | RTL source |
| --- | --- | --- |
| `ifn9` | IFN9, 6 MACs | `conv-ifn9-i40-h15-t12-o9-m06-stream12-prefetch15-rowconst6-trunc-column.sv` |
| `ifn9_m12` | IFN9, 12 MACs | `conv-ifn9-i40-h15-t12-o9-m12-stream12-prefetch15-rowconst6-trunc-column.sv` |
| `ifn9_m18` | IFN9, 18 MACs | `conv-ifn9-i40-h15-t12-o9-m18-stream12-prefetch15-rowconst6-trunc-column.sv` |
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
  /sim/tarsio/reports-conv3x3-<commit> ifn9 tcn9 ifn9_m12 ifn9_m18
```

The campaign uses the local manifests and constraints in this directory while
calling the shared implementation engine. Set
`STREAM_COLUMN_FPGA_IMPL_FLOW=explore_postroute_physopt` to use the same
implementation directives as the WPN16 Explore experiment:
`place_design -directive Explore`, `phys_opt_design -directive Explore`,
`route_design -directive Explore`, then a second
`phys_opt_design -directive Explore` after route. For example:

```bash
STREAM_COLUMN_FPGA_IMPL_FLOW=explore_postroute_physopt \
  rtl/conv3x3/fpga_zcu104/scripts/run_campaign.sh \
  /sim/tarsio/reports-conv3x3-ifn9-explore-<commit> ifn9 ifn9_m12 ifn9_m18
```

IFN9 m12 and m18 are generated from
the same canonical `build.json`; they evaluate two and three adjacent
Hadamard rows per cycle, respectively. The IFN9 constant weight-transform
module carries `use_dsp = "no"`, matching the Conv4x4 TCN16 FPGA mapping
directive so DSP resources remain available to the MAC lanes.
