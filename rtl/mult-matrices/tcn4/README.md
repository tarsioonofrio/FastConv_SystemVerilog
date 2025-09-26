# TCN4 Winograd matrices

`mult_matrices.sv` describes the Winograd transforms for the tile configuration with `C1_SIZE = 4` and `A1_SIZE = 2`. The package `packConv` inside the file exposes the following type widths:

- `type_input`: 16 elements (`C1_SIZE*C1_SIZE`).
- `type_weight`: 16 elements (`M1_SIZE*M1_SIZE`).
- `type_output`: 4 elements (`A1_SIZE*A1_SIZE`).
- `type_matrix_c` and `type_matrix_a`: 16 elements each.

## `Transform`
### Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| `QUANT` | `int` | Fractional precision preserved through the Winograd transform. |
| `NBITS` | `int` | Bit width for each element in the feature tile. |

### Ports
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `pin` | Input | `type_input` | Spatial feature tile (`16` entries). |
| `pout` | Output | `type_weight` | Winograd-domain tile aligned with the multiplier bank (`16` entries). |

## `Inverse`
### Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| `QUANT` | `int` | Fractional precision forwarded to the reconstruction stage. |
| `NBITS` | `int` | Bit width for each Winograd-domain element. |

### Ports
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `pin` | Input | `type_weight` | Winograd-domain accumulator (`16` entries). |
| `pout` | Output | `type_output` | Spatial output tile (`4` entries). |

## Matrix stages
`MatrixC0`, `MatrixC1`, `MatrixA1`, and `MatrixA0` connect the CSA reductions with the constant schedules for this tile size.

| Module | Input port | Output port | Description |
|--------|------------|-------------|-------------|
| `MatrixC0` | `P : type_input` | `soma : type_matrix_c` | First half of the input transform. |
| `MatrixC1` | `P : type_matrix_c` | `soma : type_weight` | Completes the Winograd-domain feature tile. |
| `MatrixA1` | `P : type_weight` | `soma : type_matrix_a` | First half of the inverse transform. |
| `MatrixA0` | `P : type_matrix_a` | `soma : type_output` | Produces the 2×2 spatial tile. |

Each stage uses CSA modules from `rtl/csa` to implement the fixed add/subtract patterns required by the Winograd algorithm.
