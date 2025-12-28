/*
=============================================================
Module: Control
Description: Controls the input/output dataflow for convolution
             - Reads input/weight RAMs
             - Triggers convolution core
             - Handles output writing
Author: Társio Onofrio
Date: 2025-11-07
=============================================================

=============================================================
Contents

1) Módulo, parâmetros e localparams
2) Tipos (typedef/enum/struct/interface)
3) Portas internas: regs/wires (agrupados por tema)
4) Constantes derivadas (localparams) e funções utilit.
5) FSM INPUT (curr/next + transições)
6) FSM OUTPUT (curr/next + transições)
7) Contadores e geradores de endereço
8) Handshakes / eventos registrados (pulsos)
9) Assertions e monitores de simulação (ifdef SIM)
=============================================================

TODO
Evaluate whether window counters can be removed in favor of direct address comparisons.

*/

module Control
  import pack_def::*;
  import pack_data::*;
  import pack_param::*;
  import pack_typedef::*;
#(
    parameter int NADDR            = 16,  // Address width for the external RAM interfaces
    parameter int NBITS            = 20,  // Bit width for data-path arithmetic
    parameter int LATENCY          = 1,   // Convolution core latency (cycles between request/result)
    parameter int ROM              = 0,   // Enables ROM-backed inputs instead of RAM when set
    parameter int LAST_WINDOW      = 0    // Compile-time override for the last window index
) (
    /*
     -------------------------------------------------------------
     1. Port declarations
     -------------------------------------------------------------
     */
    // Global clock/reset domain
    input  logic clk,                              // System clock driving all sequential logic
    input  logic reset,                            // Asynchronous-active-high reset

    // Top-level sequencing interface
    input  logic p_start,                          // Top-level start pulse for the entire control flow
    output logic p_end,                            // Asserted once every pipeline completes all work

    // Convolution core control handshake
    output logic p_conv_start,                     // Kicks the convolution core with a new tile
    input  logic p_conv_idle,                      // High when the convolution core is idle/ready
    input  logic p_conv_end,                       // High when the convolution core finished processing

    // Convolution core data buses
    output type_input  p_conv_input,               // Input feature vector forwarded to the convolution core
    output type_weight p_conv_weight,              // Weight vector forwarded to the convolution core
    input  type_output p_conv_output,              // Feature map returned by the convolution core

    // Input RAM interface
    output logic p_input_en,                       // Enables a read operation on the input RAM
    output logic[NADDR-1:0] p_input_addr,          // Address issued to the input RAM
    input  logic_vector p_input_data,              // Data returned from the input RAM
    input  logic p_input_valid,                    // Read-valid flag from the input RAM

    // Output RAM interface
    output logic p_output_en,                      // Enables access to the output RAM port
    output logic p_output_wr,                      // Write strobe for the output RAM port
    output logic[NADDR-1:0] p_output_addr,         // Address issued to the output RAM
    output logic_vector p_output_data_write,       // Data driven into the output RAM on writes
    input  logic_vector p_output_data_read,        // Data captured from the output RAM on reads
    input  logic p_output_valid                    // Read-valid flag from the output RAM
);

timeunit 1ns; timeprecision 1ps;

  /*
   -------------------------------------------------------------
   3. Local parameters and derived constants
   -------------------------------------------------------------
   */

  // Structure element counts (2D footprints)
  // Input feature-map elements
  localparam int INPUT_NUM_ELEMS                       = FEAT_INPUT_SIZE * FEAT_INPUT_SIZE;
  // Output feature-map elements
  localparam int OUTPUT_NUM_ELEMS                      = FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE;
  // Elements per sliding window on the input path
  localparam int INPUT_FEATURE_NUM_ELEMS               = C1_SIZE * C2_SIZE;
  // Elements produced per sliding window on the output path
  localparam int OUTPUT_FEATURE_NUM_ELEMS              = A1_SIZE * A2_SIZE;
  // Elements per kernel tile
  localparam int KERNEL_NUM_ELEMS                      = M1_SIZE * M2_SIZE;
  // Number of (input, output) channel combinations
  localparam int TOTAL_NUM_CHANNELS                    = N_CHANNEL_IN * N_CHANNEL_OUT;

  // Window accounting and channel combinations
  // Number of 3x3 output tiles required per axis (ceil to allow padding)
  localparam int WINDOW_COUNT_PER_AXIS                 = (FEAT_OUTPUT_SIZE + A1_SIZE - 1) / A1_SIZE;
  // Windows per spatial plane (row_count * col_count)
  localparam int WINDOWS_PER_PLANE                     = WINDOW_COUNT_PER_AXIS * WINDOW_COUNT_PER_AXIS;
  // Windows per input channel (across all outputs)
  localparam int WINDOWS_PER_INPUT_CHANNEL             = WINDOWS_PER_PLANE * N_CHANNEL_OUT;
  // Windows per output channel (across all inputs)
  localparam int WINDOWS_PER_OUTPUT_CHANNEL            = WINDOWS_PER_PLANE * N_CHANNEL_IN;
  // Sliding windows processed per full execution
  localparam int TOTAL_INPUT_WINDOWS                   = WINDOWS_PER_PLANE * TOTAL_NUM_CHANNELS;

  // Precomputed "last" thresholds used throughout comparisons (-1 already absorbed)
  // Final valid kernel index inside a window
  localparam int LAST_KERNEL_INDEX                     = INPUT_FEATURE_NUM_ELEMS - 1;
  // Final valid window index within a plane
  localparam int LAST_WINDOW_INDEX_PER_PLANE           = WINDOWS_PER_PLANE - 1;
  // Final valid index across every input-window combination
  localparam int LAST_INPUT_WINDOW_INDEX               = WINDOWS_PER_PLANE * TOTAL_NUM_CHANNELS - 1;
  // Final row index for the 2D window grid
  localparam int LAST_WINDOW_ROW_INDEX                 = WINDOW_COUNT_PER_AXIS - 1;
  // Final window index per output channel
  localparam int LAST_OUTPUT_CHANNEL_WINDOW_INDEX      = WINDOWS_PER_OUTPUT_CHANNEL - 1;

  localparam int RAM_LATENCY                           = (LATENCY < 1) ? 1 : LATENCY;
  localparam int RAM_LATENCY_RELOAD                    = (RAM_LATENCY > 1) ? (RAM_LATENCY - 1) : 0;
  localparam int RAM_LATENCY_COUNTER_WIDTH             = (RAM_LATENCY > 1) ? $clog2(RAM_LATENCY + 1) : 1;
  // Latency slack used to time HOLD_OUTPUT
  localparam int CYCLES_HOLD_OUTPUT_RAW                = (OUTPUT_FEATURE_NUM_ELEMS*2 + RAM_LATENCY) - (C1_SIZE * A1_SIZE + 1);
  localparam int CYCLES_HOLD_OUTPUT                    = (CYCLES_HOLD_OUTPUT_RAW > 0) ? CYCLES_HOLD_OUTPUT_RAW : 1;
  // Horizontal-to-vertical wrap deltas that keep pointers in-bounds even with padded tiles
  localparam int INPUT_ROW_WRAP_DELTA                  = A1_SIZE * (FEAT_INPUT_SIZE - WINDOW_COUNT_PER_AXIS + 1);
  localparam int INPUT_CHANNEL_WRAP_DELTA              = INPUT_NUM_ELEMS - (WINDOW_COUNT_PER_AXIS - 1) * A1_SIZE * (FEAT_INPUT_SIZE + 1);
  localparam int OUTPUT_ROW_WRAP_DELTA                 = A1_SIZE * (FEAT_OUTPUT_SIZE - WINDOW_COUNT_PER_AXIS + 1);
  localparam int OUTPUT_CHANNEL_STRIDE                 = FEAT_OUTPUT_SIZE * A1_SIZE * WINDOW_COUNT_PER_AXIS;
  // -- Input path control registers --
  // Base address register for input features
  logic [$clog2(TOTAL_NUM_CHANNELS + KERNEL_NUM_ELEMS * TOTAL_NUM_CHANNELS + N_CHANNEL_IN * INPUT_NUM_ELEMS)-1:0] r_addr_pointer_input;
  // Input feature register read counter
  logic [$clog2(INPUT_FEATURE_NUM_ELEMS)-1:0] r_addr_count_input;
  // Row-aligned window counter for read-side address updates and reuse control
  localparam int WINDOW_AXIS_COUNTER_WIDTH             = $clog2(WINDOW_COUNT_PER_AXIS);
  logic [WINDOW_AXIS_COUNTER_WIDTH:0] r_window_counter_row_input;
  logic [WINDOW_AXIS_COUNTER_WIDTH:0] r_window_counter_col_input;
  // Total window counter for a channel
  logic [$clog2(WINDOWS_PER_PLANE)-1:0] r_window_counter_channel_input;
  // Total window counter for a channel (per-channel accumulation)
  logic [$clog2(WINDOWS_PER_OUTPUT_CHANNEL)-1:0] r_window_counter_all_channel_input;
  // Total window counter for the read path
  logic [$clog2(TOTAL_INPUT_WINDOWS)-1:0] r_window_counter_total_input;

  // -- Weight path bookkeeping --
  // Base address register for weight blocks
  logic [$clog2(TOTAL_NUM_CHANNELS + KERNEL_NUM_ELEMS * TOTAL_NUM_CHANNELS)-1:0] r_addr_pointer_kernel;
  // Weight read counter
  logic [$clog2(KERNEL_NUM_ELEMS)-1:0] r_addr_count_kernel;
  // Bias read counter; bias depth is one so it is unused for now
  logic [$floor($clog2(TOTAL_NUM_CHANNELS) + 0.5)-1:0] r_addr_pointer_bias;
  // Temporary substitute for r_addr_pointer_bias
  // logic [2:0] r_addr_pointer_bias;

  // -- Output path control counters --
  // Output feature register write counter
  logic [$clog2(OUTPUT_FEATURE_NUM_ELEMS)-1:0] r_addr_count_write_out;
  // Output feature register read counter
  logic [$clog2(OUTPUT_FEATURE_NUM_ELEMS)-1:0] r_addr_count_read_out;
  // Output counter
  logic [$clog2(OUTPUT_FEATURE_NUM_ELEMS)-1:0] w_addr_count_out;
  // Output feature write counter (unused/commented)
  // logic [$floor($clog2(N_CHANNEL_OUT) + 0.5)-1:0] r_addr_count_ch_out;
  // Debug monitors for end-of-window predicates (still functions for reuse)
  // logic w_is_last_read_input;
  // logic w_is_last_row_input;
  // logic w_is_last_channel_input;
  // logic w_is_last_all_channel_input;

  // Base address register for output features
  logic [$clog2(N_CHANNEL_OUT * OUTPUT_NUM_ELEMS)-1:0] r_addr_pointer_out;
  // Total window counter for the write path
  logic [$clog2(TOTAL_INPUT_WINDOWS)-1:0] r_window_counter_total_out;
  // Total window counter for all in channel for FSM write
  logic [$clog2(WINDOWS_PER_OUTPUT_CHANNEL)-1:0] r_window_counter_all_channel_out;
  // Total window counter for a channel
  logic [$clog2(WINDOWS_PER_PLANE)-1:0] r_window_counter_channel_out;
  // Row-aligned window counter for write-side address updates
  logic [WINDOW_AXIS_COUNTER_WIDTH:0] r_window_counter_row_out;
  logic [WINDOW_AXIS_COUNTER_WIDTH:0] r_window_counter_col_out;
  // Debug monitors for output-path predicates
  // logic w_is_last_read_out;
  // logic w_is_last_write_out;
  // logic w_is_last_row_out;
  // logic w_is_last_channel_out;
  // logic w_is_last_all_channel_out;

  // Current input feature address
  logic[NADDR-1:0] w_addr_ptr_pin;
  logic[NADDR-1:0] w_addr_ptr_pin_raw;
  logic[NADDR-1:0] w_addr_ptr_pout;
  logic[NADDR-1:0] w_addr_ptr_pout_raw;
  // Column offset inside the current sliding window tile
  logic [$clog2(C1_SIZE):0] r_col_index_input;
  // Row offset inside the current sliding window tile
  logic [$clog2(C1_SIZE):0] r_row_index_input;
  // Accumulated row stride (row_index * FEAT_INPUT_SIZE built with adders)
  logic [NADDR-1:0] r_row_stride_input;
  // Zero-extended column offset used for address math
  logic [NADDR-1:0] w_col_offset_input;
  // Combined row/column offset added to the window base pointer
  logic [NADDR-1:0] w_offset_total_input;
  // Row/column coordinates for padding-aware input fetches
  logic [$clog2(FEAT_INPUT_SIZE + C1_SIZE):0] w_window_base_col_input;
  logic [$clog2(FEAT_INPUT_SIZE + C1_SIZE):0] w_window_base_row_input;
  logic [$clog2(FEAT_INPUT_SIZE + C1_SIZE):0] w_global_col_input;
  logic [$clog2(FEAT_INPUT_SIZE + C1_SIZE):0] w_global_row_input;
  logic w_input_sample_in_bounds;
  logic_vector w_input_data_clamped;
  logic_vector w_output_data_clamped;

  // Column offset inside the current sliding window tile
  logic [$clog2(A1_SIZE):0] r_col_index_output;
  // Row offset inside the current sliding window tile
  logic [$clog2(A1_SIZE):0] r_row_index_output;
  // Accumulated row stride (row_index * FEAT_OUTPUT_SIZE built with adders)
  logic [NADDR-1:0] r_row_stride_output;
  // Zero-extended column offset used for address math
  logic [NADDR-1:0] w_col_offset_output;
  // Combined row/column offset added to the window base pointer
  logic [NADDR-1:0] w_offset_total_output;
  // Row/column coordinates for padding-aware output writes
  logic [$clog2(FEAT_OUTPUT_SIZE + A1_SIZE):0] w_window_base_col_out;
  logic [$clog2(FEAT_OUTPUT_SIZE + A1_SIZE):0] w_window_base_row_out;
  logic [$clog2(FEAT_OUTPUT_SIZE + A1_SIZE):0] w_global_col_out;
  logic [$clog2(FEAT_OUTPUT_SIZE + A1_SIZE):0] w_global_row_out;
  logic w_output_pixel_in_bounds;

  // Write-enable mirror for the output RAM port (helps gate strobes during HOLD states)
  logic w_output_en;

  // Counters that keep track of which input/output channel pair is currently active
  logic [$floor($clog2(TOTAL_NUM_CHANNELS) + 0.5):0] r_channel_counter_input;
  logic [$floor($clog2(TOTAL_NUM_CHANNELS) + 0.5):0] r_channel_counter_out;

  // Legacy bookkeeping hooks for convolution activity (kept for waveform compatibility)
  logic r_conv_end;
  logic r_conv_busy;
  logic r_read_en;
  // Register bank for input features
  type_input  r_feat_input;
  // Register bank for kernel weights
  type_weight r_kernel;
  // Register bank for read output features
  type_output r_feat_output;
  // Register bank for output features from convolution module
  type_output r_conv_output;


  // Difference between accumulation, write, and read phases on the output path
  // (adjusted by the time spent reading inputs)
  logic [$clog2(CYCLES_HOLD_OUTPUT + 1) - 1:0] r_hold_output;
  // High when the convolution core can accept a new input tile
  logic w_conv_ready_for_input;
  // Single-cycle pulse emitted when the input FSM hands data to the convolution core
  logic w_conv_input_fire;
  // Sticky flag capturing an available convolution result until the output FSM consumes it
  logic r_conv_result_pending;
  // Indicates that the convolution core finished and is idle, so results are stable for transfer
  logic w_conv_result_ready;
  // Accept strobe asserted only when the output FSM is in CONV_OUTPUT and a pending result exists
  logic w_conv_result_accept;
  logic [RAM_LATENCY_COUNTER_WIDTH-1:0] r_weight_read_latency;
  logic [RAM_LATENCY_COUNTER_WIDTH-1:0] r_input_read_latency;
  logic [RAM_LATENCY_COUNTER_WIDTH-1:0] r_output_read_latency;
  logic w_weight_data_ready;
  logic w_input_data_ready;
  logic w_output_data_ready;
  logic w_weight_read_pending;
  logic w_input_read_pending;
  logic w_output_read_pending;

  // High-level debug aliases for documentation/waveforms
  logic w_read_fin;
  logic w_conv_start_dbg;
  logic w_conv_end_dbg;
  logic w_idle_conv_dbg;
  logic w_read_ofmap;
  logic w_write_ofmap;

  typedef enum {
    IDLE_INPUT,
    BIAS,
    WEIGHT,
    CONV_INPUT,
    READ_INPUT,
    HOLD_OUTPUT,
    HOLD_LAST_CONV,
    END_INPUT
   } state_input_type;

  typedef enum {
    IDLE_OUTPUT,
    READ_OUTPUT,
    CONV_OUTPUT,
    WRITE_OUTPUT,
    END_CHANNEL,
    HOLD_WEIGHT
  } state_output_type;

  state_input_type current_st_input, next_st_input;
  state_output_type current_st_output, next_st_output;




  // Sequential logic that advances the state machines
  always_ff @(posedge clk or posedge reset) begin: FSM_BLOCK
    if (reset) begin
      current_st_input  <= IDLE_INPUT;
      current_st_output <= IDLE_OUTPUT;
    end else begin
      current_st_input  <= next_st_input;
      current_st_output <= next_st_output;
    end
  end


  /*
   -------------------------------------------------------------
   4. FSM: Input path
   -------------------------------------------------------------
   */

  // Combinational logic for the input (read) state machine
  // NEXT_ST_INPUT_BLOCK: derives the next input FSM state using the f_is_last_* flags so the read
  // side stays coherent with OUTPUT_CTRL_BLOCK and the convolution handshakes.
  always_comb begin: NEXT_ST_INPUT_BLOCK
    next_st_input = current_st_input;
    unique case (current_st_input)
      // IDLE_CONTROL
      // Waits for start to begin reading weights and then input data; bias handling is currently disabled
      IDLE_INPUT: begin
        if (p_start)
          next_st_input = WEIGHT;
          // next_st_input = BIAS;
      end
      BIAS: begin
        next_st_input = WEIGHT;
      end
      // Waits for the weight fetch covering the active input/output channel pair before moving on to input data
      WEIGHT: begin
        if ((r_addr_count_kernel == (KERNEL_NUM_ELEMS - 1)) && !w_weight_read_pending)
          next_st_input = READ_INPUT;
      end
      READ_INPUT: begin
        if (f_is_last_read_input() && !w_input_read_pending)
          next_st_input = CONV_INPUT;
      end
      CONV_INPUT: begin
        if (!w_conv_ready_for_input) begin
          next_st_input = CONV_INPUT;
        end else begin
            // When all windows across input and output channels have been read, finish input
          if (f_is_last_row_input() && (r_window_counter_total_input >= LAST_INPUT_WINDOW_INDEX))
            next_st_input = END_INPUT;
          else
          // When all output-channel windows are complete, load bias (disabled for now)
          // if (r_window_counter_total_input == WINDOWS_PER_INPUT_CHANNEL)
          //  next_st_input = BIAS;
          // else
          // When a full set of windows for an input channel is done, reload weights
          if (f_is_last_row_input() && f_is_last_channel_input())
            next_st_input = HOLD_LAST_CONV;
          else if (f_is_last_row_input())
            next_st_input = READ_INPUT;
          else if (r_channel_counter_out > 0)
            next_st_input = HOLD_OUTPUT;
          else
            next_st_input = READ_INPUT;
        end
      end
      HOLD_OUTPUT: begin
        if (r_hold_output == (CYCLES_HOLD_OUTPUT - 1))
          next_st_input = READ_INPUT;
      end
      HOLD_LAST_CONV: begin
        if (p_conv_idle)
          next_st_input = WEIGHT;
      end
      END_INPUT: begin
        // next_st_input = IDLE_INPUT;
      end
    endcase
  end


  /*
   -------------------------------------------------------------
   5. FSM: Output path
   -------------------------------------------------------------
   */

  // Combinational logic for the output (write) state machine
  // NEXT_ST_OUTPUT_BLOCK: coordinates the write FSM with the status coming from both the input FSM
  // and the convolution result handshakes.
  always_comb begin: NEXT_ST_OUTPUT_BLOCK
    next_st_output = current_st_output;
    unique case (current_st_output)
      IDLE_OUTPUT: begin
        if (p_start)
          next_st_output = CONV_OUTPUT;
      end
      READ_OUTPUT: begin
        if (f_is_last_read_out() && !w_output_read_pending)
          next_st_output = CONV_OUTPUT;
      end
      // Waits for the convolution-complete signal
      CONV_OUTPUT: begin
        if (w_conv_result_ready && (r_channel_counter_out == 0))
          next_st_output = WRITE_OUTPUT;
        else if (w_conv_result_ready && (r_channel_counter_out > 0))
          next_st_output = WRITE_OUTPUT;
      end
      // Waits for the output data write to memory to complete and then returns to idle
      WRITE_OUTPUT: begin
        // TODO
        // Evaluate whether this if/else structure should be changed to an if-else tree
        if (f_is_last_write_out() && !f_is_last_channel_out() && (r_channel_counter_out == 0))
          next_st_output = CONV_OUTPUT;
        else if (f_is_last_write_out() && !f_is_last_channel_out() && (r_channel_counter_out > 0))
          next_st_output = READ_OUTPUT;
        else if (f_is_last_write_out() && f_is_last_channel_out())
          next_st_output = END_CHANNEL;
        else if (f_is_last_write_out() && (r_window_counter_total_out == LAST_INPUT_WINDOW_INDEX))
          next_st_output = IDLE_OUTPUT;
      end
      END_CHANNEL: begin
        if (next_st_input == CONV_INPUT)
          next_st_output = READ_OUTPUT;
        else
        next_st_output = HOLD_WEIGHT;
      end
      HOLD_WEIGHT: begin
        if (next_st_input == READ_INPUT)
          next_st_output = READ_OUTPUT;
      end
    endcase
  end

  /*
   -------------------------------------------------------------
   6. Handshake coordination
   -------------------------------------------------------------
   */

   /*
   Sequencers below keep track of which side currently owns the convolution
   core: `r_conv_busy` blocks new requests until the core reports idle, while
   `r_conv_result_pending` guarantees each produced feature map is accepted
   exactly once by the output FSM.
   */
  always_ff @(posedge clk) begin: CONV_BUSY_BLOCK
    if (reset) begin
      r_conv_busy <= 1'b0;
    end else begin
      if (p_conv_end)
        r_conv_busy <= 1'b0;
      if (w_conv_input_fire)
        r_conv_busy <= 1'b1;
    end
  end

  // Handshake #1: input FSM -> convolution core
  assign w_conv_ready_for_input = p_conv_idle && (!r_conv_busy || p_conv_end);
  assign w_conv_input_fire      = (current_st_input == CONV_INPUT) && w_conv_ready_for_input;

  /*
   Result handshake mirrors the input-side sequencer: the moment the convolution
   core asserts `p_conv_end`, the result stays marked as pending until the output
   FSM consumes it inside CONV_OUTPUT, preventing the same feature map from being
   accumulated twice.
   */
  always_ff @(posedge clk) begin: CONV_RESULT_PENDING_BLOCK
    if (reset) begin
      r_conv_result_pending <= 1'b0;
    end else begin
      if (w_conv_result_ready)
        r_conv_result_pending <= 1'b1;
      else if (w_conv_result_accept)
        r_conv_result_pending <= 1'b0;
    end
  end

  // Handshake #2: convolution core -> output FSM
  assign w_conv_result_ready    = p_conv_end;
  assign w_conv_result_accept   = (current_st_output == CONV_OUTPUT) && r_conv_result_pending;

  // Latency trackers: keep read side counters aligned with multi-cycle RAMs so the FSMs do not
  // advance until every outstanding request returned a valid sample.
  always_ff @(posedge clk or posedge reset) begin: RAM_LATENCY_TRACKING_BLOCK
    if (reset) begin
      r_weight_read_latency <= RAM_LATENCY_RELOAD;
      r_input_read_latency  <= RAM_LATENCY_RELOAD;
      r_output_read_latency <= RAM_LATENCY_RELOAD;
    end else begin
      // Weight stream latency
      if (current_st_input != WEIGHT) begin
        r_weight_read_latency <= RAM_LATENCY_RELOAD;
      end else if (r_weight_read_latency != 0) begin
        r_weight_read_latency <= r_weight_read_latency - 1;
      end else if (p_input_valid && (r_addr_count_kernel < (KERNEL_NUM_ELEMS - 1))) begin
        r_weight_read_latency <= RAM_LATENCY_RELOAD;
      end

      // Input feature latency
      if (current_st_input != READ_INPUT) begin
        r_input_read_latency <= RAM_LATENCY_RELOAD;
      end else if (r_input_read_latency != 0) begin
        r_input_read_latency <= r_input_read_latency - 1;
      end else if (p_input_valid && (r_addr_count_input < (INPUT_FEATURE_NUM_ELEMS - 1))) begin
        r_input_read_latency <= RAM_LATENCY_RELOAD;
      end

      // Output readback latency
      if (current_st_output != READ_OUTPUT) begin
        r_output_read_latency <= RAM_LATENCY_RELOAD;
      end else if (r_output_read_latency != 0) begin
        r_output_read_latency <= r_output_read_latency - 1;
      end else if (p_output_valid && (r_addr_count_read_out < (OUTPUT_FEATURE_NUM_ELEMS - 1))) begin
        r_output_read_latency <= RAM_LATENCY_RELOAD;
      end
    end
  end

  assign w_weight_data_ready   = (current_st_input == WEIGHT)      && (r_weight_read_latency == 0) && p_input_valid;
  assign w_input_data_ready    = (current_st_input == READ_INPUT)  && (r_input_read_latency  == 0) && p_input_valid;
  assign w_output_data_ready   = (current_st_output == READ_OUTPUT) && (r_output_read_latency == 0) && p_output_valid;
  assign w_weight_read_pending = (current_st_input == WEIGHT)     && (r_weight_read_latency != 0);
  assign w_input_read_pending  = (current_st_input == READ_INPUT) && (r_input_read_latency  != 0);
  assign w_output_read_pending = (current_st_output == READ_OUTPUT) && (r_output_read_latency != 0);


  /*
   -------------------------------------------------------------
   7. Data Input path
   -------------------------------------------------------------
   */

  // reset_input_ctrl_regs: clears all control-side registers so INPUT_CTRL_BLOCK starts in sync with
  // the FSM state transitions and handshake logic shared with the convolution core.
  task automatic reset_input_ctrl_regs();
    r_read_en                      <= 1'b0;
    r_addr_pointer_bias            <= '0;
    r_addr_pointer_kernel          <= N_CHANNEL_OUT;
    r_addr_pointer_input           <= TOTAL_NUM_CHANNELS + KERNEL_NUM_ELEMS * TOTAL_NUM_CHANNELS;
    r_addr_count_kernel            <= '0;
    r_addr_count_input             <= '0;
    r_channel_counter_input        <= '0;
    r_hold_output                  <= '0;
    r_window_counter_total_input   <= '0;
    r_window_counter_channel_input <= '0;
    r_window_counter_col_input     <= '0;
    r_window_counter_row_input     <= '0;
    r_window_counter_all_channel_input <= '0;
    r_col_index_input              <= '0;
    r_row_index_input              <= '0;
    r_row_stride_input             <= '0;
  endtask

  // load_input_idle_state: reapplies the canonical IDLE initialization so the input FSM realigns
  // with OUTPUT_CTRL_BLOCK when the pipeline drains and waits for new work.
  task automatic load_input_idle_state();
    r_read_en                      <= 1'b0;
    r_addr_pointer_bias            <= '0;
    r_addr_pointer_kernel          <= TOTAL_NUM_CHANNELS;
    r_addr_pointer_input           <= TOTAL_NUM_CHANNELS + KERNEL_NUM_ELEMS * TOTAL_NUM_CHANNELS;
    r_addr_count_kernel            <= '0;
    r_addr_count_input             <= '0;
    r_channel_counter_input        <= '0;
    r_hold_output                  <= '0;
    r_window_counter_total_input   <= '0;
    r_window_counter_channel_input <= '0;
    r_window_counter_col_input     <= '0;
    r_window_counter_row_input     <= '0;
    r_window_counter_all_channel_input <= '0;
    r_col_index_input              <= '0;
    r_row_index_input              <= '0;
    r_row_stride_input             <= '0;
  endtask

  // reset_input_buffers: wipes the local kernel/input tiles to prevent stale data from being handed
  // to P_CONV_BUS_BLOCK after resets or between sequences.
  task automatic reset_input_buffers();
    r_kernel     <= '{default: '0};
    r_feat_input <= '{default: '0};
  endtask

  // INPUT_CTRL_BLOCK: updates counters and pointers for the input FSM and drives the handshakes the
  // OUTPUT_CTRL_BLOCK depends on when scheduling writes.
  always_ff @(posedge clk) begin: INPUT_CTRL_BLOCK
    if (reset) begin
      reset_input_ctrl_regs();
    end else begin
      unique case (current_st_input)
        default: begin end
        IDLE_INPUT: begin
          // Reset control counters/pointers so the next activation starts from the canonical base.
          load_input_idle_state();
        end
        BIAS: begin
          // Sequentially advances through the bias region before weights/inputs are fetched.
          r_addr_pointer_bias <= r_addr_pointer_bias + 1;
        end
        WEIGHT: begin
          // Streams kernel coefficients into r_kernel while priming the input counter.
          r_read_en        <= 1'b1;
          r_addr_count_input <= 0;
          if (w_weight_data_ready) begin
            r_addr_pointer_kernel <= r_addr_pointer_kernel + 1;
            r_addr_count_kernel   <= r_addr_count_kernel + 1;
          end
        end
        CONV_INPUT: begin
          // On each tile handoff, bump window counters and reposition pointers for the next window.
          if (w_conv_input_fire) begin
            r_window_counter_total_input <= r_window_counter_total_input + 1;
            r_row_index_input            <= '0;
            r_row_stride_input           <= '0;

            if (f_is_last_row_input()) begin
              r_addr_count_input <= 0;
              r_col_index_input  <= 0;
            end else begin
              r_addr_count_input <= C1_SIZE * (C1_SIZE - A1_SIZE);
              r_col_index_input  <= C1_SIZE - A1_SIZE;
            end
            // r_window_counter_row_input
            if (f_is_last_row_input()) begin
              r_window_counter_row_input <= 0;
            end else
              r_window_counter_row_input <= r_window_counter_row_input + 1;
            // r_window_counter_col_input
            if (f_is_last_row_input() && f_is_last_channel_input())
              r_window_counter_col_input <= 0;
            else if (f_is_last_row_input() && (r_window_counter_col_input >= LAST_WINDOW_ROW_INDEX))
              r_window_counter_col_input <= 0;
            else if (f_is_last_row_input())
              r_window_counter_col_input <= r_window_counter_col_input + 1;
            // r_window_counter_channel_input
            if (f_is_last_channel_input())
              r_window_counter_channel_input <= 0;
            else
              r_window_counter_channel_input <= r_window_counter_channel_input + 1;
            // r_window_counter_all_channel_input
            if (f_is_last_all_channel_input())
              r_window_counter_all_channel_input <= 0;
            else
              r_window_counter_all_channel_input <= r_window_counter_all_channel_input + 1;
            // r_addr_pointer_input
            if (f_is_last_row_input() && f_is_last_all_channel_input())
              r_addr_pointer_input <= TOTAL_NUM_CHANNELS + KERNEL_NUM_ELEMS * TOTAL_NUM_CHANNELS;
            else if (f_is_last_row_input() && !f_is_last_channel_input())
              r_addr_pointer_input <= r_addr_pointer_input + INPUT_ROW_WRAP_DELTA;
            else if (f_is_last_row_input() && f_is_last_channel_input())
              r_addr_pointer_input <= r_addr_pointer_input + INPUT_CHANNEL_WRAP_DELTA;
            else
              r_addr_pointer_input <= r_addr_pointer_input + A1_SIZE;
          end
        end
        READ_INPUT: begin
          // Issues RAM reads and walks the row/column indices while filling r_feat_input.
          r_read_en          <= 1'b1;
          r_addr_count_kernel <= 0;
          if (w_input_data_ready && (r_addr_count_input < C1_SIZE * C1_SIZE)) begin
            r_addr_count_input <= r_addr_count_input + 1;
            if (r_row_index_input == (C1_SIZE - 1)) begin
              r_row_index_input  <= '0;
              r_row_stride_input <= '0;
              if (r_col_index_input == (C1_SIZE - 1))
                r_col_index_input <= '0;
              else
                r_col_index_input <= r_col_index_input + 1;
            end else begin
              r_row_index_input  <= r_row_index_input + 1;
              r_row_stride_input <= r_row_stride_input + FEAT_INPUT_SIZE;
            end
          end
        end
        HOLD_OUTPUT: begin
          // Inserts a small delay to let OUTPUT_CTRL_BLOCK consume pending windows.
          if (r_hold_output == (CYCLES_HOLD_OUTPUT - 1))
            r_hold_output <= 0;
          else
            r_hold_output <= r_hold_output + 1;
        end
        HOLD_LAST_CONV: begin
          // Waits for the convolution core to go idle before rotating to the next input channel.
          if (p_conv_idle) begin
            if (r_channel_counter_input >= N_CHANNEL_IN - 1)
              r_channel_counter_input <= 0;
            else
              r_channel_counter_input <= r_channel_counter_input + 1;
          end
        end
      endcase
    end
  end

  // INPUT_BUFFER_BLOCK: owns the actual feature/weight memories, working in tandem with
  // INPUT_CTRL_BLOCK so the data presented on p_conv_input/p_conv_weight matches the counters.
  always_ff @(posedge clk) begin: INPUT_BUFFER_BLOCK
    if (reset) begin
      reset_input_buffers();
    end else begin
      unique case (current_st_input)
        default: begin end
        IDLE_INPUT: begin
          // Flush buffer content during idle to avoid leaking stale data into the next run.
          reset_input_buffers();
        end
        WEIGHT: begin
          // Capture each weight word as it returns from the RAM interface.
          if (w_weight_data_ready)
            r_kernel[r_addr_count_kernel] <= p_input_data;
        end
        READ_INPUT: begin
          // Store incoming feature samples using the c_index indirection for stride ordering.
          if (w_input_data_ready && (r_addr_count_input < C1_SIZE * C1_SIZE))
            r_feat_input[c_index[r_addr_count_input]] <= w_input_data_clamped;
        end
        CONV_INPUT: begin
          // When reusing overlap columns, shift the buffer contents left to free room for new data.
          if (w_conv_input_fire && !f_is_last_row_input()) begin
            for (int row = 0; row < C1_SIZE; row++) begin
              for (int col = 0; col < (C1_SIZE - A1_SIZE); col++) begin
                r_feat_input[row * C1_SIZE + col] <= r_feat_input[row * C1_SIZE + col + A1_SIZE];
              end
            end
          end
        end
      endcase
    end
  end

  // Input address generation: compute `base + row*FEAT_INPUT_SIZE + col`
  // via the cached stride and offset terms to keep the adder tree shallow.
  assign w_col_offset_input   = r_col_index_input;
  assign w_offset_total_input = r_row_stride_input + w_col_offset_input;
  assign w_addr_ptr_pin_raw   = r_addr_pointer_input + w_offset_total_input;
  assign w_addr_ptr_pin       = w_input_sample_in_bounds ? w_addr_ptr_pin_raw : r_addr_pointer_input;
  assign w_window_base_col_input = r_window_counter_row_input * A1_SIZE;
  assign w_window_base_row_input = r_window_counter_col_input * A1_SIZE;
  assign w_global_col_input      = w_window_base_col_input + r_col_index_input;
  assign w_global_row_input      = w_window_base_row_input + r_row_index_input;
  assign w_input_sample_in_bounds = (w_global_col_input < FEAT_INPUT_SIZE) && (w_global_row_input < FEAT_INPUT_SIZE);
  assign w_input_data_clamped    = w_input_sample_in_bounds ? p_input_data : '0;

  /*
   -------------------------------------------------------------
   7. Data Output path
   -------------------------------------------------------------
   */

  // reset_output_ctrl_regs: clears write-side counters/pointers so OUTPUT_CTRL_BLOCK can
  // re-synchronize with the input FSM after reset or channel rollovers.
  task automatic reset_output_ctrl_regs();
    r_channel_counter_out         <= '0;
    r_addr_pointer_out            <= '0;
    r_addr_count_read_out         <= '0;
    r_addr_count_write_out        <= '0;
    r_window_counter_total_out    <= '0;
    r_window_counter_all_channel_out <= '0;
    r_window_counter_channel_out  <= '0;
    r_window_counter_row_out      <= '0;
    r_window_counter_col_out      <= '0;
  endtask

  // reset_output_data_regs: flushes accumulation buffers that feed p_output_data_write to ensure
  // OUTPUT_DATA_BLOCK never reuses old sums once the FSM restarts.
  task automatic reset_output_data_regs();
    r_conv_output <= '{default: '0};
    r_feat_output <= '{default: '0};
  endtask

  // OUTPUT_CTRL_BLOCK: sequences the write-side counters/pointers and mirrors INPUT_CTRL_BLOCK to
  // guarantee window indices remain aligned when p_end is asserted.
  always_ff @(posedge clk) begin: OUTPUT_CTRL_BLOCK
    if (reset) begin
      reset_output_ctrl_regs();
    end else begin
      unique case (current_st_output)
        default: begin end
        READ_OUTPUT: begin
          // Latch partial sums read from the output RAM while tracking how many samples arrived.
          if (w_output_data_ready && (r_addr_count_read_out < OUTPUT_FEATURE_NUM_ELEMS))
            r_addr_count_read_out <= r_addr_count_read_out + 1;
        end
        CONV_OUTPUT: begin
          // Waits for the convolution result to arrive and clears counters ahead of WRITE_OUTPUT.
          r_addr_count_read_out  <= 0;
          r_addr_count_write_out <= 0;
        end
        WRITE_OUTPUT: begin
          // Emits accumulated results to RAM and updates window/channel counters accordingly.
          r_addr_count_write_out <= r_addr_count_write_out + 1;
          // r_window_counter_total_out
          if (f_is_last_write_out())
            r_window_counter_total_out <= r_window_counter_total_out + 1;
          // r_window_counter_row_out
          if (f_is_last_write_out() && f_is_last_row_out()) begin
            r_window_counter_row_out <= 0;
          end else if (f_is_last_write_out() && !f_is_last_row_out())
            r_window_counter_row_out <= r_window_counter_row_out + 1;
          // r_window_counter_col_out
          if (f_is_last_write_out() && f_is_last_row_out() && f_is_last_channel_out())
            r_window_counter_col_out <= 0;
          else if (f_is_last_write_out() && f_is_last_row_out() && (r_window_counter_col_out >= LAST_WINDOW_ROW_INDEX))
            r_window_counter_col_out <= 0;
          else if (f_is_last_write_out() && f_is_last_row_out())
            r_window_counter_col_out <= r_window_counter_col_out + 1;
          // r_window_counter_channel_out
          if (f_is_last_write_out() && !f_is_last_channel_out())
            r_window_counter_channel_out <= r_window_counter_channel_out + 1;
          // r_window_counter_all_channel_out
          if (f_is_last_write_out() && !f_is_last_all_channel_out())
            r_window_counter_all_channel_out <= r_window_counter_all_channel_out + 1;
          // r_addr_pointer_out
          if (f_is_last_write_out() && f_is_last_row_out())
            r_addr_pointer_out <= r_addr_pointer_out + OUTPUT_ROW_WRAP_DELTA;
          else if (f_is_last_write_out() && !f_is_last_row_out())
            r_addr_pointer_out <= r_addr_pointer_out + A1_SIZE;
        end
        END_CHANNEL: begin
          // Handles inter-channel bookkeeping, rewinding pointers or advancing to the next channel.
          r_window_counter_row_out     <= 0;
          r_window_counter_col_out     <= 0;
          r_window_counter_channel_out <= 0;
          if (f_is_last_all_channel_out())
            r_window_counter_all_channel_out <= 0;
          if (r_channel_counter_out >= N_CHANNEL_IN - 1) begin
            r_channel_counter_out <= 0;
          end else begin
            r_channel_counter_out <= r_channel_counter_out + 1;
            r_addr_pointer_out    <= r_addr_pointer_out - OUTPUT_CHANNEL_STRIDE;
          end
        end
      endcase
    end
  end

  // OUTPUT_DATA_BLOCK: captures convolution results and RAM readbacks so OUTPUT_CTRL_BLOCK can emit
  // writes without re-reading memories.
  always_ff @(posedge clk) begin: OUTPUT_DATA_BLOCK
    if (reset) begin
      reset_output_data_regs();
    end else begin
      unique case (current_st_output)
        default: begin end
        IDLE_OUTPUT: begin end
        READ_OUTPUT: begin
          // Capture data from the output RAM into r_feat_output for later accumulation.
          if (w_output_data_ready && (r_addr_count_read_out < OUTPUT_FEATURE_NUM_ELEMS))
            r_feat_output[r_addr_count_read_out] <= w_output_data_clamped;
        end
        CONV_OUTPUT: begin
          // Store the freshly computed convolution result so WRITE_OUTPUT can sum with RAM data.
          if (w_conv_result_ready)
            r_conv_output <= p_conv_output;
        end
      endcase
    end
  end

  // OUTPUT_TILE_INDEX_BLOCK: derives the per-pixel row/column offsets that both OUTPUT_CTRL_BLOCK
  // and P_OUTPUT_CTRL_BLOCK use to decide when writes fall inside the valid feature map.
  always_ff @(posedge clk) begin: OUTPUT_TILE_INDEX_BLOCK
      if (reset) begin
        r_col_index_output <= '0;
        r_row_index_output <= '0;
        r_row_stride_output <= '0;
      end else begin
        if ((current_st_output == WRITE_OUTPUT) || ((current_st_output == READ_OUTPUT) && w_output_data_ready)) begin
          // Row-major traversal for the output feature tile mirrors the input logic:
          // column increments happen every cycle, while row/stride updates only occur
          // when the column reaches the end of the kernel footprint.
          if (r_col_index_output == (A1_SIZE - 1)) begin
            r_col_index_output <= '0;
            if (r_row_index_output == (A1_SIZE - 1)) begin
              r_row_index_output <= '0;
              r_row_stride_output <= '0;
            end else begin
              r_row_index_output <= r_row_index_output + 1;
              r_row_stride_output <= r_row_stride_output + FEAT_OUTPUT_SIZE;
            end
          end else begin
            r_col_index_output <= r_col_index_output + 1;
          end
        end
      end
  end

  // Output address generation mirrors the input path using
  // `base + row*FEAT_OUTPUT_SIZE + col` for RAM writes.
  assign w_col_offset_output   = r_col_index_output;
  assign w_offset_total_output = r_row_stride_output + w_col_offset_output;
  assign w_addr_ptr_pout_raw   = r_addr_pointer_out + w_offset_total_output;
  assign w_addr_ptr_pout       = w_output_pixel_in_bounds ? w_addr_ptr_pout_raw : r_addr_pointer_out;
  assign w_window_base_col_out = r_window_counter_row_out * A1_SIZE;
  assign w_window_base_row_out = r_window_counter_col_out * A1_SIZE;
  assign w_global_col_out      = w_window_base_col_out + r_col_index_output;
  assign w_global_row_out      = w_window_base_row_out + r_row_index_output;
  assign w_output_pixel_in_bounds = (w_global_col_out < FEAT_OUTPUT_SIZE) && (w_global_row_out < FEAT_OUTPUT_SIZE);
  assign w_output_data_clamped = w_output_pixel_in_bounds ? p_output_data_read : '0;


  /*
   -------------------------------------------------------------
   8. Output port path
   -------------------------------------------------------------
   */


  // P_END_BLOCK: raises p_end once OUTPUT_CTRL_BLOCK reports every window emitted, signaling back to
  // upstream sequencing logic that INPUT_CTRL_BLOCK can idle.
  always_comb begin: P_END_BLOCK
    p_end = (r_window_counter_total_out >= TOTAL_INPUT_WINDOWS) ? 1'b1 : 1'b0;
  end

  // P_CONV_BUS_BLOCK: ties INPUT_BUFFER_BLOCK contents to the convolution core, relying on the
  // handshake logic declared earlier to fire requests safely.
  always_comb begin: P_CONV_BUS_BLOCK
    p_conv_input  = r_feat_input;
    p_conv_weight = r_kernel;
    // p_conv_start  = w_handshake_input;
    p_conv_start      = w_conv_input_fire;
    w_conv_start_dbg  = w_conv_input_fire;
    w_conv_end_dbg    = p_conv_end;
    w_idle_conv_dbg   = p_conv_idle;
  end

  // P_INPUT_MUX_BLOCK: selects the RAM address/enables according to the input FSM, keeping the RAM
  // view consistent with what INPUT_CTRL_BLOCK is expecting to capture.
  always_comb begin: P_INPUT_MUX_BLOCK
    unique case (current_st_input)
      BIAS: begin
        p_input_addr = r_addr_pointer_bias;
        p_input_en = 1'b0;
      end
      WEIGHT: begin
        p_input_addr = r_addr_pointer_kernel;
        p_input_en = r_read_en;
      end
      READ_INPUT: begin
        p_input_addr = w_addr_ptr_pin;
        p_input_en = r_read_en;
      end
      default: begin
        p_input_addr = 0;
        p_input_en = 1'b0;
      end
    endcase
    // Alias for input feature-map reads (FIN)
    w_read_fin = p_input_en;
  end

  // P_OUTPUT_CTRL_BLOCK: exposes OUTPUT_CTRL_BLOCK decisions to the RAM port, toggling enables and
  // write strobes in lockstep with the internal window counters.
  always_comb begin: P_OUTPUT_CTRL_BLOCK
    unique case (current_st_output)
      // Waits for the convolution-complete signal
      default: begin
        p_output_en = 1'b0;
        p_output_wr = 1'b0;
      end
      READ_OUTPUT: begin
        p_output_en = 1'b1;
        p_output_wr = 1'b0;
      end
      // Waits for the output data write to memory to complete and then returns to idle
      WRITE_OUTPUT: begin
        p_output_en = 1'b1;
        p_output_wr = w_output_pixel_in_bounds;
      end
    endcase
    // Aliases for OFMAP access
    w_read_ofmap  = (current_st_output == READ_OUTPUT)  && p_output_en;
    w_write_ofmap = (current_st_output == WRITE_OUTPUT) && p_output_en && p_output_wr;
  end

  assign p_output_addr = w_addr_ptr_pout;

  // P_OUTPUT_DATA_WRITE_BLOCK: feeds the output RAM with the accumulated sum of the captured
  // convolution result plus any existing feature data, aligned with OUTPUT_CTRL_BLOCK counters.
  always_comb begin: P_OUTPUT_DATA_WRITE_BLOCK
    p_output_data_write = r_conv_output[r_addr_count_write_out] + r_feat_output[r_addr_count_write_out];
  end


  // Debug monitor wires so the f_is_last_* predicates remain visible in simulation
  // always_comb begin: F_END_MONITOR_BLOCK
  //   w_is_last_read_input         = f_is_last_read_input();
  //   w_is_last_row_input   = f_is_last_row_input();
  //   w_is_last_channel_input      = f_is_last_channel_input();
  //   w_is_last_all_channel_input  = f_is_last_all_channel_input();
  //   w_is_last_read_out        = f_is_last_read_out();
  //   w_is_last_write_out       = f_is_last_write_out();
  //   w_is_last_row_out  = f_is_last_row_out();
  //   w_is_last_channel_out     = f_is_last_channel_out();
  //   w_is_last_all_channel_out = f_is_last_all_channel_out();
  // end

  /*
   -------------------------------------------------------------
   9. Utility functions
   -------------------------------------------------------------
   */
  // Helper predicates replacing the former w_is_last_* wires
  // f_is_last_read_input: signals when READ_INPUT captured the final sample of the current kernel so
  // INPUT_CTRL_BLOCK can transition to CONV_INPUT in sync with the convolution core.
  function automatic logic f_is_last_read_input();
    // Static variable preserves the last computed result for waveform visibility
    static logic w_is_last_read_input;
    w_is_last_read_input = (r_addr_count_input == LAST_KERNEL_INDEX);
    f_is_last_read_input = w_is_last_read_input;
  endfunction

  // f_is_last_row_input: asserts at the last horizontal window for an input row, informing both
  // INPUT_CTRL_BLOCK and the address generator when to wrap columns.
  function automatic logic f_is_last_row_input();
    // Static variable preserves the last computed result for waveform visibility
    static logic w_is_last_row_input;
    w_is_last_row_input = (r_window_counter_row_input >= LAST_WINDOW_ROW_INDEX);
    f_is_last_row_input = w_is_last_row_input;
  endfunction

  // f_is_last_channel_input: indicates the final window inside the current output channel so
  // INPUT_CTRL_BLOCK knows when to reload weights.
  function automatic logic f_is_last_channel_input();
    // Static variable preserves the last computed result for waveform visibility
    static logic w_is_last_channel_input;
    w_is_last_channel_input = (r_window_counter_channel_input >= LAST_WINDOW_INDEX_PER_PLANE);
    f_is_last_channel_input = w_is_last_channel_input;
  endfunction

  // f_is_last_all_channel_input: pulses when every input/output channel pairing is done, allowing
  // the input FSM to reset base pointers before OUTPUT_CTRL_BLOCK starts writing.
  function automatic logic f_is_last_all_channel_input();
    // Static variable preserves the last computed result for waveform visibility
    static logic w_is_last_all_channel_input;
    w_is_last_all_channel_input = (r_window_counter_all_channel_input >= LAST_OUTPUT_CHANNEL_WINDOW_INDEX);
    f_is_last_all_channel_input = w_is_last_all_channel_input;
  endfunction

  // f_is_last_read_out: true once READ_OUTPUT fetched the last value from RAM, letting
  // OUTPUT_CTRL_BLOCK switch to CONV_OUTPUT safely.
  function automatic logic f_is_last_read_out();
    // Static variable preserves the last computed result for waveform visibility
    static logic w_is_last_read_out;
    w_is_last_read_out = (r_addr_count_read_out == (OUTPUT_FEATURE_NUM_ELEMS - 1));
    f_is_last_read_out = w_is_last_read_out;
  endfunction

  // f_is_last_write_out: flags the final store inside a window so OUTPUT_CTRL_BLOCK can advance its
  // counters and eventually raise p_end.
  function automatic logic f_is_last_write_out();
    // Static variable preserves the last computed result for waveform visibility
    static logic w_is_last_write_out;
    w_is_last_write_out = (r_addr_count_write_out == (OUTPUT_FEATURE_NUM_ELEMS - 1));
    f_is_last_write_out = w_is_last_write_out;
  endfunction

  // f_is_last_row_out: raises on the last horizontal stride of the current row, coordinating the
  // row/column wrap logic shared with OUTPUT_TILE_INDEX_BLOCK.
  function automatic logic f_is_last_row_out();
    // Static variable preserves the last computed result for waveform visibility
    static logic w_is_last_row_out;
    w_is_last_row_out = (r_window_counter_row_out >= LAST_WINDOW_ROW_INDEX);
    f_is_last_row_out = w_is_last_row_out;
  endfunction

  // f_is_last_channel_out: high when the present output channel is complete, allowing
  // OUTPUT_CTRL_BLOCK to either loop channels or enter END_CHANNEL.
  function automatic logic f_is_last_channel_out();
    // Static variable preserves the last computed result for waveform visibility
    static logic w_is_last_channel_out;
    w_is_last_channel_out = (r_window_counter_channel_out >= LAST_WINDOW_INDEX_PER_PLANE);
    f_is_last_channel_out = w_is_last_channel_out;
  endfunction

  // f_is_last_all_channel_out: final completion flag for all channels/windows, consumed by both the
  // output FSM and P_END_BLOCK to hold p_end high.
  function automatic logic f_is_last_all_channel_out();
    // Static variable preserves the last computed result for waveform visibility
    static logic w_is_last_all_channel_out;
    w_is_last_all_channel_out = (r_window_counter_all_channel_out >= LAST_OUTPUT_CHANNEL_WINDOW_INDEX - 1);
    f_is_last_all_channel_out = w_is_last_all_channel_out;
  endfunction

endmodule
