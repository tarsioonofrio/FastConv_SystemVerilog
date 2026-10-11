# ASIC workload: Cin=3, Cout=12

Source configuration: `rtl/conv2x2/synthesis/conv-i24-h13-t08-o4-m08-stream08-prefetch8-rowconst4-trunc-column-nbits16`.

Workload package: `rtl/conv2x2/data/tcn4/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv`.

Top overrides: `NBITS=16`, `N_CHANNEL_IN=3`, `N_CHANNEL_OUT=12`.

This is a separate configuration so the original Cin=3, Cout=3 netlist, simulation, and power evidence remain unchanged.

## Reproduced full flow

- Source commit: `d5350c4f2970d55fe2ad0d9ed10e1e124b654c71`.
- Host: Paxos, clean sparse checkout in `/tmp`, executed in `tmux`.
- Tools: Genus `21.12-s068_1`, Xcelium `23.03-s003`, TSMC 28 nm libraries.
- Clock constraint: 2.000 ns (500 MHz).
- Command: `make flow ARCH=conv2x2 CONFIG=conv-i24-h13-t08-o4-m08-stream08-prefetch8-rowconst4-trunc-column-nbits16-cin3-cout12`.

| Measurement | Result |
| --- | ---: |
| Mapped cells | 8,909 |
| Cell area | 10,840.536 um^2 |
| Net area | 4,283.865 um^2 |
| Total area | 15,124.401 um^2 |
| Typical dynamic power | 3.26853 mW |
| Typical leakage | 0.0492665 mW |
| Typical total power | 3.31780 mW |
| Gate-level job duration | 115.996388 us |
| Gate-level job cycles | 57,998 |
| Valid output words | 32,400 |
| Golden mismatches | 0 (testbench PASS) |

Setup slack is +45 ps slow, +256 ps nominal, and +419 ps fast. Nominal SDF
annotation completed with 0 errors and 1,428 warnings; see `sim/xrun.log` and
`sim/sdf_log.log` for the warning details. The Joules run completed normally.
SHM, SDF, and mapped database are generated artifacts and are not tracked by
Git.
