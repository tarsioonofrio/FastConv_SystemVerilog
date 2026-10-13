# Repository organization

This document defines where current source, execution evidence, and historical
material belong. The goal is traceability, not reducing the number of files at
the cost of losing provenance.

## Canonical ownership

| Material | Canonical location | Rule |
| --- | --- | --- |
| Active convolution RTL and architecture support | `rtl/conv2x2/`, `rtl/conv3x3/`, `rtl/conv4x4/` | Keep selectable RTL sources at the architecture root. Support packages remain in the corresponding `data/`, `pack-param/`, `mux-mult/`, and `mult-matrices/` trees. |
| ASIC configuration and raw flow evidence | `rtl/conv*/synthesis/<configuration>/` | One configuration per exact RTL/workload/precision combination. Keep `list-file.txt`, defines, scripts, logs, netlists, simulation activity, and power evidence together. |
| FPGA campaign | `rtl/conv*/fpga_zcu104/` | Keep constraints, manifests, scripts, and results within the campaign tree. Do not mix FPGA outputs into ASIC `synthesis/`. |
| Consolidated comparisons | `report/` and `rtl/conv*/report/` | Generated tables only. `scripts/report.py` uses active synthesis trees by default; archived flows are opt-in. |
| Retired RTL and historical runs | `rtl/conv*/archive/` (including paired archived synthesis/data) | Preserve the RTL/config/dataset relationship. Do not move only one side of a reproducible experiment. |
| Temporary working material | `tmp/` | Preserve until owner and reproducibility role are known. It is not a default destination for final flow evidence. |
| Legacy root synthesis entry point | `synthesis/` | Compatibility templates/index only. New configurations and results go under `rtl/conv*/synthesis/`. |

## Configuration identity and dataset provenance

Each synthesis config's `list-file.txt` is the authoritative source list for
that run. It must resolve from the repository root and identify the exact top
RTL, support modules, and data package used. `list-define.txt`,
`top-module.txt`, `testbench-file.txt`, and optional `top-parameters.txt`
complete the run identity. Do not silently change a dataset behind an existing
completed configuration; create a distinct configuration when the workload or
quantization differs.

Dataset directories may be stored under `data/archive/` and still be active if
an active config explicitly references them. Conversely, an unreferenced
dataset is not safe to delete merely because it is not in a current report.
Archive or remove data only after checking all synthesis lists and simulation
entry points.

Run the read-only cross-reference check with:

```bash
make audit-layout
```

It checks referenced files and reports active root-level RTL sources with no
matching synthesis source reference. That last category is informational:
some RTL is intentionally simulation-only or has not yet had an ASIC flow.

## Reporting boundary

The generated reports in `report/` and `rtl/conv*/report/` are summaries, not
the source evidence. The per-config `logical/`, `sim/`, and `power/` outputs
remain canonical. Do not hand-edit generated CSV/Markdown tables; update their
source artifacts and regenerate with `make report` or `make metrics`.

Paper-specific tables, manuscript exports, and editorial notes should have a
clearly named publication scope (for example `reports/iscas2027/`) rather than
being mixed into the generic architecture reports. This directory should only
be introduced when there is concrete ISCAS-specific material to place there.

## Migration safeguards

1. Inventory and validate references before moving files.
2. Preserve paired RTL, dataset, scripts, and results when archiving a flow.
3. Prefer `git mv` for confirmed relocations; do not rewrite historical logs.
4. Do not delete ignored or temporary files based on size or filename alone.
5. After a migration, run `make audit-layout`, the affected simulation or flow
   checks, and `make report` if report inputs changed.
