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
| Post-synthesis SDF simulation | PASS: 8,100 valid writes, zero golden mismatches; 0 SDF errors, 5,546 SDF warnings |
| Genus / Joules | Complete; see [EXPERIMENT_RESULTS.md](EXPERIMENT_RESULTS.md) |
| Timing | MET: 10 ps slow-corner slack; 224 ps typical-corner slack |
| Active-job dynamic power | 11.21060 mW, versus 9.48020 mW baseline (+18.25%) |

Conclusion: this zero-masking implementation is functionally correct but is
not a power optimization. The added operand gating increases logic and MAC
hierarchy activity enough to outweigh the reduction in register power. Keep
this variant experimental; do not replace the unisolated baseline.

Power values are tool estimates from Joules, not physical board measurements.
The comparison uses the same routed-SDF simulation mode, TT corner, PLE, and
accepted-job window (101 ns through 10,875 ns) for baseline and candidate.
