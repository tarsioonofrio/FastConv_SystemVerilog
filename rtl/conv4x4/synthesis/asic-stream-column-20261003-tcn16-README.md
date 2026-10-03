# ASIC flow: TCN16 streaming-column m12/m18

These two configurations synthesize the generated streaming-column RTL, not
the parameterized scalar `conv.sv` used by the separate
`asic-sweep-20261003-tcn16-m12/m18` configurations. They use the same TSMC 28 nm
Genus/Xcelium/Joules setup, nominal 500 MHz clock constraint, truncated
weight-transform contract, and 20-bit workload as the ASIC baseline.

The run order for each variant is:

1. Genus synthesis and timing/power reports for slow, typical, and fast views;
2. nominal-corner gate-level Xcelium simulation with SDF back-annotation and
   golden-output checks against the column testbench;
3. Joules power analysis from `dut.shm` at the typical 0.90 V / 25 C view.

On the Paxos, after checking out the exact published commit and loading the
Cadence environment, run the combined flow inside `tmux`:

```bash
cd rtl/conv4x4/synthesis
tmux new-session -d -s tcn16_column_asic ./run_tcn16_column_asic.sh
```

The per-variant directories are:

```text
asic-stream-column-20261003-tcn16-m12/
asic-stream-column-20261003-tcn16-m18/
```

Each preserves the mapped netlist, three SDF corners, timing/area reports,
Xcelium log and SDF log, `dut.shm`, and `power_evaluation.txt`. The 12- and
18-multiplier runs use 2 and 3 Hadamard rows per cycle, respectively. The
dataset is `sim-032-3-3-normal-trunc` (`NBITS=20`, `QUANT=8`, `seed=0`).

The FPGA-generated `NBITS=16` dataset is deliberately not used here, so the
ASIC results remain comparable to the existing 20-bit ASIC campaign.
