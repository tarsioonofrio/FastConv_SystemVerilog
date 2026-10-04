# ASIC configurations (prepared, not executed)

These are runnable ASIC configurations that do not yet contain evidence of a
completed flow. They are kept outside `synthesis/`, which is reserved for
executed campaigns and their results.

The `conv/asic-sweep-*` directories target the parameterized scalar
`rtl/conv3x3/archive/conv.sv` baselines. They are grouped under `conv/`
because they share the archived generic `conv.sv` RTL rather than targeting a
dedicated RTL file. Do not treat their presence as evidence of Genus, Xcelium,
or Joules execution. The sweep entry point is `scripts/run_asic_sweep.sh`;
`scripts/prepare_asic_sweep.py` creates or updates the configurations there.
