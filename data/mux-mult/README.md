# Multiplier index multiplexers

Each subdirectory contains a small package and a `MuxMult` module tailored to a Winograd tile. The package sets the number of multipliers (`NMULT`) and the number of source registers visited per multiplier (`SMULT`).

## `pack_mux_mult`
The package inside every variant exports:
- `NMULT`: number of multipliers instantiated in the convolution core.
- `SMULT`: number of register banks cycled per multiplier.

## `MuxMult`
### Parameters
These modules do not declare parameters; they rely on `NMULT` and `SMULT` from the companion package.

### Ports
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `idx_in` | Input | `logic [$clog2(SMULT)-1:0]` | Encodes the current phase/state of the convolution sweep (degenerates to a constant when `SMULT = 1`). |
| `idx_out` | Output | `logic [$clog2(NMULT*SMULT)-1:0] idx_out[0:NMULT-1]` | Array of register indices, one per multiplier, selecting which feature element participates in the current multiply. |

Consult each subdirectory for the specific `NMULT`/`SMULT` values and case statements that generate the index schedule.
