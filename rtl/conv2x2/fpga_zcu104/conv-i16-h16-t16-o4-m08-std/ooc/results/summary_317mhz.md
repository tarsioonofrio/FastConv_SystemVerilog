# OOC FPGA pilot result at 317 MHz

Status: completed and functionally validated as an IP-level pilot. This is not
the final thesis architecture and is not a board-level or complete-system
power result. The BRAM-wrapper experiment remains separate and unchanged.

## Reproducibility

| Item | Value |
| --- | --- |
| Local source commit | `52fb8b8342d47f3c586609f8fcd8dfab59207923` |
| Remote run | `paxos.inf.pucrs.br`, isolated worktree `/tmp/fastconv-ooc-52fb8b83` |
| Remote run commit | `52fb8b8342d47f3c586609f8fcd8dfab59207923` (same tree and commit) |
| Vivado | 2023.2, build 4029153 |
| Xcelium | 23.03-s003 |
| Device | `xczu7ev-ffvc1156-2-e` (ZCU104 / XCZU7EV) |
| OOC top | `Conv` |
| Target clock | 317.000 MHz; XDC period 3.154574 ns |
| Simulation clock | 3.154 ns after 1 ps timeprecision rounding; 317.058 MHz |
| Workload | canonical `sim-032-3-3-normal`, 32x32, Cin=3, Cout=3, 3x3, seed 1 |
| Workload SHA-256 | `3ced5c4527374898e1f8d65c275403e1366e2bb09f466542915656b263356da0` |
| Frozen core SHA-256 | `94939147b92d1ac5313c46825d0c14da9ac67c7e2180288c05e02806cd93bde0` |
| Testbench SHA-256 | `3c82af0c0325d880a3da07df15bbe1acb63bb3718ffcb557e4edbdd0c6ba0156` |
| Routed OOC DCP SHA-256 | `81b6e91b1d836ecdcfe3234d1acc363f4d6a669f7062896900570fa1146fb330` |
| Functional netlist SHA-256 | `571ed6a7bd59484a704581972a7e4f41b19b7e4a63ad99f164c0cb8354d482c0` |
| Internal-scope SAIF SHA-256 | `82c2e66f520bbd4a49bdb65ddf26c2c9af2d0ba37d448ffcd305e4347e396e2f` |
| Ports SAIF SHA-256 | `df5b69d873710c7ff499a8f715e272cba0a6aa28b86aaff3cff857bfe2213621` |

The implementation and power runs were launched in `tmux`. The existing
persistent Paxos checkout was not modified. No VCD, FST or SDF was generated
for this functional-SAIF run.

## Implementation and timing

| Resource / metric | Post-route result |
| --- | ---: |
| LUT | 2,124 |
| FF | 1,263 |
| DSP | 8 |
| RAMB36 / RAMB18 / URAM | 0 / 0 / 0 |
| `IBUF*`, `OBUF*`, `IOBUF*` cells | 0 |
| Worst internal register-to-register slack | +0.247 ns |
| Input-boundary worst slack | +1.793 ns* |
| Output-boundary worst slack | +0.770 ns* |
| Unconstrained synchronous endpoints | 0 reported |

`*` Boundary reports use zero external input/output delays. Vivado emitted 44
`Route 35-198` warnings that ports lacked `HD.PARTPIN_LOCS`; it explicitly
warns that timing to/from those ports is not accurate without partial routing.
Therefore the boundary slack values are diagnostic under the stated
assumptions, not a system-level timing guarantee. The internal
register-to-register path is the timing-closure evidence for this OOC run.
No OOC Fmax is claimed.

`report_io` lists 101 logical top-level bits as user I/O. This does not
contradict the zero-buffer audit: they are OOC IP interface ports, not
implemented package I/O buffers. The core itself contains no BRAM, so zero
BRAM utilization is expected; the feature/weight/output memories remain
outside this IP characterization.

## Post-implementation functional simulation and SAIF

The routed functional netlist was simulated with Xcelium and the original
combinational-memory testbench semantics. Both internal-scope and port-scope
runs completed with:

```text
cycles=23658 writes=8100 expected_writes=8100 tiles=2025 golden_errors=0
```

The reported 23,658 cycles include startup/reset and protocol cycles; the
validated active-job latency remains 23,648 core cycles. The port SAIF capture
started when `p_start` asserted at 246,012 ps and stopped when Xcelium
observed `p_end` at 74,830,327 ps. Its duration is 74,584,315 ps, or
23,647.53 periods at the simulation period of 3,154 ps. The SAIF reports
47,295 clock transitions. The half-cycle-scale difference is consistent with
capture boundaries landing between clock edges. The simulation frequency is
317.058 MHz, 0.0182% above the 317 MHz implementation target.

Vivado `read_saif` matched 5,291/5,291 candidate nets (100%) for both Typical
and Maximum reports, with High overall confidence. The clock remains governed
by the XDC. P3F is post-implementation functional activity and does not
capture SDF timing glitches.

## OOC power

Vivado reports on the routed OOC DCP, using port-scope post-implementation
functional SAIF:

| Corner | Clocks | CLB logic | Signals | DSP | BRAM | I/O category | Dynamic | Device static | Total | Confidence |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| Typical | 0.013 W | 0.034 W | 0.030 W | 0.010 W | 0 W | not reported | 0.087 W | 0.592 W | 0.679 W | High |
| Maximum | 0.013 W | 0.034 W | 0.030 W | 0.010 W | 0 W | not reported | 0.087 W | 0.811 W | 0.898 W | High |

The absence of an I/O power row follows the zero I/O-buffer implementation;
it does not mean that logical input ports had no activity. Vivado states that
more than 95% of input/I/O nodes had user-specified activity. The reported
`Device Static` is the static power estimate of the device, not an intrinsic
static component of the isolated Conv IP. For this reason, this report does
not claim IP-level total energy, GOPS/W or pJ/op.

## Comparison with the earlier full-top P3F

The earlier non-OOC P3F report measured 0.281 W dynamic, including 0.182 W in
the physical I/O category; subtracting that category gives 0.099 W for the
other modeled components. OOC reports 0.087 W dynamic and no I/O component.
That is directionally consistent with removing package I/O buffers, though
the 12 mW difference in the remaining modeled components means the two routed
implementations are not numerically interchangeable. This confirms why the
OOC number should be treated as a new IP-level implementation result, not a
post-hoc correction of the earlier report.

## Preserved artifacts

All source logs, checkpoints, routed functional netlist, SAIF files, mapping
reports, timing reports, utilization/I/O audit and Typical/Maximum power
reports are in `../reports/317mhz/`. The implementation and Xcelium logs
contain the exact commands, run timestamps and tool diagnostics.
