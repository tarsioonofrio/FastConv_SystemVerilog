# IF3 multiplier multiplexers

These variants target the IF3 kernel, covering different multiplier budgets with a shared module interface.

## Ports (all variants)
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `idx_in` | Input | `logic [$clog2(SMULT)-1:0]` | Step within the Winograd schedule for the current tile. |
| `idx_out` | Output | `logic [$clog2(NMULT*SMULT)-1:0] idx_out[0:NMULT-1]` | Register indices handed to each multiplier lane. |

## Variants
| File | `NMULT` | `SMULT` | Description |
|------|---------|---------|-------------|
| `mux_mult_01.sv` | 1 | 6 | Serial traversal of the six register positions. |
| `mux_mult_02.sv` | 2 | 3 | Two multipliers divide the register file into three-element chunks. |
| `mux_mult_03.sv` | 3 | 2 | Three multipliers toggle between paired registers. |
| `mux_mult_06.sv` | 6 | 1 | Six multipliers operate fully in parallel. |
