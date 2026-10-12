# RTL functional simulation

Command:

```sh
cd rtl/conv4x4
make run-std-column CONFIG=wpn16 NUM_MULT=32 \
  DATASET=sim-032-3-12-normal-trunc-nbits16 \
  STD_COLUMN_SRC=./conv-wpn16-i60-h41-t64-o16-m32-stream16-prefetch24-transformed-rowstream-column.sv \
  STD_COLUMN_TB=./testbench_wpn16_std_column.sv
```

Result with Verilator 5.050: PASS, 2,304 inverse events, 32,400 valid output
writes, and zero golden mismatches. The testbench's job interval is 43.640 us
(21,820 cycles at 2 ns); its cycle counter reports 21,821 because it includes
the accepted-start edge. The 1,728 clipped input samples and 4,464 invalid
output words are expected edge-padding cases.

This is RTL functional simulation only. No synthesis, gate-level simulation,
or power result is recorded in this configuration yet.
