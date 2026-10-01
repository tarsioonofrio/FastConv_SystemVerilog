# IFN9 m18 with the Vivado NetDelay_high implementation strategy

## Scope and provenance

This is a bounded implementation-only follow-up to
[`ifn9-explore-149bd5be.md`](ifn9-explore-149bd5be.md). It keeps the IFN9 m18
RTL, manifest, XCZU7EV target, 317 MHz XDC, and default `opt_design` unchanged;
only the physical implementation directives differ. The RTL hash is
`73e6cb3d8195e9d298bb0b91368521ddf784ff21de982779deceaf5c790fb80c`.

- Published source commit: `231d0dcf357fcf86c6faf862be2a16d515e1d2b4`
- Host: `paxos.inf.pucrs.br`
- Vivado: 2023.2
- Part: `xczu7ev-ffvc1156-2-e`
- Target: 317 MHz (`3.154574 ns` constraint)
- Execution: tmux session `ifn9-netdelay-high-231d0dcf`
- Raw campaign output: `/sim/tarsio/reports-ifn9-netdelay-high-231d0dcf`
- Temporary sparse worktree: `/tmp/fastconv-ifn9-p3f-231d0dcf` for P3F

The run used the documented Vivado `Performance_NetDelay_high` mapping:

```text
opt_design                         Default
place_design                       ExtraNetDelay_high
phys_opt_design (post-place)      AggressiveExplore
route_design                       NoTimingRelaxation
phys_opt_design (post-route)      AggressiveExplore
```

AMD describes `Performance_NetDelay_high` as adding cost to long-distance and
high-fanout connections and maps it to aggressive physical optimization and
no timing relaxation in the router ([UG904 2023.2 strategy mapping](https://docs.amd.com/r/2023.2-English/ug904-vivado-implementation/Directives-Used-by-phys_opt_design-and-route_design-in-Implementation-Strategies), [UG904 strategy description](https://docs.amd.com/r/2023.2-English/ug904-vivado-implementation/Directives-Used-by-opt_design-and-place_design-in-Implementation-Strategies)).

## Result

| Variant | DSP | LUT | FF | WNS @317 MHz | TNS | Failing setup endpoints | Total setup endpoints |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| IFN9 m18, Explore + post-route phys-opt | 18 | 7,992 | 2,693 | -0.224 ns | -52.290 ns | 497 | 5,073 |
| IFN9 m18, NetDelay_high | 18 | 7,782 | 2,623 | **+0.084 ns** | **0 ns** | **0** | 4,933 |

The alternate implementation closes the 317 MHz setup constraint, with 84 ps
of positive worst slack. WNS improves by 308 ps versus the earlier Explore
implementation; the design uses 210 fewer LUTs and 70 fewer FFs in this run,
with the same 18 DSPs. The new critical path is
`r_input_feat_reg[17][0]` to `r_transform_feature_reg_reg[9][8]` (2.961 ns,
about 71% routed interconnect delay), so timing closure is positive but still
has modest margin.

## Post-implementation functional simulation and P3F power

The routed DCP above was used for a separate Xcelium post-implementation
**functional** simulation (no SDF), followed by SAIF import into that same DCP.
The run used Xcelium 23.03-s003 and the existing Vivado 2023.2/Xcelium UNISIM
simulation library. It did not repeat synthesis or place-and-route.

Both independent SAIF capture scopes passed the canonical truncated IFN9
workload:

```text
STREAM_COLUMN_POWER_PASS writes=2700 physical_words=8100 final_words=2700
mismatches=0 active_cycles=7438
```

The two SAIFs cover the same active interval: `DURATION=23,457,827,000 fs`
(23.457827 us), about 7,436.1 constrained clock periods, with 14,875 clock
transitions. The testbench counted 7,438 active cycles; the small difference is
at the start/end measurement boundaries. The DUT-only SAIF directly matched
14,370/14,622 design nets (98.28%); the top-level SAIF matched 14,622/14,622
(100%). Vivado reported High confidence. The clock-activity warning is
expected: `read_saif` ignores SAIF activity on clock nets and uses the clock
constraint from the routed design.

| P3F corner | Dynamic | Device static | Total on-chip | Confidence |
| --- | ---: | ---: | ---: | :---: |
| Typical | 0.818 W | 0.596 W | 1.414 W | High |
| Maximum | 0.818 W | 0.822 W | 1.640 W | High |

Typical dynamic-power breakdown is 0.032 W clocks, 0.101 W CLB logic,
0.175 W signals, 0.016 W DSP, and 0.493 W I/O. The top-level currently
contains 253 package I/O ports; I/O alone is about 60% of reported dynamic
power. Thus this is a valid P3F estimate for the implemented `Conv` top-level
and its current pin/activity assumptions, not an isolated datapath-power
measurement. No SDF/glitch activity is included, and this is a tool estimate,
not a board measurement.

At the common 317 MHz operating point, 7,438 active cycles correspond to
approximately 23.464 us. For 145,800 equivalent operations, this is about
6.214 GOPS. Using the rounded Vivado power values gives approximately
19.19 uJ dynamic and 33.18 uJ total per job at Typical; 131.6 pJ/op dynamic
and 227.6 pJ/op total. Maximum-corner total energy is approximately 38.48 uJ
per job (263.9 pJ/op). These derived energy values are estimates and inherit
the rounded power report values.

Against the earlier Explore + post-route phys-opt implementation of this
same m18 workload, the new route reduces estimated dynamic power from 0.881 W
to 0.818 W (-0.063 W, about -7.2%). The I/O component remains 0.493 W; most of
the reduction is in clock and signal power. The two power estimates are from
different routed DCPs, while both use the same workload, power method and
operating corners.

## Preserved reports

Text-only Vivado reports and the implementation log are under
[`reports/ifn9-netdelay-high-231d0dcf/ifn9_m18/`](../reports/ifn9-netdelay-high-231d0dcf/ifn9_m18/).
The full routed DCP, functional netlist, and SAIFs remain on Paxos, not in
Git. The local report directory also contains the Typical/Maximum P3F reports,
operating-condition reports, checksums, metadata, and both Xcelium logs.
