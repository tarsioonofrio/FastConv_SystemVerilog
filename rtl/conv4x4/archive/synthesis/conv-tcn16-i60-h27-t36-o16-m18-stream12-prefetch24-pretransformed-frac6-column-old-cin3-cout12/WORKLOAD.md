# Synthesis workload

- RTL: archived TCN16 pretransformed frac6 `old` revision, 18 multipliers; artifacts are from the 2026-10-12 run.
- Source RTL: `rtl/conv4x4/archive/tcn16-pretransformed/conv-tcn16-i60-h27-t36-o16-m18-stream12-prefetch24-pretransformed-frac6-column-old.sv`.
- Dataset: `sim-032-3-12-normal-trunc-frac6-nbits20`.
- Channels: Cin=3, Cout=12.
- Parameters: NBITS=20, QUANT=8.
- The config provides the complete ASIC sequence: logical synthesis, SDF gate-level simulation, then Joules power using the captured SHM.
