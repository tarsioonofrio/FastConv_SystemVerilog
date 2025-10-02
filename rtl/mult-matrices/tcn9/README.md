# TCN9 Winograd matrices

`mult_matrices.sv` captures the 5×5 Winograd transform used by the TCN9 configuration where `C1_SIZE = 5` and `A1_SIZE = 3`.

Derived type widths inside the file:
- `type_input`: 25 elements.
- `type_weight`: 25 elements.
- `type_output`: 9 elements.
- `type_matrix_c`: 25 elements.
- `type_matrix_a`: 25 elements.

## `Transform`
### Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| `QUANT` | `int` | Fractional precision that accompanies the Winograd-domain computations. |
| `NBITS` | `int` | Bit width for each feature value. |

### Ports
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `pin` | Input | `type_input` | 5×5 spatial tile. |
| `pout` | Output | `type_weight` | 5×5 Winograd-domain tile prepared for element-wise multiplication. |

## `Inverse`
### Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| `QUANT` | `int` | Fractional precision forwarded to the reconstruction stage. |
| `NBITS` | `int` | Bit width for each Winograd-domain element. |

### Ports
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `pin` | Input | `type_weight` | 5×5 Winograd-domain accumulator tile. |
| `pout` | Output | `type_output` | 3×3 spatial tile emitted to the control block. |

## Matrix stages
| Module | Input port | Output port | Description |
|--------|------------|-------------|-------------|
| `MatrixC0` | `P : type_input` | `soma : type_matrix_c` | First constant combination of the 5×5 tile. |
| `MatrixC1` | `P : type_matrix_c` | `soma : type_weight` | Completes the Winograd-domain projection. |
| `MatrixA1` | `P : type_weight` | `soma : type_matrix_a` | First half of the inverse transform. |
| `MatrixA0` | `P : type_matrix_a` | `soma : type_output` | Produces the 3×3 spatial tile. |

CSA instances from `rtl/csa` realize the repeated additions and subtractions encoded by this configuration’s matrices.
