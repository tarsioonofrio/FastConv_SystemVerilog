# Carry-save adder library

`csa_lib.sv` provides the reusable adders used to implement the Winograd transforms and accumulation trees. All modules import the shared `pack_def` and `pack_typedef` packages so that the operand width `NBITS` follows the system configuration.

None of the modules expose Verilog parameters—the word width is inherited from the packages—so the documentation below focuses on their ports.

## `FA`
Full adder that reduces three `NBITS`-wide vectors into a sum and carry word.

### Ports
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `a` | Input | `logic [NBITS-1:0]` | First operand. |
| `b` | Input | `logic [NBITS-1:0]` | Second operand. |
| `c` | Input | `logic [NBITS-1:0]` | Third operand. |
| `sum` | Output | `logic [NBITS-1:0]` | Bitwise sum result. |
| `cout` | Output | `logic [NBITS-1:0]` | Carry word shifted left by one bit for ripple addition. |

## `CSA_1`
Wire-through stage used when only one operand needs to propagate.

### Ports
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `op0` | Input | `logic [NBITS-1:0]` | Operand forwarded unchanged. |
| `sum` | Output | `logic [NBITS-1:0]` | Output copy of `op0`. |

## `CSA_2`
Adds two operands with a ripple adder.

### Ports
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `op0` | Input | `logic [NBITS-1:0]` | First addend. |
| `op1` | Input | `logic [NBITS-1:0]` | Second addend. |
| `sum` | Output | `logic [NBITS-1:0]` | Arithmetic sum of the two inputs. |

## `CSA_3`
Three-input carry-save adder followed by ripple addition of the carry vector.

### Ports
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `op0` | Input | `logic [NBITS-1:0]` | First operand. |
| `op1` | Input | `logic [NBITS-1:0]` | Second operand. |
| `op2` | Input | `logic [NBITS-1:0]` | Third operand. |
| `sum` | Output | `logic [NBITS-1:0]` | Reduced result after combining sum and carry words. |

## `CSA_4`
Two-layer tree that compresses four operands.

### Ports
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `op0`, `op1`, `op2`, `op3` | Input | `logic [NBITS-1:0]` each | Four operands entering the CSA tree. |
| `sum` | Output | `logic [NBITS-1:0]` | Resulting sum after carry propagation. |

## `CSA_5`
Three-layer tree for five operands.

### Ports
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `op0`…`op4` | Input | `logic [NBITS-1:0]` each | Five operands scheduled into the CSA tree. |
| `sum` | Output | `logic [NBITS-1:0]` | Reduced sum after combining all terms. |

## `CSA_6`
Balanced tree for six operands.

### Ports
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `op0`…`op5` | Input | `logic [NBITS-1:0]` each | Six operands reduced in three CSA layers. |
| `sum` | Output | `logic [NBITS-1:0]` | Final accumulated result. |

## `CSA_7`
Adds seven operands using four CSA stages.

### Ports
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `op0`…`op6` | Input | `logic [NBITS-1:0]` each | Seven operands grouped across the CSA stages. |
| `sum` | Output | `logic [NBITS-1:0]` | Summed output. |

## `CSA_8`
Adds eight operands using the same structure as `CSA_7` with one extra input group.

### Ports
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `op0`…`op7` | Input | `logic [NBITS-1:0]` each | Eight operands reduced to two words then added. |
| `sum` | Output | `logic [NBITS-1:0]` | Summed output. |

## `CSA_9`
Compresses nine operands by fanning them across three layers before the final ripple add.

### Ports
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `op0`…`op8` | Input | `logic [NBITS-1:0]` each | Nine operands accepted by the tree. |
| `sum` | Output | `logic [NBITS-1:0]` | Summed output. |

## `CSA_12`
Handles twelve operands by grouping them into four CSAs per layer.

### Ports
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `op0`…`op11` | Input | `logic [NBITS-1:0]` each | Twelve operands injected into the tree. |
| `sum` | Output | `logic [NBITS-1:0]` | Summed output. |

## `CSA_16`
Reduces sixteen operands arranged into five CSA layers plus a final ripple add.

### Ports
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `op0`…`op15` | Input | `logic [NBITS-1:0]` each | Sixteen operands, including the passthrough `op0`. |
| `sum` | Output | `logic [NBITS-1:0]` | Summed output. |

## `CSA_18`
Array-based implementation that accepts eighteen operands via an input bus.

### Ports
| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `inputs` | Input | `logic [NBITS-1:0] inputs[18]` | Array with eighteen operands, three per CSA in the first stage. |
| `sum` | Output | `logic [NBITS-1:0]` | Summed output after six CSA layers. |
