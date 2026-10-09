# Campaign provenance

- Campaign source commit on Paxos: `ced7840ba8faf8353ed1675742294411ebd3dc44`
- Host: `paxos.inf.pucrs.br`
- FPGA part: `xczu7ev-ffvc1156-2-e` (ZCU104 / XCZU7EV)
- Vivado: `2023.2`, build `4029153`
- Xcelium: `23.03-s003`
- Simulation mode: post-route functional netlist, no SDF; SAIF collected over the active `p_start` to `p_end` window
- Clock constraint and simulation clock: 317 MHz target, period 3.154574 ns
- Workload: canonical `32x32`, Cin=3, Cout=3, 3x3 package at `rtl/conv2x2/data/archive/tcn4/sim/sim-032-3-3-normal/pack_data.sv`
- Equivalent operations: 145,800/job using MAC=2; active-job throughput excludes inter-job reset/rearm
- Long implementation/simulation campaign: tmux session `fc-col-pwr-ced7840b`, exit code 0
- Simulation evidence: both DUT-SAIF and top-SAIF Xcelium runs passed for all four variants; each reports 8,100 writes, 2,700 final words, zero mismatches
- Waveform policy: no VCD/FST generated
- Power corners: typical and maximum process, 25 C; P0 vectorless and P3F functional-SAIF

## SHA-256 inputs

| Artifact | SHA-256 |
|---|---|
| Canonical workload `pack_data.sv` | `3ced5c4527374898e1f8d65c275403e1366e2bb09f466542915656b263356da0` |
| `conv-i16-h16-t16-o4-m08-std.sv` | `94939147b92d1ac5313c46825d0c14da9ac67c7e2180288c05e02806cd93bde0` |
| `conv-i16-h16-t16-o4-m08-std-column.sv` | `c625ac1ee17da13a18a588c27eea875c3ae7070abc0b11c24450a652ef286115` |
| `conv-i24-h13-t08-o4-m08-stream08-prefetch8-rowconst4.sv` | `46be568b9d461adcb2901badd18e529a07e10ff99faf51a2f7cc9042c2a008d4` |
| `conv-i24-h13-t08-o4-m08-stream08-prefetch8-rowconst4-column.sv` | `650a7a9604dce065d5eef048c23b60adf808af734077ca4ed33f498666a6dbc7` |

## Per-run implementation artifacts

| Run | Routed DCP SHA-256 | Functional netlist SHA-256 | DUT SAIF SHA-256 |
|---|---|---|---|
| `std_scalar` | `a95617be5cb7935ed7c8f71001f3d9b19bce636e65c0de2455be76be31f00614` | `d8ddcab7559183512b863ed59bab821e0999983625f676956b4a80d6f7dda114` | `c461d80609b5ff8235b19cfb97832ef7c5b465a107c9084290ec349d1fbd14e4` |
| `std_column` | `61c57bd5b296d86d96b0f85e49f0ded6ede9909a1cf0ce8dda040539cceb94d0` | `38d8cd0e900a228b5c204e86d68eaaa8dd898c9ec81a031dac16fa23db23996c` | `bbf7774d42b1ba8d916011d20c1204ce5cf071986312811ecd8d9928ae5d120f` |
| `prefetch8_scalar` | `8faf5bdb8cd467e8ef2e09870416b5645341cf876444ec7c37ac38d0787dec50` | `c4f2ce6e8c73de21e8b02bae6faddb720d2826483f3e10f83467eb02be597933` | `9884711d51f31e40327e6e81b7bd400e3cd14fc34edee80af114bc60cfdd8504` |
| `prefetch8_column` | `6741fd714c148abde3a25f85d886b553b9f0a0ffff40a4abece6080d71fbde54` | `2bdc88d8df3dd86c249874b78cde7854cdeee0def3406cff7d4d58cf82eb29b6` | `c93f7afb0cb2e6b84a396c44ad8b0a9eaba9ed2ef2b6c645d548de67605dfc59` |

The matching implementation commands, P0/P3F reports, SAIF files, Xcelium
logs and Vivado logs are preserved under `reports/<run>/`. Temporary compiled
UNISIM libraries and Xcelium databases were intentionally not copied back.
