# TCN4 multiplier multiplexers

Each source exports a `pack_mux_mult` package and a `MuxMult` module tuned for the TCN4 Winograd tile. The modules reuse the port list below.

## Ports (all variants)
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `idx_in` | Input | `logic [$clog2(SMULT)-1:0]` | Indicates which slice of the register file should feed the multipliers. |
| `idx_out` | Output | `logic [$clog2(NMULT*SMULT)-1:0] idx_out[0:NMULT-1]` | Provides one register index per multiplier lane. |

## Variants
| File | `NMULT` | `SMULT` | States covered | Notes |
|------|---------|---------|----------------|-------|
| `mux_mult_01.sv` | 1 | 16 | 16 indices (0–15) | Single multiplier cycles through all registers sequentially. |
| `mux_mult_02.sv` | 2 | 8 | 8 index pairs | Two multipliers walk eight two-element groups per tile. |
| `mux_mult_04.sv` | 4 | 4 | 4 index quads | Four multipliers read four contiguous registers each cycle. |
| `mux_mult_08.sv` | 8 | 2 | 2 index octets | Eight multipliers toggle between paired registers. |
| `mux_mult_16.sv` | 16 | 1 | 1 index set (0–15) | Sixteen multipliers each fetch a dedicated register every cycle. |

Choose the variant that matches the hardware budget for the target convolution core.
