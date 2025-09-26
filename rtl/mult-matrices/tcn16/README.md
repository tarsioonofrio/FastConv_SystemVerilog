# TCN16 Winograd matrices

This directory contains the 6×6 Winograd transforms (`C1_SIZE = 6`) that produce 4×4 output tiles (`A1_SIZE = 4`).

Type widths provided by the embedded `packConv` package:
- `type_input`: 36 elements.
- `type_weight`: 36 elements.
- `type_output`: 16 elements.
- `type_matrix_c`: 36 elements.
- `type_matrix_a`: 36 elements.

## `Transform`
### Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| `QUANT` | `int` | Fractional precision retained in the Winograd domain. |
| `NBITS` | `int` | Bit width for each input element. |

### Ports
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `pin` | Input | `type_input` | 6×6 spatial tile. |
| `pout` | Output | `type_weight` | 6×6 Winograd-domain tile. |

## `Inverse`
### Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| `QUANT` | `int` | Fractional precision preserved through the reconstruction. |
| `NBITS` | `int` | Bit width of the Winograd-domain elements. |

### Ports
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `pin` | Input | `type_weight` | 6×6 Winograd-domain accumulator. |
| `pout` | Output | `type_output` | 4×4 spatial tile for the result feature map. |

## Matrix stages
| Module | Input port | Output port | Description |
|--------|------------|-------------|-------------|
| `MatrixC0` | `P : type_input` | `soma : type_matrix_c` | First reduction layer of the input transform. |
| `MatrixC1` | `P : type_matrix_c` | `soma : type_weight` | Completes the Winograd-domain projection. |
| `MatrixA1` | `P : type_weight` | `soma : type_matrix_a` | First layer of the inverse transform. |
| `MatrixA0` | `P : type_matrix_a` | `soma : type_output` | Emits the 4×4 spatial tile. |

Refer to the source for the exact CSA wiring pattern corresponding to the TCN16 schedule.
