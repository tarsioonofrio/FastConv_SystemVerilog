# TC2 multiplier multiplexers

Modules here schedule the four Winograd registers required by the TC2 configuration.

## Ports (all variants)
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `idx_in` | Input | `logic [$clog2(SMULT)-1:0]` | Phase within the TC2 multiplier schedule. |
| `idx_out` | Output | `logic [$clog2(NMULT*SMULT)-1:0] idx_out[0:NMULT-1]` | Register indices supplied to each multiplier. |

## Variants
| File | `NMULT` | `SMULT` | Description |
|------|---------|---------|-------------|
| `mux_mult_01.sv` | 1 | 4 | Serial implementation over the four register positions. |
| `mux_mult_02.sv` | 2 | 2 | Two multipliers alternate between register pairs. |
| `mux_mult_04.sv` | 4 | 1 | Four multipliers operate fully in parallel. |
