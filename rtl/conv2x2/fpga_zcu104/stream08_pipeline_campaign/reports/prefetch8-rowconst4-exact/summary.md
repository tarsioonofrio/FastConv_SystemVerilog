# Exact prefetch8 FPGA campaign

## Configuration and provenance

- Git commit: `a0ce877e005a80f65a25a138727ebd2098545858`
- Device: ZCU104, `xczu7ev-ffvc1156-2-e`
- Vivado: 2023.2, build 4029153
- Xcelium: 23.03-s003
- Top: `Conv`
- Workload: `sim-032-3-3-normal-exact/pack_data.sv`
- RTL: `conv-i24-h13-t08-o4-m08-stream08-prefetch8-rowconst4-exact.sv`
- Flow: synthesis, place and route, post-implementation functional simulation, SAIF, `report_power`
- Timing simulation/SDF was not used.
- Long-running steps were executed in tmux on `paxos.inf.pucrs.br` in an isolated clone. The persistent Paxos checkout was not modified.

## Implementation and timing

| Metric | Result |
| --- | ---: |
| LUT | 3,081 |
| FF | 1,450 |
| DSP | 8 |
| BRAM | 0 |
| WNS at routed clock constraint | +0.001 ns |
| TNS | 0.000 ns |

The XDC requested 3.154574 ns. Vivado rounded it to 3.155 ns at 1 ps resolution, equivalent to 316.957 MHz. This is a timing PASS for this implementation with only 1 ps of margin, not an Fmax characterization. Timing reports also flag 43 input ports without input delay and 53 output ports without output delay; internal endpoints are constrained, but interface timing is not characterized.

## Post-route functional simulation

Both DUT-scope and top-scope Xcelium runs completed with:

```text
POWER_RESULT PASS writes=8100 final_words=2700 mismatches=0 active_cycles=23747
```

The SAIF observation window was 74.896561 us (74,896,561,000 ps), from `p_start` to `p_end`. The testbench clock period was 3.154 ns, or 317.058 MHz. The period difference from the routed XDC clock is 0.032%.

SAIF mapping in Vivado:

- DUT-scope SAIF: 7,458 / 7,558 nets matched (98.68%).
- Top-scope SAIF: 7,558 / 7,558 nets matched (100%).
- Vivado confidence for P3F: High.

## Power results

| Method | Corner | Dynamic | Device static | Total |
| --- | --- | ---: | ---: | ---: |
| P0 vectorless | Typical | 0.197 W | 0.593 W | 0.790 W |
| P3F post-route functional SAIF | Typical | 0.286 W | 0.593 W | 0.879 W |
| P0 vectorless | Maximum | 0.197 W | 0.813 W | 1.010 W |
| P3F post-route functional SAIF | Maximum | 0.286 W | 0.814 W | 1.100 W |

P3F typical dynamic breakdown: clocks 0.014 W, CLB logic 0.029 W, signals 0.046 W, DSP 0.006 W, and I/O 0.191 W. The I/O term is substantial because this core's memory interface remains on physical top-level ports; therefore this total is a post-route estimate for the current FPGA top-level, not an estimate of datapath-only power. P3F is functional activity and does not include SDF glitch activity. It is an estimate, not a board measurement.

Relative to P0, P3F dynamic power is 0.089 W higher (+45.2%). Of that delta, 0.078 W comes from I/O, 0.010 W from signals, 0.002 W from CLB logic, and about -0.001 W from clocks; DSP power is unchanged at the report precision.

## Derived active-job metrics

Using 145,800 equivalent operations per job, 23,747 active cycles, and the rounded 3.155 ns routed period:

- Active-job throughput: approximately 1.946 GOPS.
- Job time: approximately 74.922 us.
- P3F typical dynamic energy: approximately 21.43 uJ/job.
- P3F typical total energy: approximately 65.86 uJ/job.

These energy and efficiency values include the reported top-level I/O power and device-static contribution as applicable. They should not be interpreted as intrinsic core-only energy.

## Artifacts

The local run directory contains the routed and synthesis DCPs, post-route functional netlist, timing/utilization/IO/DRC reports, P0 and P3F typical/maximum power reports, Xcelium logs, SAIF files, Vivado logs/journals, tool/module provenance, and SHA-256 input hashes. The full SAIF mapping reports are retained locally as `p3f_mapping_*.rpt`; generated DCP, netlist, SAIF, and full mapping artifacts are not committed. This repository version keeps the summary and compact reports needed to inspect the result.
