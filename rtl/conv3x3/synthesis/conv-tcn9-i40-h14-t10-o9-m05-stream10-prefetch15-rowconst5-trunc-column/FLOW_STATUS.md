# ASIC flow status — TCN9 m5

Run on Paxos from commit `f7c32122eb67f41ef8bd90a6d427ef8f74ab0616`, with Genus 21.12 and Xcelium 23.03, using the 2 ns testbench clock.

| Stage | Result |
| --- | --- |
| Genus synthesis and reports | Completed |
| Gate-level simulation with nominal SDF | **Failed golden: 9 mismatches** |
| Gate-level simulation without SDF (diagnostic) | Passed; 8,100 writes, no golden mismatch |
| Joules power report | Generated, but **invalid for comparison** because the SDF simulation failed golden |

The SDF run annotated 100% of path delays. Its nine mismatches are all in output channel 2, rows 27–29, columns 27–29. The SDF job reached `p_end` in 10,127 cycles; the no-SDF diagnostic reached it in 10,137 cycles. These timing-simulation values are diagnostic only.

Do not use `power/power_evaluation.txt` as a valid workload-power result. The reports and logs are retained under `logical/results/reports/`, `logical/genus.log`, `sim/xrun.log`, and `sim/diagnostics/` for investigation.
