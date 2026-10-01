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
- Temporary sparse worktree: `/tmp/fastconv-ifn9-netdelay-231d0dcf`

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

This result validates **post-route timing only**. Xcelium post-implementation
functional simulation, SAIF capture, and P3F power were not rerun on this new
routed DCP; do not substitute its power/performance metrics for the earlier
campaign until those checks are completed.

## Preserved reports

Text-only Vivado reports and the implementation log are under
[`reports/ifn9-netdelay-high-231d0dcf/ifn9_m18/`](../reports/ifn9-netdelay-high-231d0dcf/ifn9_m18/).
The full routed DCP and functional netlist remain on Paxos, not in Git.
