# IF3 parameter package

`pack_param.sv` configures the Winograd sizes for the IF3 kernel using single-dimension parameters.

| Parameter | Value | Description |
|-----------|-------|-------------|
| `A_SIZE` | 3 | Spatial output tile dimension. |
| `B_SIZE` | 3 | Stride/transform helper dimension. |
| `C_SIZE` | 5 | Input tile dimension after padding. |
| `M_SIZE` | 6 | Winograd-domain tile dimension (matches the multiplier bank). |

Import this package before `pack_typedef` to size the IF3 data types correctly.
