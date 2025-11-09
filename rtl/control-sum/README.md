# Control Module

This folder contains the SystemVerilog source files and testbenches related to the control logic of the FastConv architecture. The control module orchestrates the data flow and operation sequencing across the convolution datapath.

## `Control`

The main control module imports packages such as `pack_def`, `pack_typedef`, and `pack_param` to define shared widths, type aliases, and configuration parameters used throughout the design.

### Parameters

| Parameter                        | Type    | Description                                                                                                                       |
| -------------------------------- | ------- | --------------------------------------------------------------------------------------------------------------------------------- |
| Various configuration parameters | Various | Parameters defining widths, sizes, and operational modes to customize the controller behavior for different convolution instances |

### Ports

| Port                 | Direction    | Type    | Description                                                                                                                        |
| -------------------- | ------------ | ------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| Clock, reset signals | Input        | `logic` | Standard synchronous inputs for timing and initialization control                                                                  |
| Control signals      | Output       | `logic` | Control flags to enable/disable submodules, start operations, signal completion, and manage data flow across FIFOs and multipliers |
| Status signals       | Input/Output | `logic` | Feedback paths to monitor state machines, data availability, and error conditions                                                  |

The control module typically drives multiple finite state machines (FSMs) to manage the sequencing of operations such as input buffering, transform stages, multiplication scheduling, and output assembly.

### Additional Notes

- The control logic carefully handles synchronization between data arrival, processing stages, and mux selection.
- The design emphasizes modularity to enable reuse of the control subsystem across different FastConv configurations with varying window sizes and channel counts.
- Testbenches located in this folder simulate the control logic with representative stimuli and validate correct operation through assertion checks and waveform inspection.

### Handshake Signals

Two explicit handshakes keep the FSMs aligned with the convolution core:

- **Input → Convolution (`w_conv_ready_for_input`, `w_conv_input_fire`)**: The input FSM only transitions out of `CONV_INPUT` when the core reports it is idle (`w_conv_ready_for_input`). Once idle, the FSM asserts `w_conv_input_fire` for one cycle to transfer the prepared tile, guaranteeing each window is submitted exactly once.
- **Convolution → Output (`w_conv_result_ready`, `r_conv_result_pending`, `w_conv_result_accept`)**: The control logic latches every completed feature map in `r_conv_result_pending` when `w_conv_result_ready = p_conv_end && p_conv_idle`. The output FSM may consume the buffered result only while it sits in `CONV_OUTPUT`, which raises `w_conv_result_accept` and clears the pending flag so no result is written twice.
- **Debug mirrors (`w_handshake_input`, `w_handshake_conv`, `w_handshake_output`)**: These wires mimic the start/ready strobes for waveform visibility and are exposed in `wave.do` for quick inspection when running ModelSim.

Use this module as a reference guide to understand the control flow governing the convolution pipeline in the FastConv SystemVerilog project.

## FSM Overview

Two main FSMs partition the controller responsibilities: the input-side machine coordinates memory fetches and handshake timing, while the output-side machine sequences accumulation and writes. The Mermaid sources live in `docs/*.mmd`, and pre-rendered SVGs (`docs/*.svg`) are embedded below using relative paths so the diagrams display without external services.

### Input FSM

Purpose: orchestrate the bias placeholder, weight streaming, and input window loads. The transitions below reflect the combinational `next_st_input` logic up to `control.sv:280`.

States:

- `I` (`IDLE_INPUT`): wait for `p_start`; counters and base addresses remain cleared.
- `W` (`WEIGHT`): stream kernel weights until the current tile finishes.
- `T` (`CONV_INPUT`): prepare hand-off to the convolution core; may fall through immediately.
- `R` (`READ_INPUT`): refill the sliding window and manage horizontal reuse.

```mermaid
flowchart TB
    I(["IDLE_INPUT"]) --> |"start"| W(["WEIGHT"]) --> R(["READ_INPUT"]) --> C(["CONV_INPUT"]) --> H(["HOLD"])
    H --> R
    R --> |"end channel"| W
```

### Output FSM

Purpose: handshake with the convolution core, optionally read back output tiles, and dispatch writes based on window/channel completion. The diagram is derived from the combinational `next_st_output` logic up to `control.sv:280`.

States:

- `I` (`IDLE_OUTPUT`): await `p_start` before engaging downstream stages.
- `C` (`CONV`): wait for the convolution block to report completion.
- `R` (`READ_OUTPUT`): pull existing output data to seed the accumulator.
- `W` (`WRITE_OUTPUT`): write updated windows back to memory and assess termination.
- `E` (`END_CHANNEL`): bridge between write and readback phases when more accumulation is needed.

```mermaid
flowchart TB
    I(["IDLE_OUTPUT"]) --> C(["CONV"]) --> W(["WRITE_OUTPUT"]) --> E(["END_CHANNEL"]) --> R(["READ_OUTPUT"]) --> C(["CONV"]) --> W(["WRITE_OUTPUT"]) --> E(["END_CHANNEL"])
    W --> C
    W --> R
    W --> E
```
