# FPGA flow: prefetch8-rowconst4-trunc-column

## Setup and provenance

- Source commit: `9d79ad4bc14564ac35e095457d5d48d1a73d55f2`.
- Host: `paxos.inf.pucrs.br`; long-running jobs ran in `tmux` in an isolated temporary clone.
- Device: ZCU104, `xczu7ev-ffvc1156-2-e`.
- Vivado: 2023.2, build 4029153.
- Xcelium: 23.03-s003.
- Requested clock: 317 MHz; XDC period `3.154574 ns`, rounded by Vivado to `3.155 ns` (`316.957 MHz`).
- RTL: `conv-i24-h13-t08-o4-m08-stream08-prefetch8-rowconst4-trunc-column.sv`.
- Workload: canonical `sim-032-3-3-normal-trunc/pack_data.sv`.
- Flow: synthesis, place and route, post-route functional simulation, SAIF, vectorless and P3F power reports. No SDF timing simulation was used.

## Functional result

Post-route functional Xcelium simulation passed:

```text
POWER_RESULT PASS writes=8100 final_words=2700 mismatches=0 active_cycles=14502
```

The run completed 2,025 inverse tiles and 8,100 writes with zero golden mismatches. P3F SAIF capture was bounded by the workload start/end events.

## Implementation and timing

| Metric | Result |
| --- | ---: |
| LUT | 3,156 |
| FF | 1,484 |
| DSP | 8 |
| BRAM | 0 |
| WNS at routed clock constraint | +0.185 ns |
| TNS | 0.000 ns |
| Setup failing endpoints | 0 |

The requested 3.154574 ns period was rounded to 3.155 ns by Vivado. The timing report also lists unconstrained top-level I/O paths: 123 inputs lack input delays and 73 outputs lack output delays. The timing result therefore characterizes constrained internal synchronous paths, not external interface timing.

## Power

Post-route functional SAIF mapping:

- DUT scope: 7,554 / 7,754 nets (97.42%).
- Top scope used by the P3F report: 7,754 / 7,754 nets (100%).
- Vivado P3F confidence: High.

| Method | Corner | Dynamic | Device static | Total |
| --- | --- | ---: | ---: | ---: |
| P0 vectorless | Typical | 0.286 W | 0.593 W | 0.879 W |
| P3F functional SAIF | Typical | 0.389 W | 0.594 W | 0.983 W |
| P0 vectorless | Maximum | 0.286 W | 0.814 W | 1.100 W |
| P3F functional SAIF | Maximum | 0.389 W | 0.816 W | 1.205 W |

P3F typical dynamic breakdown: clocks 0.015 W, CLB logic 0.034 W, signals 0.054 W, DSP 0.009 W, and I/O 0.277 W. These are Vivado estimates for the implemented top-level, including its physical I/O interface; they are not board measurements or core-only power. Functional SAIF does not include SDF glitch activity.

## Artifacts and interpretation

The report directory contains the full local run artifacts, including DCPs, functional netlist, SAIF, and detailed mapping reports. Large generated implementation/activity artifacts are excluded from Git; SHA-256 values are retained in `artifact_hashes.sha256`, and source/workload provenance is recorded in `input_hashes.sha256` and `provenance.txt`.

The 100% figure is direct SAIF name/activity mapping for the top-level import scope, not a claim of 100% physical power accuracy. P3F is a post-route functional activity estimate and does not model timing glitches; total power includes the device-static estimate and current top-level I/O assumptions.
