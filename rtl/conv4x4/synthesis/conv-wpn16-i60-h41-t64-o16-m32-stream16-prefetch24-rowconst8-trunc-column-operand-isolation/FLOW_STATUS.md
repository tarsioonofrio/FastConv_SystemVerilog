# WPN16 m32 prefetch24 operand-isolation experiment

This is a separate experiment; the original WPN16 RTL and its baseline reports
remain unchanged. `prefetch24` means 24 feature words, or four prefetched
columns for this 4x4 core. The RTL change holds each feature-bank next-value
input at its current register value when that word is not being captured; the
register write-enable logic is unchanged.

## Configuration and functional validation

| Item | Value |
| --- | --- |
| Local commit | `7f5b6e40dae263823c4504423997b200c64d20b5` |
| Variant RTL SHA-256 | `9d62582bd67009ecaa5b3ef77ef9f4f240f45ada6fb788a48494b045aabde4d0` |
| Base RTL SHA-256 | `7a69f28f029ef76cd758925a5b5b9fc3294f177b3ca73bf2a9699e8e275a6914` |
| Target | WPN16, 32 MACs, `prefetch24`, `NBITS=20` |
| Dataset | `sim-032-3-3-normal-trunc`, canonical WPN16 package |
| Host / tools | Paxos; Genus 21.12-s068_1; Xcelium 23.03-s003 |
| Clock constraint | 2 ns |
| Verilator RTL | PASS; 8,100 valid writes, 5,387 accepted-start-to-end cycles |
| Post-synthesis SDF gate simulation | PASS; golden checker completed, 8,100 valid writes, 5,387 accepted-start-to-end cycles |
| SDF annotation | 0 errors, 28,724 warnings; `SDFINF` warnings reached the simulator print limit and are a fidelity caveat |

The gate-level testbench checks all final output words against the canonical
golden. Its `inverse_tiles=0` field is not an assertion in `GATE_LEVEL` mode;
the mode-specific final golden comparison and valid-write count are the checks
that determine pass/fail.

## Synthesis and timing

| Metric | Baseline | Operand isolation |
| --- | ---: | ---: |
| Cell count | 37,479 | 37,131 |
| Cell area (um^2) | 47,555.298 | 47,695.032 |
| Total area (um^2) | 66,524.807 | 66,628.126 |
| Total flip-flops | 3,945 | 3,945 |
| Clock-gated flip-flops | 3,933 (99.70%) | 3,939 (99.85%) |
| Slow-corner WNS | +1 ps | +4 ps |

Both implementations meet the 2 ns constraint in the reported slow corner;
the critical endpoint remains `p_output_data_write[79]`.

## Typical-corner power

Values are from Joules at TT, 0.90 V / 25 C, using the same job window and
power-report categories.

| Category | Baseline dynamic (mW) | Operand isolation dynamic (mW) | Delta (mW) |
| --- | ---: | ---: | ---: |
| Register | 3.643968 | 3.830569 | +0.186601 |
| Logic | 8.202230 | 11.493740 | +3.291510 |
| Clock | 0.223689 | 0.297348 | +0.073659 |
| **Dynamic total** | **12.069890** | **15.621660** | **+3.551770 (+29.43%)** |
| Leakage | 0.210697 | 0.210869 | +0.000172 |
| **Total power** | **12.280600** | **15.832500** | **+3.551900 (+28.92%)** |

The experiment did not reduce power. Most of the increase is in logic dynamic
power. Added feedback/selection logic is a plausible contributor, but this
report alone does not prove causality. Because the candidate also has
substantially more SDF annotation warnings than the baseline, treat the
power delta as a diagnostic result rather than a final promoted measurement.

The complete generated reports and logs are retained in the corresponding
`logical/results/`, `sim/`, and `power/` directories on the Paxos experiment
snapshot and in the persistent Paxos results directory. The main Git-tracked
summary is this file plus `power/power_evaluation.txt` and the selected text
reports.
