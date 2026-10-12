# ASIC workload: Cin=3, Cout=12

RTL: `rtl/conv4x4/conv-wpn16-i60-h41-t64-o16-m32-stream16-prefetch24-pretransformed-column.sv`.

Workload package: `rtl/conv4x4/data/wpn16/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv`.

Top overrides: `NBITS=16`, `N_CHANNEL_IN=3`, `N_CHANNEL_OUT=12`.
The RTL caches the package's pretransformed integer 8x8 WPN16 weight tile;
the testbench define `WPN16_PRETRANSFORMED_WEIGHTS` selects that packed region
and checks the expected number of column beats.

This archived configuration has its own synthesis, gate-level simulation, and
power artifacts. It is retained for provenance and is not part of the active
`make flow` configuration set.

## Executed flow

- Source commit: `b6083b9f0a8ae2ac26a8c814aae0073da28af45a`.
- Host: Paxos, isolated clean clone under `/tmp` (the persistent checkout was
  dirty and at a different commit).
- Tools: Genus `21.12-s068_1`; Xcelium `23.03-s003`; TSMC 28 nm libraries.
- Clock constraint: 2.000 ns (500 MHz).
- Full command: `make flow ARCH=conv4x4 CONFIG=conv-wpn16-i60-h41-t64-o16-m32-stream16-prefetch24-pretransformed-column`.

| Measurement | Result |
| --- | ---: |
| Mapped cells | 28,610 |
| Cell area | 35,859.978 um^2 |
| Net area | 14,069.570 um^2 |
| Total area | 49,929.548 um^2 |
| Gate-level job duration | 43.642 us |
| Gate-level job cycles | 21,821 |
| Valid output words | 32,400 |
| Golden mismatches | 0 (testbench PASS) |
| Typical dynamic power (internal + switching) | 9.82347 mW |
| Typical leakage | 0.162620 mW |
| Typical total power | 9.98610 mW |

The reported setup slack is +10 ps in the slow corner, +226 ps nominal, and
+396 ps in the fast corner. The slow-corner critical path starts at
`r_output_write_count_reg[0]/CP` and ends at `p_output_data_write[63]`.

The nominal SDF annotation completed with 0 errors and 5,956 warnings. The
log includes unannotated `RECREM` timing checks (`SDFNET`) and runtime
`Glitch suppression` warnings; the gate-level golden test still completed
with no mismatches. Joules completed successfully with 0 warnings and 0
errors. Detailed reports and logs are stored in `logical/results/`, `sim/`,
and `power/`; SDF, mapped database, and SHM are generated artifacts and are
not tracked by Git.
