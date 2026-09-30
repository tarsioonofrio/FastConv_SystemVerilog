# FPGA flow for streaming-column cores

This directory defines the common ZCU104/XCZU7EV implementation and power
flow for the four generated `trunc-column` cores: `tcn9`, `ifn9`, `tcn16`, and
`wpn16`. The RTL sources remain in `rtl/conv3x3/` and `rtl/conv4x4/`; manifests
select one design and its transform/multiply modules.

All variants use the same workload packages (`sim-032-3-3-normal-trunc`),
Vivado 2023.2 flow, 317 MHz clock, XCZU7EV part, `NADDR=12`, and output checker.
`NADDR=12` is the minimum width that covers each input/output memory and matches
the official streaming-column regression. Do not silently use the RTL default
of 16 bits in the FPGA comparison.

## Validation already performed locally

The port-level checker `tb/tb_power_stream_column.sv` was run in Verilator at
the 317 MHz clock period against each matching RTL, parameter package, matrix,
and truncated canonical workload. Each result had zero final-output mismatches:

| Algorithm | Input/output tile | MACs | Active cycles | Write beats | Physical words |
| --- | ---: | ---: | ---: | ---: | ---: |
| `tcn9` | 5x5 -> 3x3 | 5 | 10,138 | 2,700 | 8,100 |
| `ifn9` | 5x5 -> 3x3 | 6 | 11,038 | 2,700 | 8,100 |
| `tcn16` | 6x6 -> 4x4 | 6 | 7,691 | 2,304 | 9,216 |
| `wpn16` | 6x6 -> 4x4 | 8 | 8,843 | 2,304 | 9,216 |

These are RTL functional checks only, not FPGA implementation or power results.

## Paxos execution

First publish the exact source commit and verify it on the Paxos. Then load
Vivado 2023.2 and Xcelium 23.03 and run the campaign in a persistent tmux
session, directing artifacts outside Git:

```bash
source /usr/share/Modules/init/bash
module purge
module use /soft64/modulefiles
module load xilinx/vivado/2023.2 cadence/xcelium/2303
tmux new -s stream-column-fpga
# Inside tmux:
rtl/stream-column/fpga_zcu104/scripts/run_all.sh /tmp/stream-column-fpga-<commit>
```

Per algorithm, the script runs post-route implementation and reports, P0
vectorless power, post-implementation functional netlist simulation under
Xcelium, DUT and top-level SAIF captures between `p_start` and `p_end`, then
P3F power at typical and maximum operating corners. The P3F estimate is based
on functional activity and does not include SDF glitch activity. Xcelium must
report `STREAM_COLUMN_POWER_PASS` in both captures before Vivado imports SAIF.

All DCPs, netlists, SAIF files, simulator libraries and reports are placed in
the supplied output directory; they are not source artifacts and should not
be committed. Preserve the text logs, utilization/timing reports, power reports,
SAIF mapping reports and checksums as campaign evidence.
