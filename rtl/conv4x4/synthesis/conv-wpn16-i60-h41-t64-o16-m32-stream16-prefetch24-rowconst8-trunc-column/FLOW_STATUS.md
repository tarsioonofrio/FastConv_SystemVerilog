# ASIC flow status — WPN16 m32

The original gate-level mismatch was caused by an undersized input-window
terminal counter, not by the WPN16 datapath or by SDF timing. With a 4x4
workload over a 32x32 input, the input-window count is 64. The counter must
represent the inclusive range 0..64; `clog2(64)` produced only six bits and
could not represent the terminal value. In the mapped netlist, the terminal
comparison consequently behaved as if the initial count were already terminal,
so input addressing started at the out-of-range sentinel address 4096.

The RTL and shared generator template now size the counter with
`clog2(TOTAL_WINDOWS + 1)`. The fix was committed as
`27452839bca35c53bcdb336e8a2a4a539dd6063b` and synthesized on Paxos with
Genus 21.12. The regenerated netlist and nominal SDF were used for both gate
simulations below.

The same width correction has also been propagated to the other checked-in
4x4 TCN16/WPN16 RTL variants generated from this core template. The detailed
gate-level validation in this report is specifically for WPN16 m32 with
`prefetch24`; the sibling variants still need their own regenerated ASIC
flows before their historical gate-level/power results are treated as current.

| Stage | Result |
| --- | --- |
| Genus synthesis | Completed; `Normal exit`, 0 errors and 0 fatals |
| RTL simulation, canonical truncated WPN16 workload | Passed; 8,100 writes, no mismatch |
| Gate-level simulation without SDF | Passed; 8,100 writes, golden checker passed, Xcelium exit 0 |
| Gate-level simulation with nominal SDF | Passed; 8,100 writes, golden checker passed, Xcelium exit 0 |
| Accepted `p_start` to `p_end` | 5,386 cycles (10.772 us at 2 ns) |
| Testbench completion counters | `cycles_to_end=5427`, `cycles=5429` |
| Joules power report | Rerun after corrected synthesis and passing SDF simulation; see `power/power_evaluation.txt` |

## Completed ASIC power flow (2026-10-05)

The complete flow was rerun from an isolated snapshot of commit
`42affe7206fb137ae5f48fad6b7d91a58ad58f4c` on Paxos, using Genus 21.12-s068_1
and Xcelium 23.03-s003. Long jobs ran inside tmux. The RTL SHA-256 was
`7a69f28f029ef76cd758925a5b5b9fc3294f177b3ca73bf2a9699e8e275a6914`.

| Stage | Result |
| --- | --- |
| Genus synthesis | Normal exit; refreshed netlist, SDF, area, and timing reports; netlist and nominal SDF preserved in `logical/results/gate_level/run_20261005/` |
| Slow-corner setup | MET, WNS +1 ps at 0.81 V / 125 C; limiting path is `r_output_write_count_reg[1]` to `p_output_data_write[79]` under the output-delay constraint |
| Typical-corner setup | MET, WNS +223 ps at 0.90 V / 25 C |
| Cell count / cell area / total area | 37,479 / 47,555.298 / 66,524.807 um^2 |
| SDF gate simulation | PASS; 0 annotation errors, 5,546 warnings; 8,100 valid writes, zero golden mismatches |
| Accepted `p_start` to `p_end` | 5,387 cycles = 10.774 us at 2 ns/cycle |
| Joules power (TT, 0.90 V / 25 C) | Dynamic 12.06989 mW; leakage 0.210697 mW; total 12.2806 mW |

Dynamic power breakdown: register 3.643968 mW, logic 8.202230 mW, and clock
0.223689 mW. The detailed report also contains leakage/internal/switching
columns for each category.

The SDF warnings include attempts to annotate `RECREM` timing checks absent
from the corresponding cell models and negative timing-check convergence
warnings. They are nonzero and remain part of the evidence; the run had no SDF
annotation errors and the testbench golden check passed. The previous
2026-10-04 WPN power report came from a gate run with 120 golden mismatches.
It is preserved under `power/diagnostics/pre_power_rerun_20261004/` and must
not be used as the valid power result.

The SDF run still emits SDF annotation/timing-check and glitch warnings. They
did not prevent the functional golden check from passing, but the simulation
should not be described as warning-free. On Paxos, the corrected run logs are
`sim/xrun.log`, `sim/diagnostics/gate_fix_sdf_run.log`, and
`sim/diagnostics/gate_fix_nosdf_run.log`; the failed original run is preserved
under `sim/diagnostics/pre-terminal-width-fix/`.
