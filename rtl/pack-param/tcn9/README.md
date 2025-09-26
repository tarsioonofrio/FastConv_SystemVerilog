# TCN9 parameter package

`pack_param.sv` establishes the Winograd dimensions for the TCN9 kernel.

| Parameter | Value | Description |
|-----------|-------|-------------|
| `A1_SIZE` | 3 | Output tile width. |
| `A2_SIZE` | 3 | Output tile height. |
| `B1_SIZE` | 3 | Auxiliary stride factor (first dimension). |
| `B2_SIZE` | 3 | Auxiliary stride factor (second dimension). |
| `C1_SIZE` | 5 | Input tile width after padding. |
| `C2_SIZE` | 5 | Input tile height after padding. |
| `M1_SIZE` | 5 | Winograd-domain tile width. |
| `M2_SIZE` | 5 | Winograd-domain tile height. |

Additional constant:
- `c_index[25]`: permutation that maps the multiplier order to the Winograd tile layout.

Bring this package into scope before `pack_typedef` so the type aliases reflect the TCN9 sizes.
