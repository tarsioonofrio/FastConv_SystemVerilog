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
  // Windows per spatial plane
  localparam int WINDOWS_PER_PLANE                     = N_WINDOW * N_WINDOW;
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
  localparam int LAST_WINDOW_ROW_INDEX                 = N_WINDOW - 1;
  // Final window index per output channel
  localparam int LAST_OUTPUT_CHANNEL_WINDOW_INDEX      = WINDOWS_PER_OUTPUT_CHANNEL - 1;

  // Latency slack used to time HOLD_OUTPUT
  localparam int CYCLES_HOLD_OUTPUT                    = (OUTPUT_FEATURE_NUM_ELEMS*2 + 1) - (C1_SIZE * A1_SIZE + 1);
  // -- Input path control registers --
  // Base address register for input features
  logic [$clog2(TOTAL_NUM_CHANNELS + KERNEL_NUM_ELEMS * TOTAL_NUM_CHANNELS + N_CHANNEL_IN * INPUT_NUM_ELEMS)-1:0] r_addr_pointer_input;
  // Input feature register read counter
  logic [$clog2(INPUT_FEATURE_NUM_ELEMS)-1:0] r_addr_count_input;
  // Row-aligned window counter for read-side address updates and reuse control
  logic [$clog2(N_WINDOW):0] r_window_counter_row_input;
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
  logic [$clog2(N_WINDOW):0] r_window_counter_row_out;
  // Debug monitors for output-path predicates
  // logic w_is_last_read_out;
  // logic w_is_last_write_out;
  // logic w_is_last_row_out;
  // logic w_is_last_channel_out;
  // logic w_is_last_all_channel_out;

  // Current input feature address
  logic[NADDR-1:0] w_addr_ptr_pin;

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
  logic [$clog2(CYCLES_HOLD_OUTPUT) - 1:0] r_hold_output;
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
        if (r_addr_count_kernel == (KERNEL_NUM_ELEMS - 1))
          next_st_input = READ_INPUT;
      end
      READ_INPUT: begin
        if (f_is_last_read_input())
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
  always_comb begin: NEXT_ST_OUTPUT_BLOCK
    next_st_output = current_st_output;
    unique case (current_st_output)
      IDLE_OUTPUT: begin
        if (p_start)
          next_st_output = CONV_OUTPUT;
      end
      READ_OUTPUT: begin
        if (f_is_last_read_out())
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
  always_ff @(posedge clk) begin
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
  always_ff @(posedge clk) begin
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


  /*
   -------------------------------------------------------------
   7. Data Input path
   -------------------------------------------------------------
   */

  // Sequential logic updating the registers tied to the input state machine
  always_ff @(posedge clk) begin: CURRENT_ST_INPUT_BLOCK
    if (reset) begin
      r_read_en    <= 1'b0;
      // Bias base address starts at zero
      r_addr_pointer_bias  <= 0;
      // Weight base address follows the bias region
      r_addr_pointer_kernel    <= N_CHANNEL_OUT;
      // Input feature base address follows the weight region
      r_addr_pointer_input   <= TOTAL_NUM_CHANNELS + KERNEL_NUM_ELEMS * TOTAL_NUM_CHANNELS;
      r_addr_count_kernel   <= 0;
      r_addr_count_input  <= 0;
      r_channel_counter_input <= 0;
      r_hold_output <= 0;
      r_window_counter_total_input     <= 0;
      r_window_counter_channel_input   <= 0;
      r_window_counter_row_input  <= 0;
      r_kernel     <= '{default: '0};
      r_feat_input    <= '{default: '0};
    end else begin
      unique case (current_st_input)
        default: begin end
        IDLE_INPUT: begin
          r_read_en   <= 1'b0;
          r_addr_pointer_bias <= 0;
          r_addr_pointer_kernel   <= TOTAL_NUM_CHANNELS;
          r_addr_pointer_input  <= TOTAL_NUM_CHANNELS + KERNEL_NUM_ELEMS * TOTAL_NUM_CHANNELS;
          r_addr_count_kernel  <= 0;
          r_addr_count_input <= 0;
          r_channel_counter_input <= 0;
          r_hold_output <= 0;
          r_window_counter_total_input    <= 0;
          r_window_counter_channel_input   <= 0;
          r_window_counter_row_input  <= 0;
          r_window_counter_all_channel_input  <= 0;
          r_kernel    <= '{default: '0};
          r_feat_input   <= '{default: '0};
        end
        // When fetching bias, read a single address and advance
        BIAS: begin
          r_addr_pointer_bias <= r_addr_pointer_bias + 1;
        end
        // Each cycle advances the weight address and stores the returned value in-order
        WEIGHT: begin
          r_read_en   <= 1'b1;
          r_addr_count_input <= 0;
          if (p_input_valid) begin
            r_addr_pointer_kernel         <= r_addr_pointer_kernel + 1;
            r_addr_count_kernel           <= r_addr_count_kernel + 1;
            r_kernel[r_addr_count_kernel] <= p_input_data;
          end
        end
        CONV_INPUT: begin
          if (w_conv_input_fire) begin
            // When the input buffer is full, increment the total window counter
            r_window_counter_total_input <= r_window_counter_total_input + 1;

            if (f_is_last_row_input())
              r_addr_count_input <= 0;
            else begin
              r_addr_count_input <= C1_SIZE * (C1_SIZE - A1_SIZE);
              // If the input buffer is full but the row has not ended:
              // - increment the per-row window counter
              // - position the input feature counter at the reuse start column
              // - move the base pointer to the next window horizontally
              // Preserve overlapping columns locally to enable horizontal window reuse
              // TODO perform test using an index table
              r_feat_input[00] <= r_feat_input[03];
              r_feat_input[01] <= r_feat_input[04];

              r_feat_input[05] <= r_feat_input[08];
              r_feat_input[06] <= r_feat_input[09];

              r_feat_input[10] <= r_feat_input[13];
              r_feat_input[11] <= r_feat_input[14];

              r_feat_input[15] <= r_feat_input[18];
              r_feat_input[16] <= r_feat_input[19];

              r_feat_input[20] <= r_feat_input[23];
              r_feat_input[21] <= r_feat_input[24];
            end

            if (f_is_last_row_input())
              r_window_counter_row_input <= 0;
            else
              r_window_counter_row_input <= r_window_counter_row_input + 1;

            if (f_is_last_channel_input())
              r_window_counter_channel_input <= 0;
            else
              r_window_counter_channel_input <= r_window_counter_channel_input + 1;

            if (f_is_last_all_channel_input())
              r_window_counter_all_channel_input <= 0;
            else
              r_window_counter_all_channel_input <= r_window_counter_all_channel_input + 1;

            if (f_is_last_row_input() && f_is_last_all_channel_input())
              r_addr_pointer_input <= TOTAL_NUM_CHANNELS + KERNEL_NUM_ELEMS * TOTAL_NUM_CHANNELS;
            else if (f_is_last_row_input() && !f_is_last_channel_input())
              r_addr_pointer_input  <= r_addr_pointer_input + C1_SIZE + FEAT_INPUT_SIZE * (A1_SIZE - 1);
            else if (f_is_last_row_input() && f_is_last_channel_input())
              r_addr_pointer_input  <= r_addr_pointer_input + C1_SIZE + FEAT_INPUT_SIZE * (C1_SIZE - 1);
            else
              r_addr_pointer_input  <= r_addr_pointer_input + A1_SIZE;
          end
        end
        // Each cycle advances the input address and stores the returned value in the indexed slot
        READ_INPUT: begin
          r_read_en  <= 1'b1;
          r_addr_count_kernel <= 0;
          if (p_input_valid && (r_addr_count_input < C1_SIZE * C1_SIZE)) begin
            r_addr_count_input                     <= r_addr_count_input + 1;
            r_feat_input[c_index[r_addr_count_input]] <= p_input_data;
          end
        end
        HOLD_OUTPUT: begin
          if (r_hold_output == (CYCLES_HOLD_OUTPUT - 1))
            r_hold_output <= 0;
          else
            r_hold_output <= r_hold_output + 1;
        end
        HOLD_LAST_CONV: begin
          if (p_conv_idle)
            if (r_channel_counter_input >= N_CHANNEL_IN - 1)
              r_channel_counter_input <= 0;
            else
              r_channel_counter_input <= r_channel_counter_input + 1;
        end
      endcase
    end
  end

  // Combinational logic computing the input read address from the input counter
  always_comb begin: W_ADDR_IN_BLOCK
    unique case (r_addr_count_input)
      default: w_addr_ptr_pin = r_addr_pointer_input + 0; // 00
      01: w_addr_ptr_pin = r_addr_pointer_input + FEAT_INPUT_SIZE + 0; // 05
      02: w_addr_ptr_pin = r_addr_pointer_input + FEAT_INPUT_SIZE * 2 + 0; // 10
      03: w_addr_ptr_pin = r_addr_pointer_input + FEAT_INPUT_SIZE * 3 + 0; // 15
      04: w_addr_ptr_pin = r_addr_pointer_input + FEAT_INPUT_SIZE * 4 + 0; // 20

      05: w_addr_ptr_pin = r_addr_pointer_input + 1; // 01
      06: w_addr_ptr_pin = r_addr_pointer_input + FEAT_INPUT_SIZE + 1; // 06
      07: w_addr_ptr_pin = r_addr_pointer_input + FEAT_INPUT_SIZE * 2 + 1; // 11
      08: w_addr_ptr_pin = r_addr_pointer_input + FEAT_INPUT_SIZE * 3 + 1; // 16
      09: w_addr_ptr_pin = r_addr_pointer_input + FEAT_INPUT_SIZE * 4 + 1; // 21

      10: w_addr_ptr_pin = r_addr_pointer_input + 2; // 02
      11: w_addr_ptr_pin = r_addr_pointer_input + FEAT_INPUT_SIZE + 2; // 07
      12: w_addr_ptr_pin = r_addr_pointer_input + FEAT_INPUT_SIZE * 2 + 2; // 12
      13: w_addr_ptr_pin = r_addr_pointer_input + FEAT_INPUT_SIZE * 3 + 2; // 17
      14: w_addr_ptr_pin = r_addr_pointer_input + FEAT_INPUT_SIZE * 4 + 2; // 22

      15: w_addr_ptr_pin = r_addr_pointer_input + 3; // 03
      16: w_addr_ptr_pin = r_addr_pointer_input + FEAT_INPUT_SIZE + 3; // 08
      17: w_addr_ptr_pin = r_addr_pointer_input + FEAT_INPUT_SIZE * 2 + 3; // 13
      18: w_addr_ptr_pin = r_addr_pointer_input + FEAT_INPUT_SIZE * 3 + 3; // 18
      19: w_addr_ptr_pin = r_addr_pointer_input + FEAT_INPUT_SIZE * 4 + 3; // 23

      20: w_addr_ptr_pin = r_addr_pointer_input + 4; // 04
      21: w_addr_ptr_pin = r_addr_pointer_input + FEAT_INPUT_SIZE + 4; // 09
      22: w_addr_ptr_pin = r_addr_pointer_input + FEAT_INPUT_SIZE * 2 + 4; // 14
      23: w_addr_ptr_pin = r_addr_pointer_input + FEAT_INPUT_SIZE * 3 + 4; // 19
      24: w_addr_ptr_pin = r_addr_pointer_input + FEAT_INPUT_SIZE * 4 + 4; // 24
    endcase
  end


  /*
   -------------------------------------------------------------
   7. Data Output path
   -------------------------------------------------------------
   */


  // Sequential logic updating the registers tied to the output state machine
  always_ff @(posedge clk) begin: CURRENT_ST_OUTPUT_BLOCK
    if (reset) begin
      r_channel_counter_out <= 0;
      r_addr_pointer_out <= 0;
      r_addr_count_read_out <= 0;
      r_addr_count_write_out <= 0;
      r_window_counter_total_out <= 0;
      r_window_counter_all_channel_out <= 0;
      r_window_counter_channel_out <= 0;
      r_window_counter_row_out <= 0;
      r_conv_output   <= '{default: '0};
      r_feat_output   <= '{default: '0};
    end else begin
      unique case (current_st_output)
        default: begin end
        // Each cycle advances the weight address and stores the returned value in-order
        READ_OUTPUT: begin
          if (p_output_valid && (r_addr_count_read_out < OUTPUT_FEATURE_NUM_ELEMS))  begin
            r_addr_count_read_out                <= r_addr_count_read_out + 1;
            r_feat_output[r_addr_count_read_out] <= p_output_data_read;
          end
        end
        // Keep the output counter cleared while waiting for convolution to end; capture output data on completion
        CONV_OUTPUT: begin
          r_addr_count_read_out  <= 0;
          r_addr_count_write_out <= 0;
          // In first channel only get output data from convolutional module
          if (w_conv_result_ready && (r_channel_counter_out == 0))
             for (int i = 0; i < OUTPUT_FEATURE_NUM_ELEMS; i++)
               r_conv_output[i] <= p_conv_output[i];
          // After first channel, add output data from convolutional module to feature map output
          else if (w_conv_result_ready && (r_channel_counter_out > 0))
            for (int i = 0; i < OUTPUT_FEATURE_NUM_ELEMS; i++)
              r_conv_output[i] <= r_feat_output[i] + p_conv_output[i];
        end
        // Write output data to memory
        WRITE_OUTPUT: begin
          // Each cycle increments the output counter to select which register value gets written
          r_addr_count_write_out <= r_addr_count_write_out + 1;
          if (f_is_last_write_out())
            r_window_counter_total_out <= r_window_counter_total_out + 1;

          // When the output window is full but the row continues:
          // - increment the per-row window counter
          // - move horizontally to the next window
          if (f_is_last_write_out() && f_is_last_row_out())
            r_window_counter_row_out <= 0;
          else if (f_is_last_write_out() && !f_is_last_row_out())
            r_window_counter_row_out <= r_window_counter_row_out + 1;

          if (f_is_last_write_out() && !f_is_last_channel_out())
            r_window_counter_channel_out <= r_window_counter_channel_out + 1;

          if (f_is_last_write_out() && !f_is_last_all_channel_out())
            r_window_counter_all_channel_out <= r_window_counter_all_channel_out + 1;

          if (f_is_last_write_out() && f_is_last_row_out())
            r_addr_pointer_out <= r_addr_pointer_out + A1_SIZE + FEAT_OUTPUT_SIZE * (A1_SIZE - 1);
          else if (f_is_last_write_out() && !f_is_last_row_out())
            r_addr_pointer_out <= r_addr_pointer_out + A1_SIZE;
        end
        END_CHANNEL: begin
          r_window_counter_row_out <= 0;
          r_window_counter_channel_out <= 0;
          if (f_is_last_all_channel_out())
            r_window_counter_all_channel_out <= 0;
          // if (r_channel_counter_out >= N_CHANNEL_IN - 1)
          //    r_addr_pointer_out <= r_addr_pointer_out - OUTPUT_NUM_ELEMS;
          if (r_channel_counter_out >= N_CHANNEL_IN - 1)
            r_channel_counter_out <= 0;
          else begin
            r_channel_counter_out <= r_channel_counter_out + 1;
            r_addr_pointer_out <= r_addr_pointer_out - OUTPUT_NUM_ELEMS;
          end
        end
      endcase
    end
  end

  // Address counter for write paths
  always_comb begin: W_COUNT_OUT_BLOCK
    if (current_st_output == WRITE_OUTPUT)
      w_addr_count_out <= r_addr_count_write_out;
    else
      w_addr_count_out <= r_addr_count_read_out;
  end

  /*
   -------------------------------------------------------------
   8. Output port path
   -------------------------------------------------------------
   */


  always_comb begin: P_END_BLOCK
    p_end = (r_window_counter_total_out >= TOTAL_INPUT_WINDOWS) ? 1'b1 : 1'b0;
  end

  // Combinational logic driving output ports from internal registers
  always_comb begin
    p_conv_input  = r_feat_input;
    p_conv_weight = r_kernel;
    // p_conv_start  = w_handshake_input;
    p_conv_start = w_conv_input_fire;
  end

  // Combinational mux selecting which memory region to read (bias, weights, input features, or idle) based on the input state
  always_comb begin
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
  end

  // If the current state is WRITE_OUTPUT, enable write
  always_comb begin
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
        p_output_wr = 1'b1;
      end
    endcase
  end

  // Combinational logic computing the write address from the output counter
  always_comb begin: P_OUTPUT_ADDR_BLOCK
    unique case (w_addr_count_out)
      default: p_output_addr = r_addr_pointer_out + 0;
      1: p_output_addr = r_addr_pointer_out + 1;
      2: p_output_addr = r_addr_pointer_out + 2;

      3: p_output_addr = r_addr_pointer_out + FEAT_OUTPUT_SIZE + 0;
      4: p_output_addr = r_addr_pointer_out + FEAT_OUTPUT_SIZE + 1;
      5: p_output_addr = r_addr_pointer_out + FEAT_OUTPUT_SIZE + 2;

      6: p_output_addr = r_addr_pointer_out + FEAT_OUTPUT_SIZE * 2 + 0;
      7: p_output_addr = r_addr_pointer_out + FEAT_OUTPUT_SIZE * 2 + 1;
      8: p_output_addr = r_addr_pointer_out + FEAT_OUTPUT_SIZE * 2 + 2;
    endcase
  end

  // Combinational logic driving output ports from internal registers
  always_comb begin: P_OUTPUT_DATA_WRITE_BLOCK
    p_output_data_write = r_conv_output[r_addr_count_write_out];
    // p_start_channel = r_start_channel;
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
  function automatic logic f_is_last_read_input();
    // Static variable preserves the last computed result for waveform visibility
    static logic w_is_last_read_input;
    w_is_last_read_input = (r_addr_count_input == LAST_KERNEL_INDEX);
    f_is_last_read_input = w_is_last_read_input;
  endfunction

  function automatic logic f_is_last_row_input();
    // Static variable preserves the last computed result for waveform visibility
    static logic w_is_last_row_input;
    w_is_last_row_input = (r_window_counter_row_input >= LAST_WINDOW_ROW_INDEX);
    f_is_last_row_input = w_is_last_row_input;
  endfunction

  function automatic logic f_is_last_channel_input();
    // Static variable preserves the last computed result for waveform visibility
    static logic w_is_last_channel_input;
    w_is_last_channel_input = (r_window_counter_channel_input >= LAST_WINDOW_INDEX_PER_PLANE);
    f_is_last_channel_input = w_is_last_channel_input;
  endfunction

  function automatic logic f_is_last_all_channel_input();
    // Static variable preserves the last computed result for waveform visibility
    static logic w_is_last_all_channel_input;
    w_is_last_all_channel_input = (r_window_counter_all_channel_input >= LAST_OUTPUT_CHANNEL_WINDOW_INDEX);
    f_is_last_all_channel_input = w_is_last_all_channel_input;
  endfunction

  function automatic logic f_is_last_read_out();
    // Static variable preserves the last computed result for waveform visibility
    static logic w_is_last_read_out;
    w_is_last_read_out = (r_addr_count_read_out == (OUTPUT_FEATURE_NUM_ELEMS - 1));
    f_is_last_read_out = w_is_last_read_out;
  endfunction

  function automatic logic f_is_last_write_out();
    // Static variable preserves the last computed result for waveform visibility
    static logic w_is_last_write_out;
    w_is_last_write_out = (r_addr_count_write_out == (OUTPUT_FEATURE_NUM_ELEMS - 1));
    f_is_last_write_out = w_is_last_write_out;
  endfunction

  function automatic logic f_is_last_row_out();
    // Static variable preserves the last computed result for waveform visibility
    static logic w_is_last_row_out;
    w_is_last_row_out = (r_window_counter_row_out >= LAST_WINDOW_ROW_INDEX);
    f_is_last_row_out = w_is_last_row_out;
  endfunction

  function automatic logic f_is_last_channel_out();
    // Static variable preserves the last computed result for waveform visibility
    static logic w_is_last_channel_out;
    w_is_last_channel_out = (r_window_counter_channel_out >= LAST_WINDOW_INDEX_PER_PLANE);
    f_is_last_channel_out = w_is_last_channel_out;
  endfunction

  function automatic logic f_is_last_all_channel_out();
    // Static variable preserves the last computed result for waveform visibility
    static logic w_is_last_all_channel_out;
    w_is_last_all_channel_out = (r_window_counter_all_channel_out >= LAST_OUTPUT_CHANNEL_WINDOW_INDEX - 1);
    f_is_last_all_channel_out = w_is_last_all_channel_out;
  endfunction

endmodule
