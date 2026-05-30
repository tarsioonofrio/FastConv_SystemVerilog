# TC3 parameter package

`pack_param.sv` encodes the Winograd dimensions for the TC3 kernel.

| Parameter | Value | Description |
|-----------|-------|-------------|
| `A_SIZE` | 3 | Output tile dimension. |
| `CONV_KERNEL_SIZE` | 3 | Auxiliary stride dimension. |
| `C_SIZE` | 5 | Input tile dimension after padding. |
| `M_SIZE` | 5 | Winograd-domain tile dimension. |

Import this package ahead of `pack_typedef` so the TC3 type aliases receive the correct sizes.
