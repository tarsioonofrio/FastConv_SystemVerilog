# WPN16 transformed row-stream column: Cin=3, Cout=12

RTL: `rtl/conv4x4/conv-wpn16-i60-h41-t64-o16-m32-stream16-prefetch24-transformed-rowstream-column.sv`.

Workload package: `rtl/conv4x4/data/wpn16/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv`.

Overrides: `NUM_MULT=32`, `STATE_MULT=2`, `NBITS=16`, `N_CHANNEL_IN=3`, `N_CHANNEL_OUT=12`, `QUANT=8`. WPN weights are pretransformed integer values; there is no fractional-weight extension.

RTL simulation was run with Verilator 5.050 and passed the golden checks.

## ASIC logical synthesis

Genus 21.12-s068_1 synthesis completed on Paxos on 2026-10-12. The flow used
the project TSMC28 MMMC setup and a 2.0 ns clock constraint (500 MHz), with
1.0 ns input and output delays.

| Metric | Result |
| --- | ---: |
| Mapped cells | 28,467 |
| Cell area | 35,293.230 um^2 |
| Net area | 14,259.308 um^2 |
| Total area | 49,552.538 um^2 |
| Sequential cells | 3,624 |
| Sequential area | 8,419.446 um^2 |
| Logic area | 26,246.934 um^2 |

In the slow corner (0.81 V, 125 C), the worst reported path is marked MET
with 12 ps slack. It is an output-boundary path from
`r_output_write_count_reg[1]` to `p_output_data_write[63]`, constrained by
the 1.0 ns output delay. It is not a path through the transform/Hadamard/
inverse pipeline. The nominal and fast-corner slacks are 234 ps and 404 ps.

This is logical synthesis only; no gate-level simulation or power analysis
has been run for this configuration. Results are under `logical/results/`.

Provenance: RTL/configuration commit `881a73a8`; Genus ran in the existing
Paxos checkout whose HEAD was `83ce36ec` and whose unrelated working tree was
dirty. Before execution, hashes of every HDL dependency listed in
`list-file.txt` matched the local committed files, and the new RTL/config
paths did not exist remotely. Only those new paths were copied; the existing
Paxos checkout was not reset or otherwise cleaned.
