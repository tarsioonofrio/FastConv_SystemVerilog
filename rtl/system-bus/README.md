# Top-level system wrapper

`system.sv` composes the control-bus controller, convolution core, and column-wide SRAM models into a synthesizable accelerator.

## `System`
### Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| `NADDR` | `int` | Address width shared by the SRAM instances. |
| `NBITS` | `int` | Data width for feature, weight, and output elements. |
| `LATENCY` | `int` | Latency of the read SRAM used for features/weights. |
| `ROM` | `int` | When `1`, the read SRAM behaves as a ROM using `const_data`. |
| `QUANT` | `int` | Fractional precision for the convolution multipliers. |
| `N_WINDOW` | `int` | Number of Winograd windows per workload. |
| `N_CHANNEL_IN` | `int` | Number of input channels processed. |
| `N_CHANNEL_OUT` | `int` | Number of output channels generated. |
| `FEAT_INPUT_SIZE` | `int` | Input tile dimension (per side). |
| `FEAT_OUTPUT_SIZE` | `int` | Output tile dimension (per side). |
| `LAST_WINDOW` | `int` | Flag identifying the last window in the workload. |

### Ports
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk` | Input | `logic` | Clock. |
| `reset` | Input | `logic` | Active-high reset. |
| `p_start` | Input | `logic` | Launches processing of a workload. |
| `p_end` | Output | `logic` | Pulses high when the workload completes. |

Internally, the module wires:
- `Control` (see `rtl/control-bus/README.md`) for sequencing and column-wide addressing.
- Two `MemoryBus` instances (`rtl/mem-bus/README.md`) for column-wide read/write paths.
- The `Conv` engine (`rtl/conv-mux/README.md`) for Winograd computation.

Simulation harnesses (`testbench.sv`, `sim.tcl`, `wave.do`) exercise the wrapper in this directory.
