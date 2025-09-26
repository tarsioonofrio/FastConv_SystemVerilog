# Control module

`control.sv` implements the FastConv control finite-state machine. It sequences data movement between SRAMs and the convolution datapath while tracking tile, channel, and window counters derived from the Winograd flow.

## `Control`
The module imports `pack_def`, `pack_typedef`, and `pack_param` to pick up shared widths and type aliases.

### Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| `NADDR` | `int` | Address width for feature, weight, and output SRAMs. |
| `NBITS` | `int` | Bit width for feature, weight, and output elements (matches `logic_vector`). |
| `LATENCY` | `int` | Number of cycles between asserting `p_read_en` and expecting `p_read_valid`. |
| `ROM` | `int` | When set, the read memory returns constant data from `const_data`; otherwise it reads/writes SRAM. |
| `QUANT` | `int` | Quantization bit width passed to the convolution core for multiplier sizing. |
| `N_WINDOW` | `int` | Number of Winograd windows processed per feature map. |
| `N_CHANNEL_IN` | `int` | Number of input feature channels. |
| `N_CHANNEL_OUT` | `int` | Number of output channels produced by the convolution. |
| `FEAT_INPUT_SIZE` | `int` | Spatial dimension of the padded input tile (per side). |
| `FEAT_OUTPUT_SIZE` | `int` | Spatial dimension of the output tile (per side). |
| `LAST_WINDOW` | `int` | Flag indicating the final window for a sequence, used to gate the `p_end` pulse. |

### Ports
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk` | Input | `logic` | Clock. |
| `reset` | Input | `logic` | Active-high synchronous reset with asynchronous assertion. |
| `p_start` | Input | `logic` | Launches processing of a new tile/window. |
| `p_end` | Output | `logic` | Pulses high when all windows in the sequence finish. |
| `p_conv_start` | Output | `logic` | Starts a convolution burst in the datapath. |
| `p_conv_end` | Input | `logic` | Completion handshake from the convolution core. |
| `p_input` | Output | `type_input` | Feature tile written into the convolution registers. |
| `p_weight` | Output | `type_weight` | Weight tile forwarded to the convolution core. |
| `p_output` | Input | `type_output` | Accumulated result tile returned from the convolution core. |
| `p_read_en` | Output | `logic` | Enables the SRAM read port. |
| `p_read_addr` | Output | `logic [NADDR-1:0]` | Address for feature/weight SRAM access. |
| `p_read_data` | Input | `logic_vector` | Data returned by the SRAM or ROM. |
| `p_read_valid` | Input | `logic` | Indicates the read data is ready after the configured latency. |
| `p_write_en` | Output | `logic` | Write-enable for the output SRAM. |
| `p_write_addr` | Output | `logic [NADDR-1:0]` | Address for storing convolution outputs. |
| `p_write_data` | Output | `logic_vector` | Output feature-map sample to commit to memory. |
