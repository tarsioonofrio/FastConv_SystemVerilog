# Global parameter overrides

`pack_def.sv` centralizes the default FastConv configuration. Each item below is exposed as a package parameter so every module can import the same value. The package also allows overriding any setting at compile time by defining the corresponding macro (``+define+NADDR=...`` etc.).

| Parameter | Type | Description |
|-----------|------|-------------|
| `NADDR` | `int` | Address width for the feature, weight, and output memories. |
| `NBITS` | `int` | Bit width for a single data element (`logic_vector`). |
| `LATENCY` | `int` | Number of cycles a memory read takes to become valid. |
| `ROM` | `int` | Enables ROM mode on the memory model when set to `1`. |
| `QUANT` | `int` | Number of fractional bits tracked inside the multipliers. |
| `FEAT_INPUT_SIZE` | `int` | Spatial dimension of the padded input tile. |
| `FEAT_OUTPUT_SIZE` | `int` | Spatial dimension of the produced output tile. |
| `N_WINDOW` | `int` | Number of Winograd windows processed per feature map. |
| `N_CHANNEL_IN` | `int` | Count of input feature channels. |
| `N_CHANNEL_OUT` | `int` | Count of output feature channels. |
| `LAST_WINDOW` | `int` | Flag or index describing the last window in the processing sequence. |

Import `pack_def` before other packages so that these parameters are in scope whenever a module needs them.
