# ASIC workload: Cin=3, Cout=12

Source configuration: `rtl/conv3x3/synthesis/conv-tcn9-i40-h14-t10-o9-m05-stream10-prefetch15-rowconst5-trunc-column-nbits16`.

Workload package: `rtl/conv3x3/data/tcn9/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv`.

Top overrides: `NBITS=16`, `N_CHANNEL_IN=3`, `N_CHANNEL_OUT=12`.

This is a separate configuration so the original Cin=3, Cout=3 netlist, simulation, and power evidence remain unchanged.

## Reproduced full flow

- Source commit: `d5350c4f2970d55fe2ad0d9ed10e1e124b654c71`.
- Host: Paxos, clean sparse checkout in `/tmp`, executed in `tmux`.
- Tools: Genus `21.12-s068_1`, Xcelium `23.03-s003`, TSMC 28 nm libraries.
- Clock constraint: 2.000 ns (500 MHz).
- Command: `make flow ARCH=conv3x3 CONFIG=conv-tcn9-i40-h14-t10-o9-m05-stream10-prefetch15-rowconst5-trunc-column-nbits16-cin3-cout12`.

| Measurement | Result |
| --- | ---: |
| Mapped cells | 24,890 |
| Cell area | 26,980.884 um^2 |
| Net area | 11,473.639 um^2 |
| Total area | 38,454.523 um^2 |
| Typical dynamic power | 4.30667 mW |
| Typical leakage | 0.130044 mW |
| Typical total power | 4.43671 mW |
| Gate-level job duration | 81.080 us |
| Gate-level job cycles | 40,540 |
| Valid output words | 32,400 |
| Golden mismatches | 0 (testbench PASS) |

Setup slack is 0 ps slow, +214 ps nominal, and +388 ps fast. Nominal SDF
annotation completed with 0 errors and 1,679 warnings; see `sim/xrun.log` and
`sim/sdf_log.log` for the warning details. The Joules run completed normally.
SHM, SDF, and mapped database are generated artifacts and are not tracked by
Git.
