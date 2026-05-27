# TC3 multiplier multiplexers

The TC3 tile requires five Winograd registers. The provided `MuxMult` modules share the interface below.

## Ports (all variants)
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `idx_in` | Input | `logic [$clog2(SMULT)-1:0]` | Indicates the current phase within the schedule. |
| `idx_out` | Output | `logic [$clog2(NMULT*SMULT)-1:0] idx_out[0:NMULT-1]` | Register indices to read for each multiplier lane. |

## Variants
| File | `NMULT` | `SMULT` | Description |
|------|---------|---------|-------------|
| `mux_mult_01.sv` | 1 | 5 | Serially iterates across the five registers. |
| `mux_mult_05.sv` | 5 | 1 | Fully parallel version with one register per multiplier. |
