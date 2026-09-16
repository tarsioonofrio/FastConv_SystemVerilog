# P0/P1/P2 post-route power campaign

## Execution identity

- Host: `paxos.inf.pucrs.br`
- Vivado: `2023.2`
- Published commit: `35e0d2c73ced3521ee9f488e373b11413290cdfa`
- Remote worktree: `/tmp/fastconv-power-35e0d2c7`
- Checkpoint: `reports/317mhz/design_routed.dcp`
- Target clock: `317 MHz` (`23648 / 317e6 = 74.599369 us/job`)
- SAIF: `reports/rtl_saif/activity_rtl.saif`
- SAIF duration: `74587369 ps` (`23648.5` cycles)
- SAIF clock transitions: `47297`
- Refined post-route timing boundary: highest tested PASS `346.8966 MHz`
  (WNS `+0.002 ns`); lowest tested FAIL `347.1764 MHz` (WNS `-0.013 ns`).
  The PASS/FAIL bracket width is `0.2799 MHz`, below the `0.5 MHz` search
  tolerance. This is reported as a verified lower bound, not an exact Fmax.

The persistent remote checkout was not modified. The campaign ran in the
temporary worktree above, whose `HEAD` was verified to be the published commit
and whose status was clean before execution.

## Power results

| Method | Corner | Dynamic W | Static W | Total W | Direct activity |
| --- | --- | ---: | ---: | ---: | --- |
| P0 vectorless | typical | 0.251 | 0.593 | 0.844 | N/A |
| P1 RTL-SAIF/vectorless | typical | 0.210 | 0.593 | 0.803 | 104/5442 nets (1.91%) |
| P2 input/control/vectorless | typical | 0.211 | 0.593 | 0.804 | 40 input/control signals |
| P0 vectorless | maximum | 0.251 | 0.814 | 1.065 | N/A |
| P1 RTL-SAIF/vectorless | maximum | 0.210 | 0.813 | 1.023 | 104/5442 nets (1.91%) |
| P2 input/control/vectorless | maximum | 0.211 | 0.813 | 1.024 | 40 input/control signals |

For the principal P1 typical result, the total-power efficiency is
`2.4339 GOPS/W` and `410.9 pJ/equivalent-op`. Since the routed FPGA static
power is `0.593 W` (`73.8%` of the `0.803 W` total), the corresponding dynamic
figures are also reported: `9.3069 GOPS/W_dynamic` and `107.4
pJ/equivalent-op_dynamic`. P2 is a cross-check, not a second principal result;
its total power differs from P1 by only `1 mW`.

P1 imported the complete directed RTL SAIF. Vivado reported the clock-net
annotation warning and ignored the SAIF clock activity, as intended; the clock
frequency remains defined by the routed design constraints. Unmatched nets use
Vivado vectorless propagation.

P2 used `scripts/primary_input_activity.tcl`. The Tcl was checked to contain
exactly 40 `set_switching_activity` commands for reset, start, and input ports;
clock and output ports were not injected.

## Energy at the 317 MHz implementation point

The following values use the architectural job time at exactly 317 MHz, not
the slightly faster 317.058 MHz SAIF simulation clock.

| Method | Corner | Dynamic uJ/job | Total uJ/job | GOPS/W | pJ/equivalent-op |
| --- | --- | ---: | ---: | ---: | ---: |
| P0 vectorless | typical | 18.7244 | 62.9619 | 2.3157 | 431.84 |
| P1 RTL-SAIF/vectorless | typical | 15.6659 | 59.9033 | 2.4339 | 410.86 |
| P2 input/control/vectorless | typical | 15.7405 | 59.9779 | 2.4309 | 411.37 |
| P0 vectorless | maximum | 18.7244 | 79.4483 | 1.8352 | 544.91 |
| P1 RTL-SAIF/vectorless | maximum | 15.6659 | 76.3152 | 1.9105 | 523.42 |
| P2 input/control/vectorless | maximum | 15.7405 | 76.3898 | 1.9086 | 523.94 |

The active-job throughput is `1.954440 GOPS` from `145800` equivalent
operations and `23648` cycles. Inter-job II remains `N/A`; the core requires
reset/rearm between complete jobs.

## Refined Fmax search

The post-route search verified timing closure at `346.8966 MHz` and failure at
`347.1764 MHz`, giving the bounded result
`346.8966 MHz <= Fmax < 347.1764 MHz`. The implementation point used for the
power campaign remains exactly `317 MHz`; the refined Fmax search is an
independent timing characterization.
