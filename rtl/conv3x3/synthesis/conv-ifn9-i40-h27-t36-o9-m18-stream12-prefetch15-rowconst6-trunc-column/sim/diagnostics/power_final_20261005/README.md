# IFN9 m18: final SDF simulation and power run

- Host/toolchain: Paxos; Xcelium 23.03-s003; Genus/Joules 21.12-s068_1.
- Input: mapped netlist plus nominal SDF; canonical IFN9 workload; 2 ns clock.
- Functional result: PASS, 8,100 writes, zero golden mismatches; Xcelium exit 0.
- Active job interval reported by the testbench: 14,876 ns / 7,438 cycles.
- Path-delay annotation: 253,611 / 253,611 (100%).
- Timing-check annotation: 6,552 / 36,716 (17.85%); SDFNET warnings reached the warning cap.
- Power corner: `tt0p9v25c`, 0.90 V, 25 C, interconnect mode `ple`.
- Power: leakage 0.129178 mW; internal 5.27456 mW; switching 3.69429 mW;
  dynamic 8.96885 mW; total 9.09803 mW.
- The power flow imports the full SHM from 0 ns, including reset/startup; it is
  not an active-job-only power window.

Run hashes and raw logs are in this directory. The canonical copies are in
`../../` (`xrun.log`, `sdf_log.log`, `execution_time.txt`) and
`../../../power/` (`genus.log`, `power_evaluation.txt`). The prior failed run
is preserved as `pre_power_fix_*`; its power report is kept separately as
`power_evaluation.invalid_before_p_end_fix.txt`.
