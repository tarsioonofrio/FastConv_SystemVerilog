# Consolidated Reports

This folder contains the current aggregated reports generated after the synthesis and annotated-simulation runs of the FastConv architecture. The collector discovers each project below `rtl/conv*/synthesis/`, so configurations with the same `tcn`/`ifn` suffix remain distinguishable by their RTL architecture prefix.

The reports include information such as:

- Area utilization and cell counts from the synthesis results.
- Timing reports capturing critical path delays and slack for different corner cases.
- Power consumption estimates from the power analysis synthesis runs.
- Performance benchmarking including latency and throughput data.
- Comparison tables across different kernel sizes, channel counts, and quantization schemes.

The active filenames are intentionally short and scope-neutral:

- `time.csv`, `logical.csv`, `power.csv`, `merged.csv`: measured synthesis and simulation data.
- `timing-summary.csv`, `area-hierarchy.csv`, `power-breakdown.csv`: timing, area hierarchy, and power-category views.
- `register-budget.csv`: RTL-derived register-word accounting. The `h_register_words` column counts only `r_input_weight`; `t_register_words` counts registered transform/inverse banks (`r_conv_temp`, `r_transform_row`, and `r_inverse_row`). Combinational (`w_*`) vectors and control registers are excluded. `mac_lanes` reports the physical MAC lanes separately and is not counted as storage. Current Winograd input tiles are 4x4, 5x5, and 6x6 for 2x2, 3x3, and 4x4 kernels.
- `throughput.csv`, `energy-per-op.csv`, `mac-scaling.csv`, `pareto.csv`: normalized performance, energy, scaling, and Pareto views.
- `flow-status.csv`, `functional-quality.csv`: artifact-completeness and functional-quality status.
- `report.md`: Markdown rendering of all CSV tables in the current scope.

These consolidated reports facilitate design space exploration and decision-making by providing an accessible overview of trade-offs between area, power, and performance.

Use `scripts/report-all.py` to generate the report CSVs in one run. The
collector considers only `rtl/conv*/synthesis/` and therefore writes no
`sys-*` tables. The global tables remain at this directory level and a
complete Markdown index is written to `report/report.md`. In addition, each
architecture receives its own scoped report in `rtl/conv*/report/` with a
local `report.md`.

The old `conv-*`, `conv-report-*`, distance-normalization, and TC9 exports are
not generated anymore. Historical copies, including their original names, are
preserved only under `report/legacy/`.

Ratios against a naive design are intentionally opt-in. Pass
`--naive-synthesis-dir PATH` to `scripts/report-all.py`; the result is written
as a separate `ratio-naive.csv` and is not mixed into the convolution
area, power, timing, or merged tables.

Reports generated before the RTL-local synthesis layout was adopted are kept
unchanged under `report/legacy/`. They are historical snapshots and are not
mixed with the current tables.

Keep this folder updated with the latest aggregated metrics to maintain a comprehensive history of implemented experiments and synthesis configurations.
