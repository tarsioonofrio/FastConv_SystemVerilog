# FPGA flow: prefetch8-rowconst4-trunc-pipe

## Setup and provenance

- Source commit: `0ff2cf1fa9a88029bff326f0a13eaf0ff9161a97`
- Host: `paxos.inf.pucrs.br`; run executed in `tmux` in an isolated temporary clone.
- Device: ZCU104, `xczu7ev-ffvc1156-2-e`.
- Vivado: 2023.2, build 4029153.
- Xcelium: 23.03-s003.
- Target clock: 317 MHz; XDC period `3.154574 ns`, rounded by Vivado to `3.155 ns`.
- RTL: `conv-i24-h13-t08-o4-m08-stream08-prefetch8-rowconst4-trunc-pipe.sv`.
- Workload: canonical `sim-032-3-3-normal-trunc/pack_data.sv`.
- Full run: synthesis, place and route, post-route functional simulation, SAIF, vectorless and P3F power reports. No SDF timing simulation was used.
- The persistent Paxos checkout was not modified. Source/campaign commit was pushed before execution; generated reports are local and currently uncommitted.

## Functional result

Post-route functional Xcelium simulation passed:

```text
POWER_RESULT PASS writes=8100 final_words=2700 mismatches=0 active_cycles=23747
```

The run completed 2,025 inverse tiles and 8,100 writes with zero golden mismatches. P3F SAIF capture began at `p_start` and stopped at `p_end`.

## Implementation and timing

| Metric | Result |
| --- | ---: |
| LUT | 2,913 |
| FF | 1,489 |
| DSP | 8 |
| BRAM | 0 |
| WNS at 317 MHz target | +0.129 ns |
| TNS | 0.000 ns |
| Setup failing endpoints | 0 |

The worst internal register-to-register path is from `r_transform_feature_reg_reg[3][8]` to `r_hadamard_product_reg_reg[3][18]`. It has 2.857 ns data delay (1.996 ns logic, 0.861 ns routing) and 9 logic levels. The path traverses the DSP multiply/Hadamard logic and terminates at the new registered product bank. This is a timing PASS at the requested clock, not a separate Fmax search. Vivado rounded the clock period to 3.155 ns, equivalent to about 316.96 MHz.

The timing report also lists unconstrained top-level I/O paths (the XDC constrains the clock but provides no input/output delay budgets); therefore this timing result characterizes constrained internal synchronous paths, not external interface timing.

## Power

Post-route functional SAIF mapping:

- DUT scope: 7,239 / 7,339 nets (98.64%).
- Top scope used by the P3F report: 7,339 / 7,339 nets (100%).
- Vivado P3F confidence: High.

| Method | Corner | Dynamic | Device static | Total |
| --- | --- | ---: | ---: | ---: |
| P0 vectorless | Typical | 0.154 W | 0.593 W | 0.747 W |
| P3F post-route functional SAIF | Typical | 0.201 W | 0.593 W | 0.793 W |
| P0 vectorless | Maximum | 0.154 W | 0.812 W | 0.967 W |
| P3F post-route functional SAIF | Maximum | 0.201 W | 0.813 W | 1.014 W |

P3F typical dynamic breakdown: clocks 0.018 W, CLB logic 0.028 W, signals 0.041 W, DSP 0.006 W, and I/O 0.108 W. These are Vivado estimates for the implemented top-level, including its current physical I/O interface; they are not board measurements or core-only power. Functional SAIF does not include SDF glitch activity.

## Derived active-job metrics

Using 145,800 equivalent operations/job, 23,747 active cycles, and the rounded routed period of 3.155 ns:

- Active-job duration: 74.922 us.
- Equivalent throughput during the active job: 1.946 GOPS.
- P3F typical dynamic energy: 15.06 uJ/job.
- P3F typical total energy: 59.41 uJ/job.
- Dynamic-power-normalized efficiency: 9.68 GOPS/W.
- Total efficiency: 2.45 GOPS/W.

These derived energy/efficiency values include the reported top-level I/O power and, for total energy/efficiency, device-static power. They should not be interpreted as intrinsic datapath-only metrics. Inter-job throughput is not reported.

## Comparison with previous prefetch8 runs

The previous truncating run had 2,949 LUT, 1,409 FF, 8 DSP, and only +0.009 ns WNS; its testbench reported 2,473 mismatches against the then-used rounded golden, so its activity/power was not accepted as a valid workload result. The exact run had 3,081 LUT, 1,450 FF, 8 DSP, +0.001 ns WNS, and 23,747 active cycles. Its P3F power used the exact workload package, so its power numbers are not directly comparable to this truncating workload.

Relative to the prior truncating implementation, this pipeline version uses 36 fewer LUTs and 80 more FFs, while improving WNS by 0.120 ns (from +0.009 ns to +0.129 ns) and shortening the reported worst data path from 3.030 ns/10 levels to 2.857 ns/9 levels. The new run is also golden-clean against its truncation-specific canonical package.

## Artifacts

The local run directory retains the routed and synthesis DCPs, functional netlist, timing/utilization/IO/DRC reports, vectorless and P3F typical/maximum power reports, Xcelium logs, SAIFs, Vivado logs/journals, metadata, provenance, and input hashes. Generated DCP, netlist, SAIF, and full mapping artifacts are not committed; this repository version keeps the summary and compact reports needed to inspect the result. SHA-256:

- `design_routed.dcp`: `7269e259961dd1cae414e2c38f2a3da149fd6b6392503700bee46d3adccc5d40`
- `top/activity_top.saif`: `fe278bf6802ba1f3554e0c870c57e6de9cfc87d115f7246ec965d7326b0ec823`
