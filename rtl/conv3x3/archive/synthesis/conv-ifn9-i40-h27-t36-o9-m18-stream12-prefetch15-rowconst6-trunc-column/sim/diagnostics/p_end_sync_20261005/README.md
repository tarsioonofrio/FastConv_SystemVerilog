# IFN9 m18 SDF completion-check retest

- Host: Paxos; Xcelium 23.03-s003.
- Core and workload files matched the local checkout by SHA-256. Testbench SHA-256: `8ebd1a63dcf5231920e91c8ff007f3bdb2d652d92277edd0953c6e7af9be655b`.
- Post-route mapped netlist with nominal SDF; 2 ns clock.
- Result: golden PASS, 8,100 valid output writes, zero mismatches; measured job time 14,876 ns / 7,438 cycles.
- SDF path delays: 253,611/253,611 (100%). Timing checks: 6,552/36,716 (17.85%); unmatched timing-check warnings reached the Xcelium SDFNET warning cap.
- `xrun` returned status 1 even though simulation reached `$finish`, reported no simulation errors, and printed the PASS summary. Retain this process-status caveat.

The preceding trace isolated the original false failure: `p_end` pulsed high at 14,961,184 ps for 43 ps while the output FSM was in `READ_OUTPUT` (`state=4`) and `p_output_wr=0`. The old testbench woke on that edge and checked before the final writes. The fixed testbench accepts only the synchronous final-write handshake.

Files here are textual logs and runtime metadata only; the large SHM database was intentionally not copied.
