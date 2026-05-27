# TC2 parameter package

`pack_param.sv` provides the scalar Winograd dimensions for the TC2 kernel.

| Parameter | Value | Description |
|-----------|-------|-------------|
| `A_SIZE` | 2 | Output tile dimension. |
| `CONV_KERNEL_SIZE` | 3 | Auxiliary Winograd stride dimension. |
| `C_SIZE` | 4 | Input tile dimension after padding. |
| `M_SIZE` | 4 | Winograd-domain tile dimension. |

Import this package before `pack_typedef` so that TC2 type aliases expand to the correct lengths.
