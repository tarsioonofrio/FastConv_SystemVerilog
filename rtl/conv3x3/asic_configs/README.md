# ASIC configurations (prepared, not executed)

These are runnable ASIC configurations that do not yet contain evidence of a
completed flow. They are kept outside `synthesis/`, which is reserved for
executed campaigns and their results.

The `asic-sweep-*` directories target the parameterized scalar
`rtl/conv3x3/conv.sv` baselines. Do not treat their presence as evidence of
Genus, Xcelium, or Joules execution. The sweep entry point is
`scripts/run_asic_sweep.sh`; `scripts/prepare_asic_sweep.py` creates or updates
the configurations here.
