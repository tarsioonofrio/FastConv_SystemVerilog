# TCN16 multiplier multiplexers

The TCN16 tile can trade multipliers for latency. Each file in this directory defines a `pack_mux_mult` package and a `MuxMult` module with the shared port list below.

## Ports (all variants)
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `idx_in` | Input | `logic [$clog2(SMULT)-1:0]` | Selects the current register slice feeding the multiplier array. |
| `idx_out` | Output | `logic [$clog2(NMULT*SMULT)-1:0] idx_out[0:NMULT-1]` | Provides the register index for each multiplier lane. |

## Variants
| File | `NMULT` | `SMULT` | Description |
|------|---------|---------|-------------|
| `mux_mult_01.sv` | 1 | 36 | Serial implementation iterating across all 36 register elements. |
| `mux_mult_02.sv` | 2 | 18 | Two multipliers split the register file into two halves. |
| `mux_mult_03.sv` | 3 | 12 | Three multipliers consume 12-register strides. |
| `mux_mult_04.sv` | 4 | 9 | Four multipliers work on nine-element groups. |
| `mux_mult_06.sv` | 6 | 6 | Six multipliers each handle a 6-deep slice. |
| `mux_mult_09.sv` | 9 | 4 | Nine multipliers cycle through four registers per step. |
| `mux_mult_12.sv` | 12 | 3 | Twelve multipliers cover a trio of registers per cycle. |
| `mux_mult_18.sv` | 18 | 2 | Eighteen multipliers alternate between two registers. |
| `mux_mult_36.sv` | 36 | 1 | Fully parallel implementation with one register per multiplier per cycle. |

Pick the variant that matches the available DSP budget and desired throughput.
