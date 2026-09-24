# P3F — post-implementation functional-SAIF power

This is a pilot-method experiment on the frozen single-core design, not the
definition of a thesis architecture or a replacement for the P0/P1/P2 results.
P3T (post-route timing simulation with SDF) remains diagnostic-only because its
golden comparison failed. P0/P1/P2 reports were not overwritten.

## Result

P3F succeeded using the post-route functional netlist, Xcelium, UNISIM models,
and no SDF. The functional golden check passed in both captures: 8,100 output
writes, 2,025 tiles, and zero golden mismatches. Both simulations completed at
cycle 23,658 from reset release; the SAIF window itself contains 23,648 clock
cycles between `p_start` and `p_end`.

For the 317 MHz operating point, the P3F estimate is:

| Corner | Dynamic | Device static | Total | Vivado confidence | Direct SAIF matches |
| ------ | ------: | ------------: | ----: | ----------------- | ------------------: |
| Typical | 0.281 W | 0.593 W | 0.874 W | High | 5,442/5,442 (100%) |
| Maximum | 0.281 W | 0.814 W | 1.095 W | High | 5,442/5,442 (100%) |

The clock is governed by the DCP/XDC constraint; Vivado explicitly warned that
clock activity imported from SAIF is ignored. No glitches are represented
because the simulation is functional rather than SDF-timed. This is a power
estimate, not a board measurement.

## Comparison with the existing methods

| Method | Corner | Dynamic | Static | Total | Activity source / annotation |
| ------ | ------ | ------: | -----: | ----: | ---------------------------- |
| P0 | Typical | 0.251 W | 0.593 W | 0.844 W | Vectorless |
| P1 | Typical | 0.210 W | 0.593 W | 0.803 W | RTL-SAIF + vectorless, 104/5,442 direct matches |
| P2 | Typical | 0.211 W | 0.593 W | 0.804 W | Workload-derived primary input/control activity |
| P3F | Typical | 0.281 W | 0.593 W | 0.874 W | Functional post-route SAIF, internal + port scopes, 5,442/5,442 |
| P0 | Maximum | 0.251 W | 0.814 W | 1.065 W | Vectorless |
| P1 | Maximum | 0.210 W | 0.813 W | 1.023 W | RTL-SAIF + vectorless, 104/5,442 direct matches |
| P2 | Maximum | 0.211 W | 0.813 W | 1.024 W | Workload-derived primary input/control activity |
| P3F | Maximum | 0.281 W | 0.814 W | 1.095 W | Functional post-route SAIF, internal + port scopes, 5,442/5,442 |

P3F dynamic power is 33.8% above P1 and 33.2% above P2, while total typical
power is 8.8% and 8.7% higher, respectively. The difference is almost entirely
in the modeled I/O component: P3F reports 0.182 W I/O dynamic power, versus
0.111 W for P1 and 0.137 W for P2. The internal non-I/O categories are close to
P1. P3F captures DUT output-port transitions as well as workload inputs, while
P2 intentionally injects activity only on selected primary inputs/controls.
This explains the difference in the reports; it does not turn any estimate into
a physical measurement.

## Procedure and activity-window audit

1. Opened the same routed checkpoint used by P0/P1/P2 and exported
   `design_routed_funcsim.v` with Vivado `write_verilog -mode funcsim`.
2. Used `compile_simlib` for the Zynq UltraScale+ Verilog UNISIM simulation
   libraries with Xcelium. Vivado's functional-netlist conversion reports 53
   transformed instances (8 DSP48E2s and 45 IBUFs); no RTL synthesis or
   implementation was rerun. `compile_simlib` returned zero errors and three
   library warnings (one for SECUREIP, two for UNISIM); the Xcelium design
   compile/elaboration logs report zero errors and zero warnings.
3. Ran Xcelium 23.03-s003 against the canonical `pack_data.sv`, `pack_param.sv`,
   `rtl/mem/mem.sv`, the functional netlist, `glbl.v`, and the existing
   `tb_power_timing_safe.sv`. The testbench waited 70 falling edges before
   releasing reset, so the first launch followed the FPGA global startup reset.
   `P3_TRACE_COMB_MEMORY` restores the validated zero-delay behavioral memory
   boundary for this functional test; no C2Q delays or SDF were used.
4. Captured activity only after `p_start` and stopped at `p_end`. The timeout
   was a guard, not the capture endpoint. Two deterministic, golden-identical
   Xcelium runs were used because SAIF port activity and internal activity need
   different hierarchy stripping for Vivado to match them without warnings:
   `tb_power/dut` for internal nets, then `tb_power` for top-level ports. Both
   captures have the same 74,584,315,000 fs duration and cover the same workload.
5. Imported the internal SAIF and port-scope SAIF into the same routed DCP,
   without resetting switching activity between reads. The final report has
   5,442/5,442 design nets matched and High confidence for I/O, internal nodes,
   clocks, and device models.

SAIF audit values from the DUT-scope capture:

```text
SAIF time scale             1 fs
SAIF duration               74,584,315,000 fs = 74.584315 us
clock transitions           47,296 = 23,648 cycles
effective capture frequency ~317.064 MHz
reset during capture        inactive (TC=0, TX=0)
p_start                     observed (TC=2)
p_end                       observed (TC=1)
p_input_en                  active (TC=4,052)
p_input_data[0]             active (TC=15,206)
p_output_wr                 active (TC=4,049)
p_output_data_write[0]      active (TC=4,990)
```

The 3.154574 ns clock-period parameter is quantized by the 1 ps testbench
resolution. The measured SAIF window is therefore reported as approximately
317.064 MHz; the power/performance operating point remains the constrained
317 MHz point.

The whole-testbench SAIF initially captured with memories was 298 MB and was
used only to diagnose scope mapping. The retained top-scope capture omits memory
arrays and is about 17 MB. No `.vcd` or `.fst` was generated. SHM files were
generated and retained for optional inspection, but they were not visually
opened in SimVision during this run.

## Derived pilot metrics at 317 MHz

Using the frozen pilot definitions (`145,800` equivalent operations/job,
`23,648` active-job cycles, and `MAC = 2` equivalent operations):

| P3F typical metric | Value |
| ------------------ | ----: |
| Active-job throughput | 1.9544 GOPS |
| Dynamic energy/job | 20.96 µJ |
| Total energy/job | 65.20 µJ |
| Dynamic-power-normalized efficiency | 6.96 GOPS/W |
| Total efficiency | 2.236 GOPS/W |
| Dynamic energy/op | 143.8 pJ/op |
| Total energy/op | 447.2 pJ/op |

These derived values are still tool-estimated and remain specific to this pilot
and its current behavioral-memory boundary.

## Provenance

```text
local/published source commit  d0282f555d9387a0b75d7c4b0113627c614a4ac0
isolated Paxos checkout        /tmp/fastconv-p3f-d0282f55
host                           paxos.inf.pucrs.br
Vivado                         2023.2
Xcelium                        23.03-s003
device                         xczu7ev-ffvc1156-2-e
DCP SHA-256                    688d9abd0eeb27f7bd8a8b0d51e572d1977c69769443fc1cca2e0b1388c96f6e
functional netlist SHA-256      efad8d86b64156e0bae559b43130982e1b4f86133cd5cbee1ac513e7998079be
pack_data.sv SHA-256            3ced5c4527374898e1f8d65c275403e1366e2bb09f466542915656b263356da0
pack_param.sv SHA-256           32cc3b114c3e7f3108acabdb0bbc6e3bb8457a1da7cf791c4b365bb7e15b7477
testbench SHA-256               3c82af0c0325d880a3da07df15bbe1acb63bb3718ffcb557e4edbdd0c6ba0156
DUT-scope SAIF SHA-256          483964c90d381d60930c2f13609646c7f84dc494e6c999c070adf090bc3f45f5
top-scope SAIF SHA-256          5359314d70b11c3cf7e53120a76198c9dcdd5caf69d004b67950d5df950abbd5
```

The top-scope and DUT-scope SAIF files were generated by separate deterministic
simulator invocations, not simultaneous dumps from one process. Both Xcelium
logs independently show the same golden result and active window. Keep that
two-capture detail explicit when reusing this method for the target architectures.

AMD documents `funcsim` as a functional simulation netlist mode and distinguishes
functional activity from timing-glitch activity. Functional post-implementation
SAIF is therefore supported, but it is not equivalent to SDF timing SAIF:
[UG835 `write_verilog` 2023.2](https://docs.amd.com/r/2023.2-English/ug835-vivado-tcl-commands/write_verilog?contentId=L4Hk4bWP_Y7NVacYBjEDbA),
[UG900 simulation libraries 2023.2](https://docs.amd.com/r/2023.2-English/ug900-vivado-logic-simulation/Compiling-Simulation-Libraries),
[UG900 supported simulators 2023.2](https://docs.amd.com/r/2023.2-English/ug900-vivado-logic-simulation/Supported-Simulators),
[UG907 switching activity 2023.2](https://docs.amd.com/r/2023.2-English/ug907-vivado-power-analysis-optimization/Specifying-Switching-Activity-for-Power-Analysis).
