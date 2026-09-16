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
power were executed in the isolated snapshot. The sweep found a valid boundary
at 317.000013 MHz / 3.154574 ns (WNS +0.086 ns); 349.999983 MHz / 2.857143 ns
failed (WNS -0.023 ns). The gate-level XSim attempt reached SDF annotation but
Vivado's xelab aborted in LLVM `DAGTypeLegalizer::run`; SAIF is therefore kept
pending rather than presented as a timing-power result. The dirty `remote`
checkout itself was not reset or overwritten; the Cadence flow remains a
separate ASIC/standard-cell flow.

## Current direct-snapshot campaign

After the FPGA benchmark was moved under the variant-specific directory, commit
`5e0146f4` was synchronized directly to
`/tmp/fastconv-fpa-5e0146f4`. The persistent checkout at
`/sim/tarsio/FastConv_SystemVerilog` remained on its pre-existing dirty commit
`d719dfc852dfb783c6d330104c6e8980f48ec662` and was not modified.

Vivado 2023.2 regenerated the 317 MHz implementation artifacts and the full
post-route Fmax sweep. The local copy now includes the synthesis/routed DCPs,
timing netlists, SDFs, implementation logs, and reports for the sweep points.
The final Fmax JSON reports 317.000013 MHz at 3.154574 ns with WNS +0.086 ns;
349.999983 MHz fails with WNS -0.023 ns.

The official SAIF runner using `unisims_ver` compiled successfully but failed at
SDF annotation with `XSIM 43-3462`. A second elaboration using `simprims_ver`
accepted the timing primitives but aborted in Vivado 2023.2's LLVM
`DAGTypeLegalizer::run` assertion. No `activity.saif` was produced, and no
SAIF-based power value is included in the consolidated results. No VCD was
generated.
