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
| Joules power report | Not rerun after the corrected synthesis; previous report remains invalid for this netlist |

The SDF run still emits SDF annotation/timing-check and glitch warnings. They
did not prevent the functional golden check from passing, but the simulation
should not be described as warning-free. On Paxos, the corrected run logs are
`sim/xrun.log`, `sim/diagnostics/gate_fix_sdf_run.log`, and
`sim/diagnostics/gate_fix_nosdf_run.log`; the failed original run is preserved
under `sim/diagnostics/pre-terminal-width-fix/`.
