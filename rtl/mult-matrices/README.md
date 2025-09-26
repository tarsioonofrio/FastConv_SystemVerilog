# Winograd transform matrices

Each subdirectory captures a Winograd tile configuration (tile size, channel count, and schedule) and provides the structural matrices used by the convolution core.

Every `mult_matrices.sv` exports the same set of modules with identical interfaces:

## `Transform`
Applies the Winograd input transform to convert the spatial feature tile into the Winograd domain.

### Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| `QUANT` | `int` | Fractional precision propagated through the transform. |
| `NBITS` | `int` | Bit width of each element in the feature matrices. |

### Ports
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `pin` | Input | `type_input` | Spatial-domain feature tile. |
| `pout` | Output | `type_weight` | Transformed tile aligned with the multiplier bank. |

## `Inverse`
Applies the inverse Winograd transform to bring the accumulated tile back to the spatial domain.

### Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| `QUANT` | `int` | Fractional precision carried in the intermediate matrices. |
| `NBITS` | `int` | Bit width of each element in the weight/output matrices. |

### Ports
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `pin` | Input | `type_weight` | Tile in the Winograd domain after element-wise multiplication. |
| `pout` | Output | `type_output` | Spatial-domain result tile. |

## Matrix stages
The helper stages (`MatrixC0`, `MatrixC1`, `MatrixA1`, `MatrixA0`) implement the actual constant-coefficient reductions used by the two transforms.

### `MatrixC0`
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `P` | Input | `type_input` | Feature tile entering the first transform stage. |
| `soma` | Output | `type_matrix_c` | Intermediate matrix after the first constant combination. |

### `MatrixC1`
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `P` | Input | `type_matrix_c` | Intermediate matrix produced by `MatrixC0`. |
| `soma` | Output | `type_weight` | Winograd-domain feature/weight tile forwarded to the multipliers. |

### `MatrixA1`
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `P` | Input | `type_weight` | Winograd-domain accumulator values. |
| `soma` | Output | `type_matrix_a` | Intermediate matrix prior to the spatial reconstruction. |

### `MatrixA0`
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `P` | Input | `type_matrix_a` | Intermediate matrix from `MatrixA1`. |
| `soma` | Output | `type_output` | Reconstructed spatial tile. |

The constants, CSA instantiations, and operand scheduling differ between tile configurations; refer to each subdirectory for the specific wiring.
