# ASIC synthesis configurations

This tree is the canonical location for the 3x3 ASIC flow configurations.
Use `make list-configs ARCH=conv3x3` to enumerate them; directory names are
the experiment identifiers and may include workload/precision suffixes beyond
the RTL source basename.

The current tree contains six configurations: IFN9 at 6, 12, and 18 MACs
(including the m18 pretransformed candidate), and TCN9 at 5 MACs (rowconst
and pretransformed-frac6 candidates). Their exact source and dataset are the
paths in each configuration's `list-file.txt`, not an inference from the
directory name.

Each config owns its manifests, scripts, and stage evidence:

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

Run the stages in order (`logical/run.sh`, `sim/run.sh`, then `power/run.sh`)
from the config directory or use the repository-level Makefile. A directory
alone does not indicate completion; inspect `logical/exit-code.txt`,
`sim/exit-code.txt`, `power/exit-code.txt`, and the corresponding logs/results.

Archived configurations are stored under `../archive/synthesis/` and are
excluded from default report generation. The report collector reads the
executed configurations under this tree and records the source/workload
metadata from their manifests.
