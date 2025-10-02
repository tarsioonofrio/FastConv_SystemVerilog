# TC4 parameter package

`pack_param.sv` captures the Winograd dimensions for the TC4 kernel.

| Parameter | Value | Description |
|-----------|-------|-------------|
| `A_SIZE` | 4 | Output tile dimension. |
| `B_SIZE` | 3 | Auxiliary stride dimension. |
| `C_SIZE` | 6 | Input tile dimension after padding. |
| `M_SIZE` | 6 | Winograd-domain tile dimension. |

Import this package before `pack_typedef` so the TC4-specific types expand correctly.
