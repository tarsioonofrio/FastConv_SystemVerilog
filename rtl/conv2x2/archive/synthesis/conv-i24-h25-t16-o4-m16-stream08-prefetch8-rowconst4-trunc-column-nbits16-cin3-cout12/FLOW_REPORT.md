# Complete ASIC flow — m16 prefetch8 column, NBITS=16, Cin=3/Cout=12

## Configuration and provenance

- RTL: `rtl/conv2x2/conv-i24-h25-t16-o4-m16-stream08-prefetch8-rowconst4-trunc-column.sv`
- Parameters: `NUM_MULT=16`, `NBITS=16`, `N_CHANNEL_IN=3`, `N_CHANNEL_OUT=12`
- Dataset: `rtl/conv2x2/data/tcn4/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv`
- Target: ASIC TSMC28 standard-cell flow; this is not an FPGA result.
- Host: Paxos (`paxos.inf.pucrs.br`)
- Tools: Genus 21.12-s068_1; Xcelium 23.03-s003; Joules through Genus.
- Clock constraint: 2.000 ns.
- Source RTL SHA-256: `c40d543bc277c9718bd543a65a457c21b456c20ffc373aa4c30d143176cf3062`
- Testbench SHA-256: `48c79650528a9edee61fe626e34a6967774174d6ef3b627e85d6e1cd9befedef`
- RTL commit: `2db3ae93361642d75ecff664eee62885cce7e4d5`
- Flow configuration completion: `e9bdc918635c4a8b5ba10d095b8e1f6ae8a8ec0f`
- Final gate-level testbench fixes were present through commit `50fc8aecd7d51a7957233cb4d51aac71d75961fc`.

## Logical synthesis and timing

Genus completed and exported the mapped netlist, three corner SDFs, area/gate/clock-gating reports, and timing reports.

| Metric | Result |
| --- | ---: |
| Cell count | 12,653 |
| Cell area | 15,362.550 um² |
| Net area | 6,146.594 um² |
| Reported total area | 21,509.144 um² |
| Setup slack, slow corner (0.81 V, 125 °C) | +45 ps |
| Setup slack, nominal (0.90 V, 25 °C) | +256 ps |
| Setup slack, fast corner (0.99 V, -40 °C) | +419 ps |

The worst reported path is a constrained output-boundary path from `r_output_write_count_reg[0]/CP` to `p_output_data_write[31]`. At the slow corner it has 955 ps data-path delay against a 1 ns output-delay budget, leaving +45 ps slack. This is positive but has limited margin.

## Gate-level simulation with nominal SDF

The final Xcelium attempt completed successfully with nominal SDF annotation:

- Job latency from accepted `p_start` to `p_end`: 49,898 cycles × 2 ns = 99.796388 µs (reported by Xcelium).
- Final testbench drain: 49,940 cycles.
- Valid output writes: 32,400; output out-of-range accesses: 0.
- Golden comparison: passed.
- SDF annotation: 0 errors, 1,809 warnings. The warnings are principally SDF `RECREM` checks not present in the cell models; the simulation log also reports glitch-suppression notices.
- The gate-level memory model encountered one terminal input read beyond the package and explicitly returned zero for it. No output read/write was out of range. This behavior is reported rather than hidden.

Because the gate-level mapped netlist does not preserve internal RTL counters, its printed `inverse_tiles` and `terminal_inverse_events` fields are not valid acceptance counters; the testbench's external output/golden checks are the acceptance evidence.

## Joules power, nominal corner

| Category | Leakage (mW) | Internal (mW) | Switching (mW) | Total (mW) |
| --- | ---: | ---: | ---: | ---: |
| Register | 0.0191965 | 0.998624 | 0.156967 | 1.17479 |
| Logic | 0.0518370 | 0.652733 | 0.736905 | 1.44147 |
| Clock | 0.0003291 | 0.0625854 | 0.0609789 | 0.123893 |
| **Total** | **0.0713626** | **1.71394** | **0.954851** | **2.74016** |

Dynamic power (internal + switching) is **2.66879 mW**. Memory, latch, and pad categories are zero in this standard-cell report. These are ASIC tool estimates from the final annotated gate-level activity, not physical measurements.

## Artifacts

- `logical/genus.log` and `logical/results/`: mapped netlist, DB, three SDFs, reports, and physical-synthesis export.
- `sim/xrun.log`, `sim/sdf_log.log`, `sim/dut.shm/`, `sim/execution_time.txt`: final annotated simulation evidence.
- `power/genus.log` and `power/power_evaluation.txt`: Joules run and power breakdown.
- Earlier failed/diagnostic attempts are intentionally not represented as the final run; their stale generic exit markers were excluded.
