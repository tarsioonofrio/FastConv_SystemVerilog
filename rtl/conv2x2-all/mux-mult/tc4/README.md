# TC4 multiplier multiplexers

Modules here provide the register scheduling for the TC4 Winograd tile (six register entries).

## Ports (all variants)
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `idx_in` | Input | `logic [$clog2(SMULT)-1:0]` | Indicates which register slice should feed the multipliers. |
| `idx_out` | Output | `logic [$clog2(NMULT*SMULT)-1:0] idx_out[0:NMULT-1]` | Register indices produced for each multiplier lane. |

## Variants
| File | `NMULT` | `SMULT` | Description |
|------|---------|---------|-------------|
| `mux_mult_01.sv` | 1 | 6 | Serial access across six registers. |
| `mux_mult_02.sv` | 2 | 3 | Two multipliers cover three registers each. |
| `mux_mult_03.sv` | 3 | 2 | Three multipliers toggle between register pairs. |
| `mux_mult_06.sv` | 6 | 1 | Fully parallel implementation with six multipliers. |
