# Operand-isolation power run

## Run provenance

- RTL: `rtl/conv2x2/archive/m08/conv-i20-h13-t08-o4-m08-stream08-prefetch4-rowconst4-operand-isolation.sv`
- Flow commit: `4f81eee4978daef0da278a6c43ae27580c1ed4fb`
- Target: ASIC TSMC28, Genus 21.12-s068_1 / Joules XL, Xcelium 23.03-s003
- Host: `paxos.inf.pucrs.br`; execution used tmux session `fc_oi_power_20261006`
- Workload: canonical `tcn4` 32x32, Cin=3, Cout=3; `NBITS=20`, `NADDR=16`, `LATENCY=1`, `QUANT=8`
- Clock period: 2.000 ns
- SDF corner: typical, 0.90 V / 25 C (`analysis_view_0p90v_25c_captyp_nominal`)

## Functional timing-simulation result

The testbench completed the accepted `p_start` to `p_end` interval in 43.730 us (21,865 cycles). It reported 0 golden mismatches, 2,025 inverse tiles, 8,100 valid writes, 0 clipped input samples, and 0 invalid output beats. Its full-run counter reported 21,907 cycles.

Xcelium loaded the SDF and exited successfully. The log reached its 1,000-warning cap for `SDFINF` (instances from the SDF not found in the elaborated hierarchy); this is an annotation limitation and is retained in `sim/xrun.log`, so the run should not be described as complete delay annotation.

## Joules result

Typical-corner `report_power` on the mapped database, using the `dut.shm` from this same simulation:

| Category | Leakage (mW) | Internal (mW) | Switching (mW) | Total (mW) |
| --- | ---: | ---: | ---: | ---: |
| Register | 0.0159966 | 0.857763 | 0.150425 | 1.02418 |
| Logic | 0.0468042 | 1.42225 | 1.44786 | 2.91692 |
| Clock | 0.000468892 | 0.0914491 | 0.0662708 | 0.158189 |
| Subtotal | 0.0632697 | 2.37147 | 1.66456 | 4.09930 |

For this report, internal plus switching is 4.03603 mW; leakage is 0.0632697 mW.

## Comparison with the non-isolated prefetch4 baseline

The baseline report is `../conv-i20-h13-t08-o4-m08-stream08-prefetch4-rowconst4/power/power_evaluation.txt`. Its paired run record also uses 2.000 ns and 21,865 job cycles.

| Metric | Baseline (mW) | Operand isolation (mW) | Change |
| --- | ---: | ---: | ---: |
| Internal + switching | 3.75883 | 4.03603 | +7.375% |
| Switching | 1.56290 | 1.66456 | +6.505% |
| Total | 3.82131 | 4.09930 | +7.275% |

This run did not demonstrate a power reduction from the operand-isolation change. Interpret the comparison with the SDF annotation warnings above in mind.
