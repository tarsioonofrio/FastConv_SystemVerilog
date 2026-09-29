# Exact-pipelined stream08: FPGA flow result

## Provenance

- Source commit: `d031bbaa895099eabe86252fe13efa1e629b0bd3`
- Host: Paxos (`paxos.inf.pucrs.br`)
- Device: ZCU104 / `xczu7ev-ffvc1156-2-e`
- Vivado: 2023.2 (build 4029153)
- Xcelium: 23.03-s003
- Flow: post-route functional simulation, no SDF, followed by SAIF-based `report_power`
- Workload: `sim-032-3-3-normal-exact/pack_data.sv`
- Workload SHA-256: `1710c628fc21f5cab601002de35385a3ae5b634ded56e1e93ba83d1a83b3ac06`
- RTL SHA-256: `963fc75e40f39eef6093caae9b871ad608fea8684cdcd18d98e06bbcc5aafbf4`
- Flow exit code: `0`

## Implementation at the common clock constraint

The XDC requests 3.154574 ns. Vivado reports the implemented period rounded to
3.155 ns (316.957 MHz). The post-route timing summary reports WNS `+0.001 ns`,
TNS `0.000 ns`, and no failing endpoints. This is a timing PASS with essentially
no margin; it is not an Fmax search.

| Resource | Post-route use |
| --- | ---: |
| DSP | 8 |
| LUT | 2,961 |
| FF | 1,270 |
| RAMB36 / RAMB18 / URAM | 0 / 0 / 0 |
| Power-report I/O models | 101 |

Worst path is `r_transform_feature_reg_reg[0][15]` to
`r_inverse_partial_current_reg[0][15]`. It crosses the exact multiplier's
DSP48E2 and inverse/reduction logic: 10 logic levels, 3.059 ns data-path delay
(1.987 ns logic, 1.072 ns routing). This is the registered feature -> Hadamard
multiply -> inverse partial register boundary added by the pipeline correction.

## Functional and activity validation

Post-implementation functional simulation passed against the exact-arithmetic
golden:

```text
POWER_RESULT PASS writes=8100 final_words=2700 mismatches=0 active_cycles=25628
```

The SAIF window starts at `p_start` (`246012 ps`) and ends at `p_end`
(`81075247 ps`). Its duration is `80829235000 fs`, or `80829235 ps`
(`80.829235 us`). The clock
has `51256` transitions, exactly `2 x 25628` active cycles. `p_end`, output
writes, all final outputs, and golden comparison were observed in the same
Xcelium run.

Vivado matched `7041/7141` nets from the DUT-only SAIF and `7141/7141` after
the top-level SAIF was also read (100% combined coverage; High confidence).
The clock activity from SAIF is ignored by Vivado and comes from the XDC clock
constraint, as intended. The timing SAIF/SDF flow was not used.

## Power estimate

Vivado post-route estimates, in watts:

| Method / corner | Dynamic | Device static | Total | Confidence / coverage |
| --- | ---: | ---: | ---: | --- |
| P0 vectorless / typical | 0.188 | 0.593 | 0.780 | Low / N/A |
| P3F functional SAIF / typical | 0.256 | 0.593 | 0.849 | High / 7141 of 7141 |
| P0 vectorless / maximum | 0.188 | 0.813 | 1.001 | Low / N/A |
| P3F functional SAIF / maximum | 0.256 | 0.814 | 1.070 | High / 7141 of 7141 |

Typical P3F dynamic breakdown is `0.012 W` clocks, `0.023 W` CLB logic,
`0.039 W` signals, `0.006 W` DSP, and `0.176 W` I/O. Thus the current scalar
top-level still models its memory/control buses as package I/O; I/O is about
69% of dynamic power. This is a valid estimate for this implemented top-level,
not an OOC core-only power result or a board measurement.

For reference, P3F dynamic power is `0.068 W` (36.2%) above the same design's
P0 vectorless estimate. Device static power is effectively unchanged between
the two activity methods within each corner.

Using 145,800 equivalent operations per job, 25,628 active cycles, and
316.957 MHz gives an active-job throughput of approximately `1.803 GOPS`.
Multiplying P3F power by the measured SAIF window gives approximately
`20.69 uJ` dynamic and `68.62 uJ` total per job. These are tool-estimated
values for this top-level and exact workload. The corresponding power-normalized
figures are `7.04 dynamic GOPS/W` and `2.12 total GOPS/W`.

## Main artifacts

- `design_routed.dcp` SHA-256: `8172a27cc1b2d77f0b626d3a3b4d177a60975c4a856a0decf48117b52fc8a237`
- `design_routed_funcsim.v` SHA-256: `53faf2c32609db5913da116f3b10cb1b5851ab1968a4b72d3bc996ea686f4223`
- `dut/activity_dut.saif` SHA-256: `5eb680adeb275367712670a64557c584f608824dc7bef91dad2dec7e338e93a9`
- `top/activity_top.saif` SHA-256: `dad8ab7c965615105020848725a2b734d7dfdcd37ee567d2aceab18bf03313fe`

Full logs, reports, SAIF files, netlists, checkpoints, and the exact run script
are retained in this directory. The persistent Paxos checkout was not modified;
the flow ran from a clean worktree at the source commit above.
