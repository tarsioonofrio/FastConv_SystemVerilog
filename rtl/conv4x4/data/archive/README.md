# Archived simulation datasets

This directory stores workloads that are not selected by the current default
simulation or active synthesis configurations. They are retained for historical
reproduction and are excluded from the active dataset-metrics scan, which only
walks `data/<algorithm>/sim/sim-032-*`.

Archived workloads are grouped by algorithm under
`<algorithm>/sim/<dataset>/`. Their contents are kept unchanged.

| Algorithm | Archived dataset | Reason |
| --- | --- | --- |
| `tcn16` | `sim-032-1-1-normal`, `sim-032-1-1-seq` | Alternate single-channel workloads; not used by the current 32x32, 3-channel benchmark. |
| `tcn16` | `sim-032-3-3-normal`, `sim-032-3-3-normal-trunc`, `sim-032-3-3-normal-trunc-frac6-nbits20` | Not referenced by a non-archived synthesis configuration; retained for numerical and RTL comparisons. Active TCN16 synthesis manifests use the truncated 16-bit package. |
| `tcn16` | `sim-032-3-3-normal-trunc-frac8-nbits16` | Superseded fractional-precision experiment. |
| `wpn16` | `sim-032-1-1-normal`, `sim-032-1-1-seq` | Alternate single-channel workloads; not used by the current 32x32, 3-channel benchmark. |
| `wpn16` | `sim-032-3-3-normal` | Not referenced by a non-archived synthesis configuration; retained for historical comparison. Active WPN16 synthesis uses truncated packages. |
