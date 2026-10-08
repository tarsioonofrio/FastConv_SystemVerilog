# ASIC power flow status — TCN16 m18

Complete ASIC power flow executed on 2026-10-05 from an isolated snapshot of
commit `42affe7206fb137ae5f48fad6b7d91a58ad58f4c` on Paxos. Tools: Genus
21.12-s068_1 and Xcelium 23.03-s003. Long jobs ran inside tmux. RTL SHA-256:
`e5308dffb489206c23a9e3c6ac8606c241ebe8b1d7f375bde8ba8eb0e1fe262b`.

| Stage | Result |
| --- | --- |
| Genus synthesis | Normal exit; refreshed netlist, SDF, area, and timing reports; netlist and nominal SDF preserved in `logical/results/gate_level/run_20261005/` |
| Slow-corner setup | MET, WNS 0 ps at 0.81 V / 125 C; limiting path is `r_weight_spatial_reg[6][2]` through `WEIGHT_TRANSFORM_ROWS[3].weight_trf_row` / `f_floor_div` to `r_input_weight_reg[6][16]` |
| Typical-corner setup | MET, WNS +226 ps at 0.90 V / 25 C |
| Cell count / cell area / total area | 71,026 / 79,180.794 / 111,426.449 um^2 |
| SDF gate simulation | PASS; 0 annotation errors, 4,084 warnings; 8,100 valid writes, zero golden mismatches |
| Accepted `p_start` to `p_end` | 5,387 cycles = 10.774 us at 2 ns/cycle |
| Joules power (TT, 0.90 V / 25 C) | Dynamic 10.60519 mW; leakage 0.416727 mW; total 11.0219 mW |

Dynamic power breakdown: register 2.904773 mW, logic 7.499890 mW, and clock
0.200524 mW. The detailed report also contains leakage/internal/switching
columns for each category.

The SDF warnings include attempts to annotate `RECREM` timing checks absent
from the corresponding cell models and negative timing-check convergence
warnings. They are nonzero and remain part of the evidence; the run had no SDF
annotation errors and the testbench golden check passed. Detailed Genus, Xrun,
timing, area, and Joules outputs are kept in this configuration's `logical/`,
`sim/`, and `power/` directories.
