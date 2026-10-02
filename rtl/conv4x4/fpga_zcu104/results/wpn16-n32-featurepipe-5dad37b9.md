# WPN16 feature-only transform pipeline, 32 cores

This is a preserved experiment for the feature-only pipelined RTL at commit
`5dad37b9452fc0e4aa03ca22d14eb8581d644f48`. It is distinct from the canonical
unpipelined WPN16 and from the later candidate that also pipelines the weight
transform.

## RTL golden

The 16-bit canonical truncated workload
`sim-032-3-3-normal-trunc-nbits16` passed the Verilator column test:

```text
inverse_tiles=576
valid_writes=8100
golden mismatches=0
cycles_to_end=9418
cycles=9420
```

The datapath function is valid, but that does not imply that the replicated
implementation meets the target clock.

## 32-core implementation at 317 MHz

Vivado 2023.2, XCZU7EV (`xczu7ev-ffvc1156-2-e`), OOC implementation, 16-bit
datapath, 32 independent logical core boundaries, with `Explore` placement,
post-place `phys_opt_design -directive Explore`, and `route_design -directive
Explore`:

| Metric | Result |
| --- | ---: |
| Target period | 3.154574 ns (Vivado timing report: 3.155 ns) |
| Post-route WNS | **−0.449 ns (FAIL)** |
| Post-route TNS | −192.289 ns |
| LUT | 207,352 / 230,400 (90.00%) |
| CLB sites | 28,536 / 28,800 (99.08%) |
| FF | 88,104 / 460,800 (19.12%) |
| DSP48E2 | 256 / 1,728 (14.81%) |
| BRAM / URAM | 0 / 0 |

The router completed and verified all routed nets, but emitted a critical
warning that timing was not met. Therefore this is not evidence of a 317 MHz
implementation.

## Critical path and interpretation

The worst path is inside replica 9, from
`r_weight_spatial_reg[0][0]` to `r_input_weight_reg[2][11]`. It crosses the
combinational constant weight-transform row logic. The reported data-path
delay is 3.584 ns: 1.062 ns logic and 2.522 ns routing over 10 logic levels
(four CARRY8s and LUTs). This is the weight-transform path, not the feature
`MatrixC0` → register → `MatrixC1` path that the feature-only pipeline split.

This result motivated the separate `PIPE_WEIGHT_TRANSFORM=1` candidate. That
candidate places a register between the two separable axes of the weight
transform while retaining full-precision intermediate numerators; its FPGA
route result must be evaluated independently.

## Preserved reports

Text reports from the failed route are retained alongside this note:

- `critical_paths.rpt`
- `timing_summary.rpt`
- `utilization.rpt` and `utilization_synth.rpt`
- hierarchical utilization, clock utilization, DRC, metadata, and `result.txt`

No DCP, netlist, waveform, SAIF, or other binary implementation artifact is
stored here. The full Vivado log and implementation workspace remain on Paxos.
