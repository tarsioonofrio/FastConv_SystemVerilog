# IFN9 Winograd matrices

Both `mult_matrices.sv` and `mult_matrices_simplified.sv` expose identical module interfaces for the IFN9 configuration (`C1_SIZE = 5`, `M1_SIZE = 6`, `A1_SIZE = 3`). The simplified version collapses temporary wires but keeps the same ports.

Type widths:
- `type_input`: 25 elements (`5×5`).
- `type_weight`: 36 elements (`6×6`).
- `type_output`: 9 elements (`3×3`).
- `type_matrix_c`: 30 elements (`C1_SIZE*M1_SIZE`).
- `type_matrix_a`: 30 elements.

## `Transform`
### Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| `QUANT` | `int` | Fractional precision propagated through the forward transform. |
| `NBITS` | `int` | Bit width for each operand. |

### Ports
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `pin` | Input | `type_input` | 5×5 spatial feature tile. |
| `pout` | Output | `type_weight` | 6×6 Winograd-domain tile feeding the multiplier array. |

## `Inverse`
### Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| `QUANT` | `int` | Fractional precision retained for the reconstruction. |
| `NBITS` | `int` | Bit width of each Winograd-domain element. |

### Ports
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `pin` | Input | `type_weight` | 6×6 Winograd-domain accumulator tile. |
| `pout` | Output | `type_output` | 3×3 spatial tile returned to the control block. |

## Matrix stages
| Module | Input port | Output port | Description |
|--------|------------|-------------|-------------|
| `MatrixC0` | `P : type_input` | `soma : type_matrix_c` | First constant combination for the forward transform. |
| `MatrixC1` | `P : type_matrix_c` | `soma : type_weight` | Produces the Winograd-domain coefficients. |
| `MatrixA1` | `P : type_weight` | `soma : type_matrix_a` | Begins the inverse transform. |
| `MatrixA0` | `P : type_matrix_a` | `soma : type_output` | Emits the 3×3 spatial tile. |

Both source variants instantiate the same CSA primitives from `rtl/csa` to implement the add/subtract schedule.
