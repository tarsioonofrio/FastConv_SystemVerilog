# OOC multicore capacity experiment

This experiment estimates how many independent IFN9 m06 and WPN16 m08 cores
fit and meet the common 317 MHz register-to-register timing target on the
XCZU7EV. It is an IP/fabric capacity result, not a complete board-level system
result: each replica has its own logical memory boundary, while clock, reset,
and start are shared. The top is synthesized Out-of-Context, so package I/O
buffers and a physical memory system are not included.

Distinct per-core input and feedback buses, plus per-core observable output
buses, prevent synthesis from merging duplicate cores. There are no `KEEP` or
`DONT_TOUCH` directives. The same 317 MHz clock XDC and Vivado 2023.2 are used
for both algorithms. P3F/power is not part of this capacity sweep.

Run the (potentially long) count sweeps from a persistent `tmux` session on
Paxos after publishing the exact source commit and creating a clean temporary
worktree pinned to it:

```bash
bash rtl/stream-column/fpga_zcu104/multicore/run_capacity_sweep.sh \
  "$PWD" /sim/tarsio/reports-multicore-<commit> ifn9 1 8 16 24 32 40 44 48
bash rtl/stream-column/fpga_zcu104/multicore/run_capacity_sweep.sh \
  "$PWD" /sim/tarsio/reports-multicore-<commit> wpn16 1 4 8 12 16 20 24
```

Each run records synthesis/routed utilization, full timing summary, critical
paths, clock utilization, DRC, metadata, and a compact timing result. Start
with the listed coarse counts, then route additional counts near the largest
passing candidate to locate the limit. The maximum reported as timing-capable
must be the largest routed design with WNS >= 0 at 317 MHz; also report the
next tested count and whether it failed from resource exhaustion or timing.
