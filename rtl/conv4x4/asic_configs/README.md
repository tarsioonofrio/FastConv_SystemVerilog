# ASIC configurations (prepared, not executed)

This directory contains runnable ASIC flow configurations that do not yet
have ASIC execution artifacts. They are deliberately kept outside
`synthesis/`; only executed flows and their results belong there.

The `conv/asic-sweep-*` directories target the parameterized scalar
`archive/conv.sv` baselines. They are grouped under `conv/` because they share
the archived generic RTL rather than targeting dedicated RTL files. The dedicated TCN16
directories at this level target generated streaming-column RTL and use the
20-bit truncated dataset. None of these directories is evidence of a completed
Genus, Xcelium, or Joules run.

To run the prepared streaming-column TCN16 m12/m18 pair on Paxos, first
publish/check out the intended commit and then launch this script inside
`tmux`:

```bash
cd rtl/conv4x4/asic_configs
tmux new-session -d -s tcn16_column_asic ./run_tcn16_column_asic.sh
```

The two configurations are
`conv-tcn16-i60-h21-t24-o16-m12-stream12-prefetch24-rowconst6-trunc-column/`
and
`conv-tcn16-i60-h27-t36-o16-m18-stream12-prefetch24-rowconst6-trunc-column/`.
Each directory matches its RTL basename. They use the nominal 500 MHz clock
constraint, `sim-032-3-3-normal-trunc` (`NBITS=20`, `QUANT=8`, `seed=0`), and
the order Genus -> SDF-annotated Xcelium -> Joules. The FPGA-generated
`NBITS=16` package is intentionally not used in these prepared ASIC configs.
