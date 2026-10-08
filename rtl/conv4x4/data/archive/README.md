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
| `tcn16` | `sim-032-3-3-normal`, `sim-032-3-3-normal-trunc` | Not referenced by a non-archived synthesis configuration; retained for numerical and RTL comparisons. |
| `tcn16` | `sim-032-3-3-normal-trunc-nbits16` | Low-accuracy 16-bit truncated package (R² ≈ 0.494 against the canonical float output); retained because the `tcn16-std-nbits16` synthesis manifests still reference it. Excluded from the selected dataset-quality report. |
| `tcn16` | `sim-032-3-3-normal-trunc-frac8-nbits16` | Superseded fractional-precision experiment. |
| `wpn16` | `sim-032-1-1-normal`, `sim-032-1-1-seq` | Alternate single-channel workloads; not used by the current 32x32, 3-channel benchmark. |
| `wpn16` | `sim-032-3-3-normal` | Not referenced by a non-archived synthesis configuration; retained for historical comparison. Active WPN16 synthesis uses truncated packages. |
