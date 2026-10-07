# WPN16 m32 MAC operand-isolation experiment

This is an independent experiment based on the unisolated WPN16 m32 core.
It masks both operands of each multiplier to zero outside `HADAMARD`, the only
state in which `w_hadamard_product_current` is captured into the registered
product bank. The transform, multiplier count, arithmetic, FSM, and capture
edge are otherwise unchanged.

| Item | Value |
| --- | --- |
| Variant | `conv-wpn16-i60-h41-t64-o16-m32-stream16-prefetch24-rowconst8-trunc-column-mac-operand-isolation.sv` |
| Baseline | `conv-wpn16-i60-h41-t64-o16-m32-stream16-prefetch24-rowconst8-trunc-column.sv` |
| Data width | 16 bits |
| MAC count / prefetch | 32 / 24 words |
| Workload | canonical WPN16 `sim-032-3-3-normal-trunc-nbits16` |
| Local RTL simulation | PASS: 8,100 valid writes, 576 inverse tiles, 5,387 active job cycles |
| Genus / Xcelium / Joules | Not yet run |

The power comparison must use the same routed-SDF simulation mode, TT corner,
and active-job window (101 ns through 10,875 ns) for baseline and candidate.
The full-job and category/hierarchy reports will be recorded here after the
remote flow completes. This document does not treat RTL switching estimates
as measured power.
