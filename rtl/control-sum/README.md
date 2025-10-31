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

Use this module as a reference guide to understand the control flow governing the convolution pipeline in the FastConv SystemVerilog project.
