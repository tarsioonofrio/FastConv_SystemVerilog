# TCN16 parameter package

`pack_param.sv` defines the Winograd geometry for the TCN16 kernel.

| Parameter | Value | Description |
|-----------|-------|-------------|
| `A1_SIZE` | 4 | Output tile width. |
| `A2_SIZE` | 4 | Output tile height. |
| `B1_SIZE` | 3 | Auxiliary stride factor (first dimension). |
| `B2_SIZE` | 3 | Auxiliary stride factor (second dimension). |
| `C1_SIZE` | 6 | Input tile width after padding. |
| `C2_SIZE` | 6 | Input tile height after padding. |
| `M1_SIZE` | 6 | Winograd-domain tile width. |
| `M2_SIZE` | 6 | Winograd-domain tile height. |

Additional constant:
- `c_index[36]`: permutation that aligns multiplier outputs with the transform order.

Import this package before `pack_typedef` to ensure all type aliases match the TCN16 tile size.
