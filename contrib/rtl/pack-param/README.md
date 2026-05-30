# Parameter packages

Every subdirectory supplies a `pack_param` package that fixes the Winograd tile geometry for a specific kernel family (TC*, TCN*, IF*). Each package exports the parameters listed below along with any index tables needed by the transforms.

| Parameter | Description |
|-----------|-------------|
| `A1_SIZE`, `A2_SIZE` | Spatial dimensions of the output tile for the first/second dimension. |
| `B1_SIZE`, `B2_SIZE` | Stride matrices used internally by certain Winograd formulations (kept for completeness). |
| `C1_SIZE`, `C2_SIZE` | Input tile dimensions after padding. |
| `M1_SIZE`, `M2_SIZE` | Winograd-domain (transformed) tile dimensions. |

Each package also exposes a constant array such as `c_index` that maps multiplier outputs back into the transform order. Consult the individual subdirectories for the concrete values tied to each kernel.
