# Archived simulation datasets

This directory stores workloads that are not selected by the current default
simulation or active synthesis configurations. They are retained for historical
reproduction and are excluded from the active dataset-metrics scan, which only
walks `data/<algorithm>/sim/sim-032-*`.

Archived workloads are grouped by algorithm under
`<algorithm>/sim/<dataset>/`. Their contents are kept unchanged.

| Algorithm | Archived dataset | Reason |
| --- | --- | --- |
| `tcn4` | `sim-032-3-3-normal`, `sim-032-3-3-normal-exact`, `sim-032-3-3-normal-trunc`, `sim-032-3-3-normal-nbits16` | Not referenced by a non-archived synthesis configuration; retained for RTL and historical comparisons. |
| `tcn4` | `sim-032-3-3-normal-trunc-nbits16` | 16-bit package for the archived 2x2 FPGA variants; the corresponding synthesis configurations are archived as well. |
