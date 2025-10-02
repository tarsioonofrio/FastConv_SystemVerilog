# TCN9 multiplier multiplexers

All variants contain the `pack_mux_mult` package defining the number of multiplier lanes (`NMULT`) and the register slices traversed per lane (`SMULT`). The shared module interface is shown below.

## Ports (all variants)
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `idx_in` | Input | `logic [$clog2(SMULT)-1:0]` | Indicates the current step within the Winograd tile schedule. |
| `idx_out` | Output | `logic [$clog2(NMULT*SMULT)-1:0] idx_out[0:NMULT-1]` | Register indices for each multiplier lane. |

## Variants
| File | `NMULT` | `SMULT` | Description |
|------|---------|---------|-------------|
| `mux_mult_01.sv` | 1 | 25 | Single multiplier iterates over the 25 Winograd-domain registers. |
| `mux_mult_05.sv` | 5 | 5 | Five multipliers cooperate, each visiting a stride-5 pattern per cycle. |
| `mux_mult_25.sv` | 25 | 1 | Fully parallel implementation with one register per multiplier lane each cycle. |

Select the implementation that matches the available multiplier budget.
