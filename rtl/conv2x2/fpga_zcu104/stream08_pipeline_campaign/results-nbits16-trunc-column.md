# Truncated-column FPGA comparison: NBITS=16 vs NBITS=20

## Scope and reproducibility

This comparison covers both 8-MAC and 4-MAC truncated-column implementations
at signed datapath widths of 16 and 20 bits. All four FPGA runs use the same
current RTL revision, target, clock, logical workload, quantization, truncation
rule, and post-route functional-SAIF power method. The 20-bit m08 was rerun:
the older checked-in 20-bit report came from an earlier RTL revision and is not
the matched-width baseline for this comparison.

| Item | Value |
| --- | --- |
| RTL repository commit for matched 16/20-bit runs | `b96155529160ddc00a32d27ed7178e92a0a83da2` |
| FPGA / part | ZCU104 / `xczu7ev-ffvc1156-2-e` |
| Vivado | 2023.2 |
| Xcelium | 23.03-s003 |
| Target clock | 317 MHz (`3.154574 ns`) |
| Workload | tcn4 F(2,3), 32x32, Cin=3, Cout=3, 3x3 kernel, seed=0 |
| Quantization | 8 bits |
| Weight transform | Truncated, arithmetic divide by scale 4 |
| Equivalent direct-convolution operations | 145,800 per job (`MAC=2 ops`) |

The 16-bit package declares its arrays as signed `[15:0]` and `NBITS=16`; the
20-bit comparison uses the existing signed 20-bit canonical truncated package.
Both use seed 0. The same NBITS=20 seed/configuration reproduced the existing
truncated workload's `d.txt`, `g.txt`, and `s.txt` byte-for-byte before
generation of the 16-bit dataset. The generator checkout was dirty at generation
time; its commit and hashes of the relevant generator/configuration files are
recorded in the 16-bit dataset provenance.

## Results

All four routed designs passed post-implementation functional simulation
against the matching width's golden package. Power is a Vivado estimate using
post-implementation functional SAIF (P3F), without SDF; it is not a physical
board measurement. The latency/throughput figures use the active job cycles
reported by the testbench and the common 317 MHz operating point.

| Metric | m08, 20-bit | m08, 16-bit | m04, 20-bit | m04, 16-bit |
| --- | ---: | ---: | ---: | ---: |
| DSP | 8 | 8 | 4 | 4 |
| LUT | 3,170 | 2,332 | 2,980 | 2,358 |
| FF | 1,484 | 1,156 | 1,243 | 969 |
| BRAM | 0 | 0 | 0 | 0 |
| Routed setup WNS at 317 MHz | +0.048 ns | +0.369 ns | +0.289 ns | +0.370 ns |
| Setup failing endpoints | 0 | 0 | 0 | 0 |
| Active job cycles | 14,502 | 14,502 | 18,552 | 18,552 |
| Active job time at 317 MHz | 45.748 us | 45.748 us | 58.524 us | 58.524 us |
| Equivalent throughput | 3.187 GOPS | 3.187 GOPS | 2.491 GOPS | 2.491 GOPS |
| Golden simulation | PASS, 0 mismatches | PASS, 0 mismatches | PASS, 0 mismatches | PASS, 0 mismatches |
| Writes / final output words | 8,100 / 2,700 | 8,100 / 2,700 | 8,100 / 2,700 | 8,100 / 2,700 |
| DUT SAIF direct match | 7,545 / 7,745 (97.42%) | 5,638 / 5,806 (97.11%) | 6,666 / 6,866 (97.09%) | 5,180 / 5,348 (96.86%) |
| Top-level SAIF direct match | 7,745 / 7,745 (100%) | 5,806 / 5,806 (100%) | 6,866 / 6,866 (100%) | 5,348 / 5,348 (100%) |
| Vectorless Typical dynamic / total | 0.285 / 0.879 W | 0.212 / 0.805 W | 0.247 / 0.840 W | 0.203 / 0.796 W |
| P3F Typical dynamic / static / total | 0.388 / 0.594 / 0.982 W | 0.295 / 0.593 / 0.889 W | 0.343 / 0.594 / 0.936 W | 0.288 / 0.593 / 0.881 W |
| P3F Maximum dynamic / static / total | 0.388 / 0.816 / 1.204 W | 0.295 / 0.814 / 1.110 W | 0.343 / 0.815 / 1.158 W | 0.288 / 0.814 / 1.102 W |
| Derived Typical dynamic / total energy per job | 17.75 / 44.92 uJ | 13.50 / 40.67 uJ | 20.07 / 54.78 uJ | 16.85 / 51.56 uJ |

Power components at Typical are:

| Component | m08, 20-bit | m08, 16-bit | m04, 20-bit | m04, 16-bit |
| --- | ---: | ---: | ---: | ---: |
| Clocks | 0.013 W | 0.013 W | 0.014 W | 0.012 W |
| CLB Logic | 0.033 W | 0.026 W | 0.027 W | 0.022 W |
| Signals | 0.056 W | 0.034 W | 0.040 W | 0.032 W |
| DSP | 0.009 W | 0.009 W | 0.006 W | 0.005 W |
| I/O | 0.277 W | 0.214 W | 0.257 W | 0.216 W |

The displayed component values are rounded to milliwatts; their rounded sum
may differ by 1 mW from Vivado's dynamic total. The designs have no inferred
BRAMs. The reported I/O count falls from 201 in both 20-bit runs to 169 in both
16-bit runs because narrower top-level buses reduce the number of physical
ports. I/O power is substantial because the original core interface remains
the FPGA top-level boundary; these are IP/top-level Vivado estimates, not a
claim about an eventual system wrapper.

The timing summaries report no unconstrained internal endpoints. The 20-bit
timing runs identify 124 inputs and 73 outputs without input/output delay
constraints; the 16-bit runs identify 100 inputs and 65 outputs. Therefore,
the positive WNS values establish closure for the constrained paths at 317 MHz;
they do not establish timing closure for an external interface with a specified
board-level input/output budget.

## Interpretation

Changing from 20 to 16 bits leaves the cycle counts and equivalent throughput
unchanged for each MAC count. It reduces LUTs by 26.4% and FFs by 22.1% for m08;
for m04, LUTs fall by 20.9% and FFs by 22.0%. DSP count is unchanged. WNS
improves by 0.321 ns for m08 and 0.081 ns for m04; the 20-bit m08 timing margin
is especially small at only 48 ps, although it has no failing setup endpoints.

The P3F dynamic estimate falls by 93 mW (24.0%) for m08 and 55 mW (16.0%) for
m04 when moving to 16 bits. Much of this reduction is at the I/O boundary: the
I/O component decreases by 63 mW for m08 and 41 mW for m04, as the ports narrow.
The remaining decrease comes from CLB logic/signals and, for m04, rounded clock
and DSP components. Since the job cycle counts are unchanged, the same relative
reductions appear in dynamic energy/job. Total power falls less because device
static power is nearly unchanged.

Within each width, m08 uses twice the DSPs and completes 4,050 cycles sooner
than m04, providing 28.0% more equivalent throughput. At 16 bits its P3F
dynamic estimate is 7 mW higher than m04, but its shorter runtime gives lower
dynamic energy/job (13.50 uJ versus 16.85 uJ). At 20 bits, m08 similarly has
higher dynamic power (0.388 W vs 0.343 W) but lower dynamic energy/job (17.75
uJ vs 20.07 uJ). All four P3F reports have Vivado `High` confidence.

For each P3F power run Vivado warns that the SAIF contains clock activity; that
activity is intentionally ignored because the 317 MHz clock is supplied by the
timing constraint. There are no critical warnings or errors. The matching
counts above distinguish direct DUT activity from full top-level annotation.

## Per-variant evidence

The following directories contain the utilization, routed timing, P3F and
vectorless power reports, logs, provenance, workload/RTL/constraint hashes,
and both DUT- and top-level Xcelium functional-simulation logs:

- `reports/prefetch8-rowconst4-trunc-column-nbits16/`
- `reports/prefetch8-rowconst4-trunc-column-nbits16-4mac/`
- `reports/prefetch8-rowconst4-trunc-column-current20/`
- `reports/prefetch8-rowconst4-trunc-column-4mac-current20/`

Large routed checkpoints, post-route netlists, SAIF files, and generated
Xcelium libraries remain in the clean Paxos worktree at the campaign hash;
they were not copied into the Git repository.
