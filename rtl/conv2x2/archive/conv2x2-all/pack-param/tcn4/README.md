# TCN4 parameter package

`pack_param.sv` fixes the Winograd dimensions for the TCN4 kernel.

| Parameter | Value | Description |
|-----------|-------|-------------|
| `A1_SIZE` | 2 | Spatial output tile width/height. |
| `A2_SIZE` | 2 | Duplicate of `A1_SIZE` for the second dimension. |
| `B1_SIZE` | 3 | Internal Winograd stride factor (kept for completeness). |
| `B2_SIZE` | 3 | Duplicate of `B1_SIZE`. |
| `C1_SIZE` | 4 | Padded input tile width/height. |
| `C2_SIZE` | 4 | Duplicate of `C1_SIZE`. |
| `M1_SIZE` | 4 | Winograd-domain tile width/height. |
| `M2_SIZE` | 4 | Duplicate of `M1_SIZE`. |

Additional constants:
- `c_index[16]`: lookup table mapping multiplier outputs to their position in the Winograd tile.

Import this package before `pack_typedef` so type aliases (`type_input`, `type_weight`, etc.) expand to the TCN4 sizes.
