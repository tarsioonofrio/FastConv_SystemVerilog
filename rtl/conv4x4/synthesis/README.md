# ASIC synthesis configurations

This is the canonical home for 4x4 ASIC configs that participate in the
default report scope. Use `make list-configs ARCH=conv4x4` to see the current
directory set. The configuration directory is an experiment identity; its
name can include workload and precision suffixes in addition to the RTL stem.

The tree currently contains TCN16 rowconst and transformed-frac6 flows,
standard-column setup configs, and WPN16 8/16/32-MAC flows, including
transformed and inverse-accumulator experiments. Do not assume every listed
config has a completed flow: check the stage logs and exit-code files. The
exact source, dataset, defines, and top are recorded in the config's
`list-file.txt`, `list-define.txt`, `rtl-top-file.txt`, and `top-module.txt`.
Some preserved configs intentionally reference RTL under `../archive/`; their
results remain reproducible but are not necessarily results for a current
root-level RTL candidate.

Each config keeps its own flow scripts and evidence:

```text
<configuration>/
|-- list-file.txt
|-- list-define.txt
|-- rtl-top-file.txt
|-- top-module.txt
|-- testbench-file.txt
|-- logical/
|-- sim/
|-- power/
`-- scripts/
```

Run stages in order (`logical/run.sh`, `sim/run.sh`, then `power/run.sh`) or
select the exact config with the repository-level Makefile. The reports under
`rtl/conv4x4/report/` are summaries generated from executed configs; raw logs,
netlists, and power files stay with their producing config.

Historical and retired runs are under `../archive/synthesis/`. They are not
included in default reports. Avoid moving a source or dataset independently
of the config that records it; run `make audit-layout` after organization
changes to verify all manifest references.
