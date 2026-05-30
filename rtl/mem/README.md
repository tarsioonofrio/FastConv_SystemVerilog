# SRAM model

`mem.sv` implements a configurable single-port memory used for both read-only tiles and writable feature/output buffers.

## `Memory`
Imports `data`, `pack_def`, and `pack_typedef` to gain access to initialization vectors and shared widths.

### Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| `NADDR` | `int` | Address width (number of bits) of the memory. |
| `NBITS` | `int` | Width of each stored element. |
| `LATENCY` | `int` | Number of cycles between enabling a read and the data becoming valid. |
| `ROM` | `int` | When `1`, drives the output from the constant dataset instead of the writable array. |
| `CONST_DATA_SIZE` | `int` | Optional explicit size of a constant ROM vector. |
| `CONST_DATA[]` | `int[]` | Optional explicit constant ROM vector. |

When `ROM==1`:

- If `CONST_DATA_SIZE > 0`, the module uses `CONST_DATA`/`CONST_DATA_SIZE`.
- Otherwise, it falls back to `pack_data::const_data`.

### Ports
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk` | Input | `logic` | Clock. |
| `reset` | Input | `logic` | Active-high reset clears the writable array. |
| `chip_en` | Input | `logic` | Enables the memory for read or write operations. |
| `wr_en` | Input | `logic` | Write enable; when high with `chip_en`, stores `data_in`. |
| `address` | Input | `logic [NADDR-1:0]` | Address of the element to read or write. |
| `data_in` | Input | `logic_vector` | Data to be written on the rising edge. |
| `data_out` | Output | `logic_vector` | Data returned from the selected address. |
| `data_valid` | Output | `logic` | Indicates `data_out` reflects a completed read considering `LATENCY`. |
