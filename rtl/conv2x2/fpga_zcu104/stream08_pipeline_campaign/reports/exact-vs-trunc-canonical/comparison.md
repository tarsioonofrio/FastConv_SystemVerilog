# FPGA comparison: `exact` versus `trunc`

## Setup and interpretation

Both implementations were run through Vivado synthesis and post-route implementation on the ZCU104 target part `xczu7ev-ffvc1156-2-e`, with Vivado 2023.2, Xcelium 23.03-s003, and the same 3.154574 ns clock constraint (316.957 MHz after Vivado's 1 ps resolution). Long runs were launched in `tmux` on Paxos. The source commit was `a37f1df2ec065b408ba3915d028628f193746f59`; the persistent Paxos checkout was not modified. Input data and canonical outputs came from `sim-032-3-3-normal/pack_data.sv` (SHA-256 recorded in `comparison_sha256.txt`).

The comparison is between two complete RTL variants, not a controlled experiment changing only rounding:

- `exact`: archived `conv-i16-h13-t08-o4-m08-stream08-rowconst4-exact.sv`;
- `trunc`: `conv-i24-h13-t08-o4-m08-stream08-prefetch8-rowconst4-trunc.sv`.

They also differ in prefetch architecture and datapath width. Therefore the PPA differences below belong to these variants as a whole and cannot be attributed only to truncation.

## Results

| Metric | `exact` | `trunc` | Comparison |
|---|---:|---:|---|
| DSP | 8 | 8 | same |
| LUT | 3,037 | 2,949 | trunc uses 88 fewer (−2.9%) |
| FF | 1,108 | 1,409 | trunc uses 301 more (+27.2%) |
| RAMB36 / RAMB18 | 0 / 0 | 0 / 0 | same |
| WNS at 316.957 MHz | −2.105 ns | +0.009 ns | exact fails; trunc barely passes |
| TNS / failing setup endpoints | −170.513 ns / 127 | 0 ns / 0 | trunc closes the constrained internal paths |
| Worst path | `r_input_feat_reg[13][2]` → `r_output_write_reg[3][18]` | `r_transform_feature_reg_reg[3][9]` → `r_inverse_partial_current_reg[1][14]` | see path details below |
| Worst path delay / logic levels | 5.239 ns / 20 | 3.030 ns / 10 | trunc path is 2.209 ns shorter |
| Canonical-golden mismatches | 2,502 / 2,700 | 2,473 / 2,700 | trunc has 29 fewer mismatches |
| MAE | 5.0741 | 3.7385 | trunc lower by 26.3% |
| RMSE | 6.3984 | 4.8610 | trunc lower by 24.0% |
| Maximum absolute error | 23 | 21 | trunc lower by 8.7% |
| 95th percentile absolute error | 13 | 10 | trunc lower |
| Post-route functional SAIF window | 80.826081 µs (~25,618 cycles) | 74.896561 µs (~23,739 cycles) | start-to-`p_end` capture |
| Equivalent active-window throughput* | 1.804 GOPS | 1.947 GOPS | trunc +7.9% |
| P3F typical dynamic / static / total | 0.291 / 0.593 / 0.884 W | 0.299 / 0.593 / 0.892 W | trunc +8 mW dynamic, +8 mW total |
| P3F maximum dynamic / static / total | 0.291 / 0.814 / 1.105 W | 0.299 / 0.814 / 1.114 W | trunc +8 mW dynamic, +9 mW total |
| P0 vectorless typical dynamic / static / total | 0.162 / 0.593 / 0.755 W | 0.203 / 0.593 / 0.796 W | trunc +41 mW dynamic |
| P0 vectorless maximum dynamic / static / total | 0.162 / 0.812 / 0.974 W | 0.203 / 0.813 / 1.016 W | trunc +41 mW dynamic |
| P3F top-SAIF mapping | 7,052 / 7,052 (100%) | 7,251 / 7,251 (100%) | full direct mapping in each routed design |

The error metrics are against the canonical golden and were calculated from the RTL output vectors. The post-route functional simulations reproduced the same mismatch counts. Both jobs completed and produced the expected output-write count; neither version is golden-correct, so these runs do not establish a correct-output FPGA benchmark.

*The throughput is `145,800 equivalent operations / SAIF active-window duration` and is included only as a measure of the completed run's rate. Because the outputs mismatch the canonical golden, it must not be read as throughput of a validated inference result. The SAIF time unit is 1 fs; the capture starts at `p_start` and stops at `p_end`.

### Critical paths

The `exact` critical path starts at an input-feature register and ends at an output-write register, crossing multiplier/DSP and carry logic: 20 logic levels and 5.239 ns data-path delay. It misses the 3.155 ns target by 2.105 ns, with 127 setup endpoints failing.

The `trunc` critical path starts at a registered transformed feature and ends at the registered inverse partial result: 10 logic levels and 3.030 ns delay. It meets the target by only 0.009 ns. This is effectively zero margin; the timing report covers constrained internal paths and is not a board-interface timing certification.

### Power breakdown, P3F typical

| Component | `exact` | `trunc` | Δ (`trunc - exact`) |
|---|---:|---:|---:|
| Clocks | 0.013 W | 0.014 W | +0.001 W |
| CLB logic | 0.038 W | 0.028 W | −0.010 W |
| Signals | 0.055 W | 0.042 W | −0.013 W |
| DSP | 0.009 W | 0.006 W | −0.003 W |
| BRAM | 0 W | 0 W | 0 W |
| I/O | 0.177 W | 0.209 W | +0.032 W |
| Dynamic total (tool report) | 0.291 W | 0.299 W | +0.008 W |

The aggregate dynamic-power difference is small, but the component mix changes: the trunc variant's I/O estimate rises by 32 mW while its CLB, signal, and DSP estimates fall. Both designs expose the same 101 top-level I/Os; these are current top-level estimates, not core-only/OOC power. P3F has High Vivado confidence and 100% SAIF mapping, but the SAIF represents switching for a run whose output differs from the canonical golden. Treat these power figures as comparative activity estimates for the tested RTL/input sequence, not as power for a validated inference result.

## Conclusion

For these two variants, `trunc` is clearly better in post-route timing and has lower numerical error against the canonical golden, at the cost of 301 extra FFs and an 8 mW higher P3F typical dynamic estimate. It barely closes the common clock target, while `exact` fails timing substantially. The numerical distance between them is not negligible in relative terms (about 24–26% lower RMSE/MAE for `trunc`), but both still mismatch more than 90% of outputs, so neither is acceptable as a golden-correct implementation yet.

This is not an isolated rounding/truncation conclusion because the RTLs differ in other architectural details. To identify the effect of truncation alone, the next controlled pair should be the rounded and truncated `prefetch8-rowconst4` variants with otherwise matching width, pipeline, workload, and constraints.

## Preserved evidence

The sibling `exact/` and `trunc/` directories preserve the routed DCP, post-route functional netlist, raw DUT/top SAIFs, RTL simulation logs, timing/utilization reports, and P0/P3F power reports. `comparison_provenance.txt`, `comparison_sha256.txt`, and `campaign.log` record provenance and execution. The comparison ran in an isolated temporary clone at `/tmp/fastconv-exact-trunc.syAEwG`; the persistent Paxos checkout was left untouched.
