# IFN9 parameter package

`pack_param.sv` fixes the geometry for the IFN9 Winograd kernel.

| Parameter | Value | Description |
|-----------|-------|-------------|
| `A1_SIZE` | 3 | Output tile width. |
| `A2_SIZE` | 3 | Output tile height. |
| `B1_SIZE` | 3 | Auxiliary Winograd stride factor (first dimension). |
| `B2_SIZE` | 3 | Auxiliary stride factor (second dimension). |
| `C1_SIZE` | 5 | Input tile width after padding. |
| `C2_SIZE` | 5 | Input tile height after padding. |
| `M1_SIZE` | 6 | Winograd-domain tile width. |
| `M2_SIZE` | 6 | Winograd-domain tile height. |

Additional constant:
- `c_index[25]`: maps the flattened Winograd-domain coefficients into multiplier order.

Import this package before `pack_typedef` so all type aliases match the IFN9 dimensions.
