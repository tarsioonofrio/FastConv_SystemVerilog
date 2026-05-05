# Renaming Log - `rtl/control`

This document records the naming migration applied to the `rtl/control` block to align it with the project conventions used by other control modules.

## 1. File and Module

| Before                   | After            |
| ------------------------ | ---------------- |
| `conv_controller.sv`     | `control.sv`     |
| `module conv_controller` | `module Control` |

## 2. Top-Level Ports

| Before                 | After          |
| ---------------------- | -------------- |
| `rst`                  | `reset`        |
| `start`                | `p_start`      |
| `end_all_convolutions` | `p_end`        |
| `address`              | `p_input_addr` |
| `Din`                  | `p_input_data` |

## 3. Parameters and Derived Localparams

| Before                     | After                          |
| -------------------------- | ------------------------------ |
| `NB_IFMAP`                 | `N_CHANNEL_IN`                 |
| `NB_OFMAP`                 | `N_CHANNEL_OUT`                |
| `SZ_KERNEL`                | `KERNEL_SIZE`                  |
| `NB_LINES`                 | `FEAT_INPUT_SIZE`              |
| `NB_COLUMNS`               | `FEAT_INPUT_WIDTH`             |
| `ADDR_W`                   | `NADDR`                        |
| `NB_MULTIPS`               | `CONV_MULTIPLY_STEPS`          |
| `CONVOLUTIONS_PER_LINE`    | `WINDOW_COUNT_PER_LINE`        |
| `CONVOLUTIONS_PER_COLUMN`  | `WINDOW_COUNT_PER_COLUMN`      |
| `CONVOLUTIONS_PER_CHANNEL` | `WINDOW_COUNT_PER_CHANNEL`     |
| `BITS_IF`                  | `CHANNEL_INPUT_COUNTER_WIDTH`  |
| `BITS_OF`                  | `CHANNEL_OUTPUT_COUNTER_WIDTH` |
| `BITS_CONV`                | `WINDOW_COUNTER_WIDTH`         |
| `BITS_LINE`                | `WINDOW_ROW_COUNTER_WIDTH`     |
| `BITS_COL`                 | `ADDR_INPUT_COUNTER_WIDTH`     |
| `WEIGHT_W`                 | `WEIGHT_WIDTH`                 |
| `BITSM`                    | `CONV_MULTIPLY_COUNTER_WIDTH`  |

## 4. FSM Type/State Variables

| Before      | After               |
| ----------- | ------------------- |
| `state_r_t` | `type_st_input`     |
| `EA_R`      | `st_input_current`  |
| `PE_R`      | `st_input_next`     |
| `state_c_t` | `type_st_conv`      |
| `EA_C`      | `st_conv_current`   |
| `PE_C`      | `st_conv_next`      |
| `state_w_t` | `type_st_output`    |
| `EA_W`      | `st_output_current` |
| `PE_W`      | `st_output_next`    |

## 5. FSM Enum State Names

| Before        | After          |
| ------------- | -------------- |
| `WAIT_WR`     | `HOLD_WRITE`   |
| `CHANGE_LINE` | `NEXT_ROW`     |
| `R10A`        | `READ_IN_10A`  |
| `R10B`        | `READ_IN_10B`  |
| `R15A`        | `READ_IN_15A`  |
| `R15B`        | `READ_IN_15B`  |
| `R15C`        | `READ_IN_15C`  |
| `XFER`        | `TRANSFER`     |
| `W_CONV`      | `WAIT_CONV`    |
| `T1`          | `TRANSFORM`    |
| `HAD`         | `HADAMARD`     |
| `T2`          | `INVERSE`      |
| `W_WRITE`     | `WAIT_WRITE`   |
| `ZERA9`       | `RESET9`       |
| `READ9`       | `READ_OUTPUT`  |
| `WRITE9`      | `WRITE_OUTPUT` |

## 6. Key Internal Signals and Counters

| Before              | After                      |
| ------------------- | -------------------------- |
| `Vrd`               | `r_feat_input`             |
| `convReg`           | `r_conv_input`             |
| `nextVrd`           | `w_next_feat_input`        |
| `ce`                | `w_feat_input_write_en`    |
| `ce_w`              | `w_weight_write_en`        |
| `weightReg`         | `weight_reg`               |
| `end_conv`          | `w_conv_end`               |
| `contRd`            | `r_output_read_count`      |
| `contWr`            | `r_output_write_count`     |
| `internal_address`  | `r_addr_pointer_input`     |
| `horizontal_step`   | `r_window_row_step`        |
| `weight_address`    | `r_addr_pointer_kernel`    |
| `current_IFchannel` | `r_channel_counter_input`  |
| `current_OFchannel` | `r_channel_counter_output` |
| `cnt_convolutions`  | `r_window_counter_input`   |
| `cnt_horiz_convs`   | `r_window_counter_row`     |
| `base_VRd`          | `w_base_feat_input`        |
| `cnt_col`           | `r_addr_count_input`       |
| `cnt_weight`        | `r_addr_count_kernel`      |
| `weight_done`       | `w_weight_done`            |
| `end_write_results` | `w_write_done`             |
| `cnt_multip`        | `r_conv_multiply_count`    |

## 7. Testbench Naming

| Before     | After       |
| ---------- | ----------- |
| `inputMEM` | `input_mem` |

## 8. Supporting Files Updated

The following files were updated to reflect the new names and references:

- `tb.sv`
- `Makefile`
- `sim.tcl`
- `wave.do`
- `README.md`
- `docs/read-fsm.mmd`
- `docs/conv-fsm.mmd`
- `docs/write-fsm.mmd`

## 9. Explicit Non-Change

As requested, the migration did not rename `last*` naming to `is_last*`.

Examples intentionally kept:

- `last_line`
- `last_input`
- `last_output`
