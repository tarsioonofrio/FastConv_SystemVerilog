# Consolidated Reports

This folder contains aggregated reports generated after the synthesis and simulation runs of the FastConv architecture. These reports are typically in CSV format and provide detailed metrics and insights regarding the different design configurations explored.

The reports include information such as:

- Area utilization and cell counts from the synthesis results.
- Timing reports capturing critical path delays and slack for different corner cases.
- Power consumption estimates from the power analysis synthesis runs.
- Performance benchmarking including latency and throughput data.
- Comparison tables across different kernel sizes, channel counts, and quantization schemes.

These consolidated reports facilitate design space exploration and decision-making by providing an accessible overview of trade-offs between area, power, and performance.

Users can find scripts to generate and manipulate these reports in the `scripts/` directory. The CSV files can be imported into spreadsheet software or used as input to further automated analysis tools.

Keep this folder updated with the latest aggregated metrics to maintain a comprehensive history of implemented experiments and synthesis configurations.
