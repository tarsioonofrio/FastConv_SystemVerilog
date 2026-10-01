# IFN9 Explore + post-route phys-opt FPGA campaign

## Provenance and method

- Source commit: `149bd5be16c78ab9df405f4f0b1c06c48a25c990`
- Platform: ZCU104 / XCZU7EV (`xczu7ev-ffvc1156-2-e`)
- Tools: Vivado 2023.2; Xcelium 23.03-s003
- Host: `paxos.inf.pucrs.br`
- Target clock: 317 MHz (`3.154574 ns` constraint; Vivado rounds it to
  `3.155 ns`)
- Implementation flow: default `synth_design`, then `opt_design`,
  `place_design -directive Explore`, `phys_opt_design -directive Explore`,
  `route_design -directive Explore`, and final
  `phys_opt_design -directive Explore`.
- Power: post-implementation functional simulation (P3F), without SDF;
  workload activity is captured from `p_start` through `p_end` and read into
  the routed DCP. These are Vivado estimates, not board measurements.
- Workload: canonical IFN9 32x32, Cin=3, Cout=3, truncated package. Each run
  wrote 8,100 physical words representing 2,700 final outputs; all had zero
  golden mismatches.

## Results

| Variant | MAC lanes / DSP | LUT | FF | Post-route WNS @317 MHz | TNS | Active cycles | DUT SAIF match | Top SAIF match | Dynamic typical | Total typical | Total maximum |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| IFN9 m06 | 6 | 4,721 | 1,885 | +0.094 ns | 0 ns | 11,038 | 10,045/10,297 (97.55%) | 10,297/10,297 (100%) | 0.557 W | 1.152 W | 1.375 W |
| IFN9 m12 | 12 | 5,513 | 2,251 | +0.099 ns | 0 ns | 8,338 | 11,243/11,495 (97.81%) | 11,495/11,495 (100%) | 0.762 W | 1.357 W | 1.583 W |
| IFN9 m18 | 18 | 7,992 | 2,693 | -0.224 ns | -52.290 ns | 7,438 | 14,460/14,712 (98.29%) | 14,712/14,712 (100%) | 0.881 W | 1.478 W | 1.704 W |

All three post-route functional simulations passed:

```text
2700 final outputs; 8100 physical words; 0 golden mismatches
```

m06 and m12 close timing at 317 MHz. m18 does not: 497 of 5,073 timed
endpoints fail setup at the target, and the final post-route phys-opt improves
WNS only from about `-0.250 ns` to `-0.224 ns`. Its shorter active-cycle count
is therefore not a timing-closed 317 MHz operating point.

## Power interpretation

The Typical dynamic breakdown (`Clocks / CLB Logic / Signals / DSP / I/O`) is:

| Variant | Clocks | CLB Logic | Signals | DSP | I/O | Device static (Typical / Maximum) |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| m06 | 0.021 W | 0.055 W | 0.094 W | 0.010 W | 0.376 W | 0.595 / 0.818 W |
| m12 | 0.026 W | 0.072 W | 0.125 W | 0.013 W | 0.525 W | 0.596 / 0.821 W |
| m18 | 0.046 W | 0.102 W | 0.224 W | 0.016 W | 0.493 W | 0.596 / 0.823 W |

The design top still exposes 253 package I/Os. Consequently the P3F total
includes substantial Vivado I/O-power estimates (notably 0.376–0.525 W), so
the total is not an IP-only/core-only power number. P3F has High confidence and
100% top-scope SAIF matching for all three variants; the DUT-only SAIF matches
97.55–98.29% of routed nets. The functional SAIF omits delay-induced glitches.

## Artifacts

The campaign ran in tmux from a clean temporary checkout on Paxos, at the
exact source commit above. The persistent checkout at
`/sim/tarsio/FastConv_SystemVerilog` was not modified. Full raw outputs
(including DCPs, SAIFs, and mapping reports) remain at:

```text
/sim/tarsio/reports-conv3x3-ifn9-explore-149bd5be
```

This directory contains the selected text reports and logs. `checksums.sha256`
records the DCP, funcsim netlist, SAIF, workload, and source hashes. Campaign
exit code: `0`.
