# ASIC configurations (prepared, not executed)

This directory contains runnable ASIC flow configurations that do not yet
have ASIC execution artifacts. They are deliberately kept outside
`synthesis/`; only executed flows and their results belong there.

The `asic-sweep-*` directories target the parameterized scalar `conv.sv`
baselines. The `asic-stream-column-*` directories target generated streaming-
column RTL and use the 20-bit truncated dataset. None of these directories is
evidence of a completed Genus, Xcelium, or Joules run.

To run the prepared streaming-column TCN16 m12/m18 pair on Paxos, first
publish/check out the intended commit and then launch this script inside
`tmux`:

```bash
cd rtl/conv4x4/asic_configs
tmux new-session -d -s tcn16_column_asic ./run_tcn16_column_asic.sh
```

The two configurations are `asic-stream-column-20261003-tcn16-m12/` and
`asic-stream-column-20261003-tcn16-m18/`. They use the nominal 500 MHz clock
constraint, `sim-032-3-3-normal-trunc` (`NBITS=20`, `QUANT=8`, `seed=0`), and
the order Genus -> SDF-annotated Xcelium -> Joules. The FPGA-generated
`NBITS=16` package is intentionally not used in these prepared ASIC configs.
