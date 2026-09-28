# Scalar versus column-I/O FPGA power campaign

This isolated experiment measures two matched scalar/column pairs on the
ZCU104 (`xczu7ev-ffvc1156-2-e`) at the common 317 MHz operating point:

| Pair | Scalar RTL | Column RTL |
| --- | --- | --- |
| Standard | `conv-i16-h16-t16-o4-m08-std.sv` | `conv-i16-h16-t16-o4-m08-std-column.sv` |
| Prefetch-8 / rowconst4 | `conv-i24-h13-t08-o4-m08-stream08-prefetch8-rowconst4.sv` | `conv-i24-h13-t08-o4-m08-stream08-prefetch8-rowconst4-column.sv` |

The workload is the existing canonical `sim-032-3-3-normal` package. The
experiment does not modify the accelerator RTL. Each design is synthesized,
placed, routed, functionally simulated from its post-route netlist in Xcelium,
and analyzed with Vivado `report_power`. The functional SAIF method is P3F;
no SDF is used, so timing-glitch activity is not modeled. A vectorless report
is also generated from the same routed checkpoint as a baseline.

The testbench has a scalar and a `COLUMN_IO` interface mode. It waits through
the FPGA startup GSR interval, runs one job at the 317 MHz simulation clock,
checks all final output words against `const_feat_out`, and emits no VCD/FST.
The SAIF capture window is delimited by `p_start` and `p_end`; the final golden
check runs immediately after that window.

## Runs

On Paxos, load the documented Vivado 2023.2 and Xcelium 23.03 modules, verify
the exact checkout commit, then run the long campaign inside `tmux`:

```bash
cd rtl/conv2x2/fpga_zcu104/column_power_comparison
bash scripts/run_all.sh
```

`run_all.sh` performs, for each of the four designs:

1. Synthesis, placement, physical optimization and routing at 317 MHz.
2. Post-route vectorless power at typical and maximum process corners.
3. Xcelium functional simulation of the post-route netlist (no SDF), twice:
   once for internal SAIF and once for top-level port SAIF.
4. Golden output checking and SAIF-driven Vivado power at both corners.

Logs, checkpoints, netlists, SAIF captures and reports are written under
`reports/<run>/`. Generated Xcelium simulator libraries are shared under
`reports/simlibs_unisim/` and are not source artifacts.

The comparison table must report each scalar/column pair side-by-side, with
LUT, FF, DSP, BRAM, WNS, dynamic/static/total power for both P0 vectorless and
P3F functional-SAIF, plus SAIF mapping coverage and active-job cycles. Keep
the distinction between estimated power and physical board measurement.
