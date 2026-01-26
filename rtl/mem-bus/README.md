# Column-wide memory model

`mem.sv` implements a simple SRAM/ROM model that reads or writes an entire column per cycle.

## Interface

- `data_in` and `data_out` are arrays of `COLUMN_LANES` elements.
- `address` points to the top row of the column; each lane offsets by `lane * FEAT_SIZE`.
- When `ROM=1`, the model sources data from `const_data` (same as the scalar memory).
- `data_valid` asserts after `LATENCY` cycles of `chip_en`.

## Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| `NADDR` | int | Address width for the memory array. |
| `NBITS` | int | Data width per element. |
| `LATENCY` | int | Read latency in cycles. |
| `ROM` | int | When `1`, uses `const_data` as ROM. |
| `FEAT_SIZE` | int | Feature-map row size used to compute lane strides. |
| `COLUMN_LANES` | int | Number of rows read/written per cycle. |

Use this model in testbenches that expect the control-bus column interface.
