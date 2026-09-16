# Paxos probe for the ZCU104 benchmark

Probe performed over the configured SSH endpoint `paxos.inf.pucrs.br:8888`.
The command was read-only and returned:

```text
hostname: paxos.inf.pucrs.br
checkout: /sim/tarsio/FastConv_SystemVerilog
HEAD: d719dfc852dfb783c6d330104c6e8980f48ec662
```

The remote checkout is on branch `remote`, differs from the local active
documentation commit `d29b50d1`, and has pre-existing modified and untracked
files. It was not reset, cleaned, copied over, or used for a write campaign.

Available remote EDA modules were confirmed with `module avail` as including:

```text
cadence/genus/211  -> Genus 21.12-s068_1
cadence/xcelium/2303 -> Xcelium 23.03-s003
xilinx/vivado/2023.2
xilinx/vivado/2024.2
xilinx/vivado/2025.2
xilinx/vitis/2024.2
```

After `module load xilinx/vivado/2023.2`, the remote tool paths were verified:

```text
vivado v2023.2 (64-bit), SW Build 4029153
xvlog, xelab, xsim -> same Vivado 2023.2 bin directory
```

Therefore the Paxos has the required FPGA tools. The ZCU104 implementation,
317 MHz post-route timing, FPGA resource extraction, and vectorless Vivado
power were executed in the isolated snapshot. The initial coarse sweep found
a valid point at 317.000013 MHz / 3.154574 ns (WNS +0.086 ns) and a failure at
349.999983 MHz / 2.857143 ns (WNS -0.023 ns). The refined boundary is recorded
in the current direct-snapshot campaign below; 317 MHz is not an exact Fmax.
The gate-level XSim attempt reached
SDF annotation but Vivado's xelab aborted in LLVM
`DAGTypeLegalizer::run`; timing-SAIF is optional rather than the primary power
result. The dirty `remote`
checkout itself was not reset or overwritten; the Cadence flow remains a
separate ASIC/standard-cell flow.

## Current direct-snapshot campaign

After the FPGA benchmark was moved under the variant-specific directory, commit
`5e0146f4` was synchronized directly to
`/tmp/fastconv-fpa-5e0146f4`. The persistent checkout at
`/sim/tarsio/FastConv_SystemVerilog` remained on its pre-existing dirty commit
`d719dfc852dfb783c6d330104c6e8980f48ec662` and was not modified.

Vivado 2023.2 regenerated the 317 MHz implementation artifacts and the full
post-route Fmax sweep. The local copy includes the implementation logs and
timing reports for the sweep points. The refined campaign verified a highest
tested PASS of 346.896588 MHz at 2.882703476 ns (WNS +0.002 ns) and a lowest
tested FAIL of 347.176439 MHz at 2.880379796 ns (WNS -0.013 ns). Therefore the
reported boundary is the bounded interval
`346.896588 MHz <= Fmax < 347.176439 MHz`, with width 0.279851 MHz; no exact
Fmax beyond this tested bracket is claimed.

The timing-SAIF runner using `unisims_ver` compiled successfully but failed at
SDF annotation with `XSIM 43-3462`. A second elaboration using `simprims_ver`
accepted the timing primitives but aborted in Vivado 2023.2's LLVM
`DAGTypeLegalizer::run` assertion. This path is optional and is not a blocker;
no VCD was generated.

## Workload generated with `fast-conv`

The activity workload was regenerated in an isolated copy of the
`fast-convolution-rtl` configuration with the project virtual environment:

```text
/home/tarsio/gaph/fast-convolution-rtl/.venv/bin/fast-conv \
  --path <isolated-config-copy> sim normal \
  --image-side 32 --channel-in 3 --channel-out 3 --seed 1 \
  --name 032-3-3-normal --no-c
```

The resulting package is the canonical
`rtl/conv2x2/data/tcn4/sim/sim-032-3-3-normal/pack_data.sv`, with SHA-256
`3ced5c4527374898e1f8d65c275403e1366e2bb09f466542915656b263356da0`.
The metadata records the generator, configuration, dimensions, seed, and the
8-bit quantization used by `fast-conv sim normal`. Local RTL validation passed
with one complete job: 23,648 cycles latency and 11 cycles between tile-end
events. The core is not re-entrant without reset, so the workload deliberately
uses one job and reports inter-job II as N/A rather than reusing latency as a
pipeline interval.

## Direct Paxos SAIF attempts for the generated workload

The isolated snapshot `/tmp/fastconv-fpa-workload-8fdb9dc6.tar.gz` (SHA-256
`e2126b286f26e71be8b03af5b432fa6c7595d24ccb4a40a7f631591bb48621a6`) was
copied directly to Paxos; the persistent checkout was not changed. The
generated package compiled successfully together with the routed netlist and
the missing auxiliary RTL files.

The following attempts were recorded without VCD generation:

- Vivado 2023.2, 2024.2, and 2025.2 with `unisims_ver`: SDF backannotation
  failed with `XSIM 43-3462` (`Unable to annotate SDF delays in the design`).
- Vivado 2023.2 with `simprims_ver`: SDF annotation succeeded, but `xelab`
  aborted in LLVM `DAGTypeLegalizer::run()`.
- A functional netlist emitted from the routed DCP (`write_verilog -mode
  funcsim`) was generated, but its `xelab` elaboration remained at the module
  compilation stage for more than six minutes and produced no SAIF; that
  temporary process was stopped and its logs were preserved remotely.

The RTL/behavioral SAIF capture is generated without VCD. The first local
capture was accidentally limited to 245 ns by a time-unit mismatch in the
Verilator driver; it was then regenerated with a 249.995 us window. That
second capture contains the full 23,648-cycle job, including `p_end` and output
writes, but it used the old approximately 100 MHz RTL clock and is now treated
as superseded evidence rather than a 317 MHz power input. The earlier
0.689 W/0.908 W reports and 104/5442 mapping belong to the truncated capture
and were moved to `reports/stale_saif_245ns/`; neither set is a final hybrid
power result.

The current driver uses the 317 MHz nominal period (`3154.574 ps`) and starts
SAIF at `p_start` and stops when the testbench observes `p_end`, with a timeout
only as a safety guard. Its capture metadata must show approximately 23,648 active
cycles and approximately 74.6 us before the SAIF is imported into the routed
checkpoint with `TOP/tb_power`. The intended label is **post-route hybrid
SAIF/vectorless power**, with direct mapping and vectorless propagation
reported separately. The timing-SDF SAIF path remains optional because of the
XSim LLVM failure.
