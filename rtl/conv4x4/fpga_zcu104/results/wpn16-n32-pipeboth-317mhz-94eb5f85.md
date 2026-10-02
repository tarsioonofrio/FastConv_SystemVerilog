# WPN16 dual-transform pipeline: 32 cores at 317 MHz

This is a separate timing-oriented WPN16 m08 candidate. It keeps the earlier
feature-only pipeline experiment and adds a register barrier between the two
separable axes of the weight transform. The feature-only version remains
available by leaving `PIPE_WEIGHT_TRANSFORM=0`; the dual-barrier configuration
uses `PIPE_WEIGHT_TRANSFORM=1`.

## RTL functional check

The 16-bit canonical truncated workload
`sim-032-3-3-normal-trunc-nbits16` passed the Verilator streaming-column test:

```text
inverse_tiles=576
terminal_inverse_events=0
cycles_to_end=9994
cycles=9996
useful_weight_beats=27
valid_writes=8100
golden mismatches=0
```

This adds 576 cycles relative to the feature-only pipelined candidate, one
cycle per spatial tile. The functional simulation is a single-core RTL check;
the 32-core Vivado run below is an OOC implementation/timing result, not a
32-core Xcelium golden simulation.

## 32-core implementation at 317 MHz

Vivado 2023.2, XCZU7EV (`xczu7ev-ffvc1156-2-e`), OOC implementation, 16-bit
datapath, 32 independent logical core boundaries, placement Explore,
post-placement `phys_opt_design -directive Explore`, and
`route_design -directive Explore`:

| Metric | Result |
| --- | ---: |
| Target period | 3.154574 ns (Vivado report rounds to 3.155 ns) |
| Post-route WNS | **+0.043 ns (PASS)** |
| Post-route TNS | 0 ns |
| Post-route WHS / THS | +0.040 ns / 0 ns |
| LUT | 180,060 / 230,400 (78.15%) |
| FF | 99,813 / 460,800 (21.66%) |
| DSP48E2 | 256 / 1,728 (14.81%) |
| BRAM | 0 / 312 |

The route completed successfully with no failed, unrouted, or partially routed
nets. Vivado reported localized CLB routing congestion during routing, but the
final routing verification passed. This demonstrates a post-route timing pass
at the requested 317 MHz operating point; it does not establish Fmax.

## Critical path

The worst path is in replica 27, from
`FSM_onehot_st_conv_current_reg[5]` to the clock-enable (`CE`) of
`r_transform_partial_reg[10][12]`. It has zero logic levels, a data-path delay
of 3.007 ns, and a routed net fanout of 684. The delay is dominated by routing:
2.928 ns (97.37%) versus 0.079 ns of cell delay. Thus the transform arithmetic
is no longer the limiting path in this run; the remaining narrow margin is
associated with a high-fanout state/control enable feeding the feature
transform register bank.

The OOC timing report warns that `HD.CLK_SRC` is unset on the clock port, so
clock delay/skew estimation is not available in the same way as in a full
top-level context. Vivado also reports missing `HD.PARTPIN_LOCS` for the
replicated OOC boundary ports; timing to and from those ports is therefore not
accurate as a package-level interface estimate. `check_timing` reports zero
unconstrained internal endpoints, while 5,186 input ports have no input delay
and 2,944 output ports have no output delay. The reported worst path is an
internal register-to-register control/enable path. Preserve this as an OOC
internal timing pass under the recorded constraints, not as board-level or
external-interface timing evidence.

## Comparison with the preserved feature-only trial

| 32-core candidate | Post-route WNS @ 317 MHz | LUT | FF | DSP48E2 |
| --- | ---: | ---: | ---: | ---: |
| Feature barrier only | −0.449 ns (FAIL) | 207,352 (90.00%) | 88,104 (19.12%) | 256 |
| Feature + weight barriers | **+0.043 ns (PASS)** | **180,060 (78.15%)** | 99,813 (21.66%) | 256 |

The dual-pipeline candidate uses 27,292 fewer LUTs (13.2% below the feature-only
candidate) and 11,709 more FFs (13.3% above it). Most importantly, the added
weight-transform boundary moves the 32-core implementation from failing to
meeting 317 MHz. Keep the feature-only result as a failed but useful historical
experiment; do not replace it or relabel its result.

## Provenance and reports

- RTL commit: `94eb5f854f9ff06781317e3ef894b3e19f93c489`
- Remote worktree: `/sim/tarsio/fastconv-wpn16-pipeboth-94eb5f85`
- Vivado output: `/sim/tarsio/reports-wpn16-pipeboth-n32-317mhz-94eb5f85`
- Algorithm: `wpn16_pipe_both_nbits16`, 32 cores, `NBITS=16`
- Result marker: `timing_closed_317mhz=1`, `wns_ns=0.043`

Text-only timing, utilization, DRC, clock, metadata, journal, and Vivado log
artifacts are stored in the matching `reports/wpn16-pipeboth-n32-317mhz-94eb5f85/`
directory. Trailing whitespace and extra final blank lines were stripped from copied Vivado reports/logs;
the report content and values were otherwise left unchanged. No DCP, synthesized
netlist, bitstream, waveform, SAIF, or simulator database is included in Git.

The campaign is limited to synthesis, placement, physical optimization, and
route. It did not run replicated post-implementation functional simulation or
power analysis, so no power/energy result is claimed.
