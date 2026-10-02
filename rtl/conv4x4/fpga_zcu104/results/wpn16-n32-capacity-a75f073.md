# WPN16 m08 replicated capacity at 16 bits

This is a preserved capacity experiment for the unpipelined WPN16 m08 core,
not the transform-pipelined variant introduced later. It uses 32 replicated
cores, Vivado 2023.2, XCZU7EV, out-of-context implementation, and the
`Explore` place / post-place physical optimization / `Explore` route flow.
The published source revision was `a75f073eb0c16b602a9c023bf6d1344a20a90e8`.

| Target clock | Result | WNS | LUT | FF | DSP | BRAM |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 220 MHz | post-route PASS | +0.191 ns | 209,920 (91.11%) | 64,680 (14.04%) | 256 (14.81%) | 0 |
| 250 MHz | post-route FAIL | -0.280 ns | not retained in this summary | not retained in this summary | not retained in this summary | not retained in this summary |

At 220 MHz, the worst reported internal path was from
`CORES[30].core_inst/r_input_feat_reg[10][3]` to
`CORES[30].core_inst/r_transform_feature_reg_reg[4][15]`. Its data-path delay
was 4.334 ns, comprising 1.347 ns logic and 2.987 ns route, across 10 logic
levels. This path spans both combinational feature-transform stages
(`MatrixC0` and `MatrixC1`), motivating the separate pipeline experiment.

The routed device utilization was the limiting capacity dimension: CLB LUT use
was 91.11%, while FF and DSP use were much lower. The OOC timing result covers
constrained internal synchronous paths; the logical core boundary has no
package I/O buffers and does not establish external input/output timing.

This is an implementation/timing capacity result only. No functional golden,
SAIF, or power campaign was run for the 32-core configuration. Raw text reports
and Vivado logs are preserved under `reports/wpn16-n32-220mhz-a75f073/` and
`reports/wpn16-n32-250mhz-a75f073/`.
