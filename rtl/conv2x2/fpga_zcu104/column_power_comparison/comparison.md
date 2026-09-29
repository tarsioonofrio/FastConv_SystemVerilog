# FPGA scalar/column power comparison

All four implementations use the same XCZU7EV, Vivado 2023.2, 317 MHz constraint and canonical 32x32 / Cin=3 / Cout=3 / 3x3 workload. Power values are Vivado estimates, not board measurements. P0 is post-route vectorless; P3F uses post-route functional Xcelium SAIF (no SDF). The reported GOPS is computed at the 317 MHz target; rows that fail timing did not close at that frequency, so their GOPS and energy figures are constrained-point estimates, not achievable operating results.

## Scalar versus column, paired

Each cell is scalar → column, so the effect of changing only the memory interface is visible directly:

| Architecture | DSP | LUT | FF | User I/O bits | WNS @317 MHz (ns) | Active cycles | Active-job GOPS* | P0 dynamic/static/total (W) | P3F dynamic/static/total (W) | P3F SAIF mapping |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| std | 8 → 8 | 2,087 → 2,143 | 1,266 → 1,263 | 101 → 201 | 0.221 (PASS) → 0.166 (PASS) | 23,648 → 10,578 | 1.954 → 4.369 | 0.251/0.593/0.844 → 0.332/0.593/0.925 | 0.281/0.593/0.874 → 0.452/0.594/1.046 | 5442/5442 → 5680/5680 |
| prefetch8-rowconst4 | 8 → 8 | 4,503 → 4,719 | 1,244 → 1,247 | 101 → 201 | -2.322 (FAIL) → -2.242 (FAIL) | 21,865 → 10,730 | 2.114 → 4.307 | 0.137/0.592/0.729 → 0.314/0.593/0.908 | 0.246/0.593/0.839 → 0.537/0.595/1.132 | 9676/9676 → 10115/10115 |

Interpretation of the paired results:

- `std-column` reduces active cycles by 55.3% (23,648 to 10,578) and raises active-job throughput 2.24x at 317 MHz while retaining positive WNS. P3F dynamic power rises from 0.281 W to 0.452 W; the 100 additional top-level user-I/O bits account for a substantial part of that estimate.
- `prefetch8-rowconst4-column` reduces active cycles by 50.9% (21,865 to 10,730), but both prefetch8 implementations fail timing at 317 MHz. The corresponding GOPS and energy figures are only common-target comparisons, not a valid 317 MHz operating result. Its P3F dynamic power rises from 0.246 W to 0.537 W, with I/O rising from 0.118 W to 0.354 W.

Detailed per-variant values:

| Architecture pair | Interface | DSP | LUT | FF | BRAM | User I/O bits | WNS @317 MHz (ns) | Active cycles | Active-job GOPS* | P0 dyn/static/total (W) | P3F dyn/static/total (W) | P3F direct SAIF mapping |
|---|---|---:|---:|---:|---|---:|---:|---:|---:|---:|---:|---:|
| std | scalar | 8 | 2,087 | 1,266 | 0 RAMB36 + 0 RAMB18 | 101 | 0.221 (PASS) | 23,648 | 1.954 | 0.251 / 0.593 / 0.844 | 0.281 / 0.593 / 0.874 | 5442/5442 |
| std | column | 8 | 2,143 | 1,263 | 0 RAMB36 + 0 RAMB18 | 201 | 0.166 (PASS) | 10,578 | 4.369 | 0.332 / 0.593 / 0.925 | 0.452 / 0.594 / 1.046 | 5680/5680 |
| prefetch8-rowconst4 | scalar | 8 | 4,503 | 1,244 | 0 RAMB36 + 0 RAMB18 | 101 | -2.322 (FAIL) | 21,865 | 2.114 | 0.137 / 0.592 / 0.729 | 0.246 / 0.593 / 0.839 | 9676/9676 |
| prefetch8-rowconst4 | column | 8 | 4,719 | 1,247 | 0 RAMB36 + 0 RAMB18 | 201 | -2.242 (FAIL) | 10,730 | 4.307 | 0.314 / 0.593 / 0.908 | 0.537 / 0.595 / 1.132 | 10115/10115 |

P3F category breakdown (Typical; watts):

| Pair | Interface | Clocks | CLB logic | Signals | DSPs | BRAM | I/O | Non-I/O dynamic | Confidence |
|---|---|---:|---:|---:|---:|---:|---:|---:|---|
| std | scalar | 0.010 | 0.034 | 0.046 | 0.010 | 0.000 | 0.182 | 0.099 | High |
| std | column | 0.014 | 0.054 | 0.082 | 0.015 | 0.000 | 0.287 | 0.165 | High |
| prefetch8-rowconst4 | scalar | 0.015 | 0.042 | 0.062 | 0.009 | 0.000 | 0.118 | 0.128 | High |
| prefetch8-rowconst4 | column | 0.015 | 0.063 | 0.092 | 0.013 | 0.000 | 0.354 | 0.183 | High |

`report_io` lists 101 user-I/O bits for each scalar top and 201 for each column top; the report marks these ports UNFIXED. P3F power therefore includes Vivado-estimated I/O power at this top-level boundary with inferred defaults, not a board pinout/load model. The column interface roughly doubles the exposed top-level I/O count, so do not attribute the P3F power difference solely to internal datapath switching.

*Throughput is an equivalent active-job rate derived from active cycles and 317 MHz. It excludes inter-job reset/rearm and is not a sustained multi-job rate. The prefetch8 rows fail the 317 MHz timing constraint (negative WNS/TNS); their 317 MHz throughput and energy figures are hypothetical at the common comparison point and require a lower-frequency implementation before being claimed as achievable FPGA performance.

Derived typical-corner metrics use active-job cycles at 317 MHz and 145,800 equivalent operations/job. They are estimates from Vivado power, not board measurements:

| Pair | Interface | Dynamic energy/job (uJ) | Total energy/job (uJ) | Dynamic GOPS/W | Total GOPS/W | P0 max dyn/static/total (W) | P3F max dyn/static/total (W) |
|---|---|---:|---:|---:|---:|---:|---:|
| std | scalar | 20.96 | 65.20 | 6.96 | 2.24 | 0.251 / 0.814 / 1.065 | 0.281 / 0.814 / 1.095 |
| std | column | 15.08 | 34.90 | 9.67 | 4.18 | 0.332 / 0.815 / 1.146 | 0.452 / 0.817 / 1.269 |
| prefetch8-rowconst4 | scalar | 16.97 | 57.87 | 8.59 | 2.52 | 0.137 / 0.812 / 0.949 | 0.246 / 0.814 / 1.059 |
| prefetch8-rowconst4 | column | 18.18 | 38.32 | 8.02 | 3.81 | 0.314 / 0.815 / 1.129 | 0.537 / 0.818 / 1.355 |
