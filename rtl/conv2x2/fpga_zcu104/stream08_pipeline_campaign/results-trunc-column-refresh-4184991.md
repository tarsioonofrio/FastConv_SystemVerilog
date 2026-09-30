# FPGA refresh after truncated-column prefetch fix

## Scope

The four truncated-column points were rerun at commit
`4184991c425803b5bd11adc591b864e6a876b5eb`, after changes to the m04 and m08
RTL. The matched configurations are 4/8 MACs at `NBITS=16/20`, on the same
XCZU7EV part, Vivado 2023.2, 317 MHz constraint, canonical width-matched
truncated workload, and post-implementation functional-SAIF (P3F) flow.

The persistent Paxos checkout was left untouched because it was old and dirty.
The campaign instead used a temporary source snapshot of the published commit
under `/tmp`, and the long Vivado/Xcelium jobs ran in `tmux`. The run outputs
have unique `refresh-4184991-*` names; prior reports remain unchanged. The
large DCPs, functional netlists, and SAIF files remain on Paxos and were not
copied into this repository.

## RTL changes since the previous comparison

Both `trunc-column` RTL variants changed in the same way:

- Added an elaboration-time guard that `NUM_MULT` equals the variant's fixed
  MAC count.
- Made prefetch issue one-shot while a transfer is active or the prefetch
  buffer is full, and cleared the active/full flags at row/address boundaries.
  This prevents the input FSM from reissuing the same prefetch during a long
  `CONV_INPUT` interval.
- Replaced the two-beat prefetch address multiply with a choice between offset
  zero and one input-column width.
- Made `OUTPUT_DATA_BLOCK` asynchronously reset `r_output_read`.
- Simplified a redundant branch that reset the raw-weight address to the same
  base in either case.

## Results: previous reports versus rerun

All four reruns passed post-implementation functional simulation with 8,100
writes, 2,700 final words, zero mismatches, and the same active-cycle count as
before. DSP count and workload latency did not change. Every refreshed design
meets the constrained 317 MHz timing point with zero setup-failing endpoints.

| Metric | m08, 20-bit | m08, 16-bit | m04, 20-bit | m04, 16-bit |
| --- | ---: | ---: | ---: | ---: |
| DSP, old -> new | 8 -> 8 | 8 -> 8 | 4 -> 4 | 4 -> 4 |
| LUT, old -> new | 3,170 -> 3,191 | 2,332 -> 2,346 | 2,980 -> 2,999 | 2,358 -> 2,338 |
| FF, old -> new | 1,484 -> 1,484 | 1,156 -> 1,092 | 1,243 -> 1,243 | 969 -> 968 |
| Routed WNS @317 MHz, old -> new | +0.048 -> +0.258 ns | +0.369 -> +0.423 ns | +0.289 -> +0.315 ns | +0.370 -> +0.507 ns |
| Active cycles, old -> new | 14,502 -> 14,502 | 14,502 -> 14,502 | 18,552 -> 18,552 | 18,552 -> 18,552 |
| P3F typical dynamic, old -> new | 0.388 -> 0.369 W | 0.295 -> 0.324 W | 0.343 -> 0.349 W | 0.288 -> 0.273 W |
| P3F typical static, old -> new | 0.594 -> 0.594 W | 0.593 -> 0.593 W | 0.594 -> 0.594 W | 0.593 -> 0.593 W |
| P3F typical total, old -> new | 0.982 -> 0.962 W | 0.889 -> 0.917 W | 0.936 -> 0.943 W | 0.881 -> 0.866 W |
| DUT SAIF direct match, new | 7,591/7,791 (97.43%) | 5,600/5,768 (97.09%) | 6,702/6,902 (97.10%) | 5,172/5,340 (96.85%) |
| Top SAIF direct match, new | 7,791/7,791 (100%) | 5,768/5,768 (100%) | 6,902/6,902 (100%) | 5,340/5,340 (100%) |

The complete power categories are in each run's `power_p3f_typical.rpt` and
`power_p3f_maximum.rpt`. At Typical, changes in dynamic power are primarily
visible in Signals and I/O, while device static remains unchanged. For
example, m08/16-bit I/O rises from 0.214 W to 0.237 W and Signals from 0.034 W
to 0.041 W; m08/20-bit I/O falls from 0.277 W to 0.256 W. This is why the
dynamic-power direction is not uniform across widths and MAC counts. The
reports establish the category deltas, but do not isolate one RTL statement as
the sole cause of every activity change.

The largest resource change is m08/16-bit FF, down by 64, while its LUT count
increases by 14. The refreshed power reports retain High confidence and 100%
top-level SAIF coverage. Direct DUT coverage remains about 97%; unmatched
internal nets are covered by Vivado's remaining activity propagation.

These P3F values are Vivado estimates based on a post-implementation
functional simulation (no SDF), not physical board measurements. The timing
reports verify the constrained 317 MHz paths; they do not add external
input/output delay budgets.

## Evidence

Refreshed report directories:

- `reports/refresh-4184991-m08-nbits20/`
- `reports/refresh-4184991-m08-nbits16/`
- `reports/refresh-4184991-m04-nbits20/`
- `reports/refresh-4184991-m04-nbits16/`
- `reports/refresh-4184991-campaign/runner.log`

Each per-variant directory retains utilization, timing, Typical/Maximum power,
SAIF mapping, input hashes, provenance, and Xcelium logs. Functional markers
were `POWER_RESULT PASS` for both DUT and top-level captures in all four runs.
