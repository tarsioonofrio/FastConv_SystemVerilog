# TCN9 m5: final SDF simulation and power run

- Host/toolchain: Paxos; Xcelium 23.03-s003; Genus/Joules 21.12-s068_1.
- Input: mapped netlist plus nominal SDF; canonical TCN9 workload; 2 ns clock.
- Functional result: PASS, 8,100 writes, zero golden mismatches; Xcelium exit 0.
- Active job interval reported by the testbench: 20,276 ns / 10,138 cycles.
- Path-delay annotation: 250,939 / 250,939 (100%).
- Timing-check annotation: 4,226 / 25,254 (16.73%); SDFNET warnings reached the warning cap.
- Power corner: `tt0p9v25c`, 0.90 V, 25 C, interconnect mode `ple`.
- Power: leakage 0.170676 mW; internal 3.30725 mW; switching 2.21730 mW;
  dynamic 5.52455 mW; total 5.69523 mW.
- The power flow imports the full SHM from 0 ns, including reset/startup; it is
  not an active-job-only power window.

Run hashes and raw logs are in this directory. The canonical copies are in
`../../` (`xrun.log`, `sdf_log.log`, `execution_time.txt`) and
`../../../power/` (`genus.log`, `power_evaluation.txt`). The prior failed run
is preserved as `pre_power_fix_*`; its power report is kept separately as
`power_evaluation.invalid_before_p_end_fix.txt`.
