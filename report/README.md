# Consolidated Reports

This folder contains the current aggregated reports generated after the synthesis and annotated-simulation runs of the FastConv architecture. The collector discovers each project below `rtl/conv*/synthesis/`, so configurations with the same `tcn`/`ifn` suffix remain distinguishable by their RTL architecture prefix.

The reports include information such as:

- Area utilization and cell counts from the synthesis results.
- Timing reports capturing critical path delays and slack for different corner cases.
- Power consumption estimates from the power analysis synthesis runs.
- Performance benchmarking including latency and throughput data.
- Comparison tables across different kernel sizes, channel counts, and quantization schemes.

These consolidated reports facilitate design space exploration and decision-making by providing an accessible overview of trade-offs between area, power, and performance.

Use `scripts/report-all.py` to generate the report CSVs in one run. The current tables remain at this directory level; chapter-7 derived tables are written to `report/chapter7/`. The CSV files can be imported into spreadsheet software or used as input to further automated analysis tools.

Reports generated before the RTL-local synthesis layout was adopted are kept
unchanged under `report/legacy/`. They are historical snapshots and are not
mixed with the current tables.

Keep this folder updated with the latest aggregated metrics to maintain a comprehensive history of implemented experiments and synthesis configurations.
