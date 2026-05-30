# IFN9 multiplier multiplexers

The IFN9 tile shares the same multiplier scaling options as TCN16 (36 register entries) but maps to the IFN9 Winograd schedule. Every file defines the standard `MuxMult` interface with the ports below.

## Ports (all variants)
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `idx_in` | Input | `logic [$clog2(SMULT)-1:0]` | Indicates which register slice feeds the multipliers this cycle. |
| `idx_out` | Output | `logic [$clog2(NMULT*SMULT)-1:0] idx_out[0:NMULT-1]` | Register indices provided to each multiplier lane. |

## Variants
| File | `NMULT` | `SMULT` | Description |
|------|---------|---------|-------------|
| `mux_mult_01.sv` | 1 | 36 | Serial implementation iterating through all 36 registers. |
| `mux_mult_02.sv` | 2 | 18 | Two multipliers cover 18 registers each. |
| `mux_mult_03.sv` | 3 | 12 | Three multipliers walk 12-register strides. |
| `mux_mult_04.sv` | 4 | 9 | Four multipliers read nine consecutive registers per cycle. |
| `mux_mult_06.sv` | 6 | 6 | Six multipliers rotate across six registers. |
| `mux_mult_09.sv` | 9 | 4 | Nine multipliers alternate over four registers. |
| `mux_mult_12.sv` | 12 | 3 | Twelve multipliers consume three registers at a time. |
| `mux_mult_18.sv` | 18 | 2 | Eighteen multipliers toggle between paired registers. |
| `mux_mult_36.sv` | 36 | 1 | Fully parallel implementation with one register per lane. |
