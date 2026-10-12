# Synthesis workload

- RTL: archived WPN16 pretransformed feature-bank, 32 multipliers.
- Dataset: `sim-032-3-12-normal-trunc-nbits16`.
- Channels: Cin=3, Cout=12.
- Parameters: NBITS=16, QUANT=8.
- The config provides the complete ASIC sequence: logical synthesis, SDF gate-level simulation, then Joules power using the captured SHM.
