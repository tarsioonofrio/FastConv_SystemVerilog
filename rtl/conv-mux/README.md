# Convolution core

`conv.sv` holds the Winograd convolution engine that consumes feature and weight tiles, as well as the scalar multiplier used inside the datapath.

## `Conv`
The main module orchestrates the Winograd transforms and multiplier bank. It imports `pack_def`, `pack_param`, `pack_typedef`, and `pack_mux_mult` for common dimensions and index schedules.

### Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| `QUANT` | `int` | Number of fractional bits kept from the multiplier outputs. |
| `NBITS` | `int` | Element width for the feature, weight, and accumulator arrays. |

### Ports
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk` | Input | `logic` | Clock for the pipeline. |
| `reset` | Input | `logic` | Active-high asynchronous reset used in the sequential logic. |
| `p_start` | Input | `logic` | Asserts when the control block loads a new tile. |
| `p_end` | Output | `logic` | Raised for one cycle when the tile finishes processing. |
| `p_input` | Input | `type_input` | Feature tile in Winograd order after the control FSM pushes memory data. |
| `p_weight` | Input | `type_weight` | Weight tile supplied by the control FSM. |
| `p_output` | Output | `type_output` | Filtered tile after inverse Winograd transform. |

## `Multip`
This helper module performs a single quantized multiply and truncates the product back to `NBITS`.

### Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| `QUANT` | `int` | Fractional precision carried in the internal product. |
| `NBITS` | `int` | Output width of the truncated product. |

### Ports
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `register` | Input | `logic_vector` | Feature/register operand selected by `MuxMult`. |
| `weight` | Input | `logic_vector` | Weight operand aligned with the feature element. |
| `product` | Output | `logic signed [NBITS-1+QUANT:0]` | Multiplier result truncated to `NBITS` bits and widened by `QUANT` internally. |
