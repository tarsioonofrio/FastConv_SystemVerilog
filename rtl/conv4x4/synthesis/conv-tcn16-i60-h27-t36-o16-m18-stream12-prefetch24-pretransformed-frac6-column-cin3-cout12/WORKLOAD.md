# Synthesis workload

- RTL: active TCN16 pretransformed frac6, 18 multipliers.
- Dataset: `sim-032-3-12-normal-trunc-frac6-nbits20`.
- Channels: Cin=3, Cout=12.
- Parameters: NBITS=20, QUANT=8.
- The config provides the complete ASIC sequence: logical synthesis, SDF gate-level simulation, then Joules power using the captured SHM.
