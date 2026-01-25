# Convolution Core

This folder contains the SystemVerilog source files and testbenches related to the main convolution core of the FastConv architecture. The convolution core performs the Winograd transforms, element-wise multiplications, and inverse transforms that compose the optimized convolution operation.

## `Conv`

The top-level convolution module orchestrates the different processing stages of the Winograd-based algorithm. It imports shared packages such as `pack_def`, `pack_param`, `pack_typedef`, and `pack_mux_mult` which define common dimensions, parameters, and multiplexing index schedules used throughout the design.

This module mainly integrates:

- The Winograd input transform stage
- A bank of multipliers performing element-wise products on transformed tiles
- The Winograd inverse transform stage
- Control and data path muxing logic for channel and window multiplexing

## Parameters

| Parameter | Type    | Description                                                                                                                 |
| --------- | ------- | --------------------------------------------------------------------------------------------------------------------------- |
| Various   | Various | Configuration parameters controlling data widths, vector sizes, channel counts, quantization bitwidths, and pipeline stages |

These parameters enable adapting the convolution core to different Winograd tile sizes, hardware resource tradeoffs, and quantization settings.

## Ports

| Port                   | Direction    | Type                 | Description                                                                  |
| ---------------------- | ------------ | -------------------- | ---------------------------------------------------------------------------- |
| Clock, reset           | Input        | `logic`              | Clock and synchronous reset signals                                          |
| Control signals        | Input/Output | Various              | Start, ready, and handshake signals to coordinate data flow and stalls       |
| Input feature windows  | Input        | Various packed types | Transformed feature maps input to the multipliers                            |
| Weight windows         | Input        | Various packed types | Transformed convolution kernels input to the multipliers                     |
| Output feature windows | Output       | Various packed types | Resulting transformed convolution output windows after the inverse transform |

The interface provides connections for input tiles, weight tiles, and output tiles along with handshaking signals to enable smooth backpressure-aware pipelining.

## `Multip`

A helper submodule performing a single quantized multiply. It receives quantized fixed-point inputs, executes the multiplication, and truncates the product back to the configured bit width (`NBITS`), preserving the required precision and range for efficient convolution implementation.

---

This directory and its contents serve as the core computation engine in the FastConv pipeline. The modular design allows experimentation with different quantization widths, window sizes, and hardware configurations to optimize convolution throughput, area, and power in FPGA or ASIC implementations.

Use these sources as a key reference when exploring Winograd-based convolution hardware accelerators in SystemVerilog.
