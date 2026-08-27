# Consolidated Reports

This folder contains aggregated reports generated after the synthesis and simulation runs of the FastConv architecture. These reports are typically in CSV format and provide detailed metrics and insights regarding the different design configurations explored.

The reports include information such as:

- Area utilization and cell counts from the synthesis results.
- Timing reports capturing critical path delays and slack for different corner cases.
- Power consumption estimates from the power analysis synthesis runs.
- Performance benchmarking including latency and throughput data.
- Comparison tables across different kernel sizes, channel counts, and quantization schemes.

These consolidated reports facilitate design space exploration and decision-making by providing an accessible overview of trade-offs between area, power, and performance.

Use `scripts/report-all.py` to generate all report CSVs in one run. The CSV files can be imported into spreadsheet software or used as input to further automated analysis tools.

Keep this folder updated with the latest aggregated metrics to maintain a comprehensive history of implemented experiments and synthesis configurations.

The phase-1 streaming experiment is documented in
`fastconv_streaming_phase1.md`. It records the bit-exact regressions, cycle
counts, sequential-storage comparison, and the synthesis tools unavailable in
the current environment.
