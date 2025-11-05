// TODO
// Avaliar se é melhor remover os contadores de janelas e comparar com os endereços.

module Control
  import pack_def::*;
  import pack_data::*;
  import pack_param::*;
  import pack_typedef::*;
#(
    parameter int NADDR            = 16,
    parameter int NBITS            = 20,
    parameter int LATENCY          = 1,
    parameter int ROM              = 0,
    // parameter int QUANT            = 8,
    // parameter int N_WINDOW         = 10,
    // parameter int N_CHANNEL_IN     = 1,
    // parameter int N_CHANNEL_OUT    = 1,
    // parameter int FEAT_INPUT_SIZE  = 32,
    // parameter int FEAT_OUTPUT_SIZE = 30,
    parameter int LAST_WINDOW      = 0
) (
    input  logic clk,
    input  logic reset,

    input  logic p_start,
    output logic p_end,

    output logic p_conv_start,
    input  logic p_conv_idle,
    input  logic p_conv_end,

    output type_input  p_conv_input,
    output type_weight p_conv_weight,
    input  type_output p_conv_output,

    output logic p_input_en,
    output logic[NADDR-1:0] p_input_addr,
    input  logic_vector p_input_data,
    input  logic p_input_valid,

    output logic p_output_en,
    output logic p_output_wr,
    output logic[NADDR-1:0] p_output_addr,
    output logic_vector p_output_data_write,
    input  logic_vector p_output_data_read,
    input  logic p_output_valid
);

  timeunit 1ns; timeprecision 1ps;

  // Weight read counter
  logic [$clog2(M1_SIZE*M2_SIZE)-1:0] r_count_wh;
  // Input feature register read counter
  logic [$clog2(C1_SIZE*C2_SIZE)-1:0] r_count_in;
  // Output feature register write counter
  logic [$clog2(A1_SIZE*A2_SIZE)-1:0] r_count_write_out;
  // Output feature register read counter
  logic [$clog2(A1_SIZE*A2_SIZE)-1:0] r_count_read_out;
  // Output counter
  logic [$clog2(A1_SIZE*A2_SIZE)-1:0] w_count_out;
  // Output feature write counter
  // logic [$floor($clog2(N_CHANNEL_OUT) + 0.5)-1:0] r_count_ch_out;
  // Bias read counter; bias depth is one so it is unused for now
  logic [$floor($clog2(N_CHANNEL_IN * N_CHANNEL_OUT) + 0.5)-1:0] r_addr_bias;
  // Temporary substitute for r_addr_bias
  // logic [2:0] r_addr_bias;
  // Base address register for weight blocks
  logic [$clog2(N_CHANNEL_IN * N_CHANNEL_OUT + M1_SIZE * M2_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT)-1:0] r_addr_wh;
  // Base address register for input features
  logic [$clog2(N_CHANNEL_IN * N_CHANNEL_OUT +M1_SIZE * M2_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT + N_CHANNEL_IN * FEAT_INPUT_SIZE * FEAT_INPUT_SIZE)-1:0] r_addr_in;
  // Row-aligned window counter for read-side address updates and reuse control
  logic [$clog2(N_WINDOW):0] r_window_horizontal_in;
  // Total window counter for a channel
  logic [$clog2(N_WINDOW * N_WINDOW)-1:0] r_window_channel_in;
  // Total window counter for a channel
  logic [$clog2(N_WINDOW * N_WINDOW * N_CHANNEL_IN)-1:0] r_window_all_channel_in;
  // Total window counter for the read path
  logic [$clog2(N_WINDOW * N_WINDOW * N_CHANNEL_OUT * N_CHANNEL_IN)-1:0] r_window_total_in;

  // Base address register for output features
  logic [$clog2(N_CHANNEL_OUT * FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE)-1:0] r_addr_out;
  // Total window counter for the write path
  logic [$clog2(N_WINDOW * N_WINDOW * N_CHANNEL_OUT * N_CHANNEL_IN)-1:0] r_window_total_out;
  // Total window counter for all in channel for FSM write
  logic [$clog2(N_WINDOW * N_WINDOW * N_CHANNEL_IN)-1:0] r_window_all_channel_out;
  // Total window counter for a channel
  logic [$clog2(N_WINDOW * N_WINDOW)-1:0] r_window_channel_out;
  // Row-aligned window counter for write-side address updates
  logic [$clog2(N_WINDOW):0] r_window_horizontal_out;

  // Flag indicating end-of-row for read memory
  logic w_end_horizontal_in;
  // Flag indicating end-of-row for write memory
  logic w_end_horizontal_out;
  // Flag indicating the input window is ready for convolution
  logic w_end_read_in;
  // Flag indicating the output window inished reading
  logic w_end_read_out;
  // Flag indicating the output window inished writing
  logic w_end_write_out;
  // Flag indicating the input window inished reading (renamed)
  logic w_end_channel_in;
  // Flag indicating the output channel inished writing (renamed)
  logic w_end_channel_out;
  logic w_end_first_channel_in;
  logic w_end_first_channel_out;
  logic w_end_all_channel_in;
  logic w_end_all_channel_out;
  logic w_end_last_channel_out;
  // Current input feature address
  logic[NADDR-1:0] w_addr_in;

  logic w_output_en;
  logic r_read_en;
  // Register bank for input features
  type_input  r_feat_in;
  // Register bank for kernel weights
  type_weight r_weight;
  // Register bank for output features
  type_output r_conv_output;
  type_output r_feat_output;

  typedef enum {
    IDLE_INPUT,
    BIAS,
    WEIGHT,
    FIRST_READ_INPUT,
    TRANSFER,
    READ_INPUT,
    WAIT_OUTPUT,
    END_INPUT
   } state_input_type;

   logic w_handshake_input;
   logic w_handshake_conv;
   logic w_handshake_output;

  typedef enum {
    IDLE_OUTPUT,
    READ_OUTPUT,
    CONV,
    FIRST_WRITE_OUTPUT,
    CONV_SUM,
    WRITE_OUTPUT,
    END_CHANNEL
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


  // control path: input

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
        if (r_count_wh == (M1_SIZE * M2_SIZE) - 1)
          next_st_input = FIRST_READ_INPUT;
      end
      FIRST_READ_INPUT: begin
        if (w_end_read_in)
        // if (w_end_read_in && w_handshake_output)
          next_st_input = TRANSFER;
      end
      TRANSFER: begin
        if (w_handshake_output)
          next_st_input = READ_INPUT;
        else
          next_st_input = WAIT_OUTPUT;
      end
      // Waits until the input register bank is full; based on processed windows it may keep reading, reload weights/bias, or inish
      READ_INPUT: begin
          if (w_end_read_in && !w_end_horizontal_in)
            next_st_input = TRANSFER;
         else if (w_end_read_in && w_end_horizontal_in) begin
          // When all windows across input and output channels have been read, inish control
          if (r_window_total_in == N_WINDOW * N_WINDOW * N_CHANNEL_OUT * N_CHANNEL_IN - 1)
            next_st_input = END_INPUT;
          else
          // When all output-channel windows are complete, load bias (disabled for now)
          // if (r_window_total_in == N_WINDOW * N_WINDOW * N_CHANNEL_OUT)
          //  next_st_input = BIAS;
          // else
          // When a full set of windows for an input channel is done, reload weights
          if (r_window_channel_in == N_WINDOW * N_WINDOW - 1)
            next_st_input = WEIGHT;
          else
          // else if (w_handshake_output)
            next_st_input = FIRST_READ_INPUT;
        end
      end
      WAIT_OUTPUT: begin
        if (w_handshake_output)
          next_st_input = READ_INPUT;
      end
      END_INPUT: begin
        next_st_input = IDLE_INPUT;
      end
    endcase
  end


  // control path: output

  // Combinational logic for the output (write) state machine
  always_comb begin: NEXT_ST_OUTPUT_BLOCK
    next_st_output = current_st_output;
    unique case (current_st_output)
      IDLE_OUTPUT: begin
        if (p_start)
          next_st_output = CONV;
      end
      CONV: begin
        if (w_handshake_conv)
          next_st_output = FIRST_WRITE_OUTPUT;
      end
      // Waits for the output data write to memory to complete and then returns to idle
      FIRST_WRITE_OUTPUT: begin
        // if (w_end_write_out)
        //   next_st_output = CONV_SUM;
        if (w_end_write_out && !w_end_channel_out)
          next_st_output = CONV;
        else if (w_end_write_out && w_end_channel_out)
          next_st_output = END_CHANNEL;
        // else if (w_end_write_out && r_window_total_out == (N_WINDOW * N_WINDOW * N_CHANNEL_IN) - 1)
          // next_st_output = IDLE_OUTPUT;
        else if (w_end_write_out && r_window_total_out == (N_WINDOW * N_WINDOW * N_CHANNEL_OUT * N_CHANNEL_IN - 1))
          next_st_output = IDLE_OUTPUT;
      end
      END_CHANNEL: begin
        next_st_output = READ_OUTPUT;
      end
      READ_OUTPUT: begin
        if (w_end_read_out)
          next_st_output = CONV_SUM;
      end
      // Waits for the convolution-complete signal
      CONV_SUM: begin
        if (w_handshake_conv)
          next_st_output = WRITE_OUTPUT;
      end
      // Waits for the output data write to memory to complete and then returns to idle
      WRITE_OUTPUT: begin
        // if (w_end_write_out)
        //   next_st_output = CONV_SUM;
        if (w_end_write_out && !w_end_channel_out)
          next_st_output = READ_OUTPUT;
        else if (w_end_write_out && w_end_channel_out)
          next_st_output = END_CHANNEL;
        // else if (w_end_write_out && r_window_total_out == (N_WINDOW * N_WINDOW * N_CHANNEL_IN) - 1)
          // next_st_output = IDLE_OUTPUT;
        else if (w_end_write_out && r_window_total_out == (N_WINDOW * N_WINDOW * N_CHANNEL_OUT * N_CHANNEL_IN - 1))
          next_st_output = IDLE_OUTPUT;
      end
    endcase
  end


  // Handshake signals

  always_comb begin: LATCH_INPUT_BLOCK
    if (reset)
      w_handshake_input <= '0;
   else
   if ((next_st_input == TRANSFER) || ((next_st_input == FIRST_READ_INPUT) && (current_st_input != FIRST_READ_INPUT) && (current_st_input != WEIGHT)))
   // if ((next_st_input == TRANSFER))
      w_handshake_input <= '1;
   else
   // if(w_end_read_fin)
      w_handshake_input <= '0;
  end

  always_comb begin: LATCH_CONV_BLOCK
    if (reset)
      w_handshake_conv <= '0;
     else
     if (p_conv_end)
      w_handshake_conv <= '1;
     else
     // if (w_end_write_out)
      w_handshake_conv <= '0;
  end

  always_comb begin: LATCH_OUTPUT_BLOCK
    if (reset)
      w_handshake_output <= '0;
    else
    if (w_end_write_out || (r_window_channel_in < 1))
      w_handshake_output <= '1;
    else
    // if (w_end_read_fin)
      w_handshake_output <= '0;
  end

  // always_comb begin: LATCH_CONTROL_BLOCK
  //   if (reset)
  //     w_handshake_control <= '0;
  //   else
  //   // if (w_end_read_fin && (next_st_output == WRITE_OUTPUT))
  //   if (next_st_input == READ_INPUT)
  //   // if ((next_st_input == READ_INPUT) && (next_st_output == WRITE_OUTPUT))
  //   // ((next_st_input == TRANSFER) || (next_st_input == HOLD_INPUT))
  //   // &&
  //   // ((next_st_output == CONV_SUM) || (next_st_output == READ_OUTPUT))
  //   // )
  //     w_handshake_control <= '1;
  //   else
  //   // if (w_end_read_fin)
  //     w_handshake_control <= '0;
  // end


  // Data path: input

  // Sequential logic updating the registers tied to the input state machine
  always_ff @(posedge clk) begin: CURRENT_ST_INPUT_BLOCK
    if (reset) begin
      r_read_en    <= 1'b0;
      // Bias base address starts at zero
      r_addr_bias  <= 0;
      // Weight base address follows the bias region
      r_addr_wh    <= N_CHANNEL_OUT;
      // Input feature base address follows the weight region
      r_addr_in   <= N_CHANNEL_IN * N_CHANNEL_OUT + M1_SIZE * M2_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT;
      r_count_wh   <= 0;
      r_count_in  <= 0;
      r_window_total_in     <= 0;
      r_window_channel_in   <= 0;
      r_window_horizontal_in  <= 0;
      r_weight     <= '{default: '0};
      r_feat_in    <= '{default: '0};
    end else begin
      unique case (current_st_input)
        default: begin end
        IDLE_INPUT: begin
          r_read_en   <= 1'b0;
          r_addr_bias <= 0;
          r_addr_wh   <= N_CHANNEL_IN * N_CHANNEL_OUT;
          r_addr_in  <= N_CHANNEL_IN * N_CHANNEL_OUT + M1_SIZE * M2_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT;
          r_count_wh  <= 0;
          r_count_in <= 0;
          r_window_total_in    <= 0;
          r_window_channel_in   <= 0;
          r_window_horizontal_in  <= 0;
          r_window_all_channel_in  <= 0;
          r_weight    <= '{default: '0};
          r_feat_in   <= '{default: '0};
        end
        // When fetching bias, read a single address and advance
        BIAS: begin
          r_addr_bias <= r_addr_bias + 1;
        end
        // Each cycle advances the weight address and stores the returned value in-order
        WEIGHT: begin
          r_read_en   <= 1'b1;
          r_count_in <= 0;
          if (p_input_valid) begin
            r_addr_wh            <= r_addr_wh + 1;
            r_count_wh           <= r_count_wh + 1;
            r_weight[r_count_wh] <= p_input_data;
          end
        end
        FIRST_READ_INPUT: begin
          r_read_en  <= 1'b1;
          r_count_wh <= 0;
          if (p_input_valid && (r_count_in < C1_SIZE * C1_SIZE)) begin
            r_count_in                     <= r_count_in + 1;
            r_feat_in[c_index[r_count_in]] <= p_input_data;
          end

          // When the input buffer is full, increment the total window counter
          if(w_end_read_in)
            r_window_total_in <= r_window_total_in + 1;

          // If the input buffer is full but the row has not ended:
          // - increment the per-row window counter
          // - position the input feature counter at the reuse start column
          // - move the base pointer to the next window horizontally
          if (w_end_read_in)
            // Preserve overlapping columns locally to enable horizontal window reuse
            // TODO perform test using an index table
            r_count_in <= C1_SIZE * (C1_SIZE - A1_SIZE);

          if (w_end_read_in)
            r_window_horizontal_in <= r_window_horizontal_in + 1;

          if (w_end_read_in)
            r_window_channel_in <= r_window_channel_in + 1;

          if (w_end_read_in)
            r_window_all_channel_in <= r_window_all_channel_in + 1;

          if (w_end_read_in && !w_end_horizontal_in)
            r_addr_in  <= r_addr_in + A1_SIZE;
        end
        TRANSFER: begin
          r_feat_in[00] <= r_feat_in[03];
          r_feat_in[01] <= r_feat_in[04];

          r_feat_in[05] <= r_feat_in[08];
          r_feat_in[06] <= r_feat_in[09];

          r_feat_in[10] <= r_feat_in[13];
          r_feat_in[11] <= r_feat_in[14];

          r_feat_in[15] <= r_feat_in[18];
          r_feat_in[16] <= r_feat_in[19];

          r_feat_in[20] <= r_feat_in[23];
          r_feat_in[21] <= r_feat_in[24];
        end
        // Each cycle advances the input address and stores the returned value in the indexed slot
        READ_INPUT: begin
          r_read_en  <= 1'b1;
          r_count_wh <= 0;
          if (p_input_valid && (r_count_in < C1_SIZE * C1_SIZE)) begin
            r_count_in                     <= r_count_in + 1;
            r_feat_in[c_index[r_count_in]] <= p_input_data;
          end

          // When the input buffer is full, increment the total window counter
          if(w_end_read_in)
            r_window_total_in <= r_window_total_in + 1;

          // If the input buffer is full but the row has not ended:
          // - increment the per-row window counter
          // - position the input feature counter at the reuse start column
          // - move the base pointer to the next window horizontally
          if (w_end_read_in && !w_end_horizontal_in) begin
            // Preserve overlapping columns locally to enable horizontal window reuse
            // TODO perform test using an index table
            r_count_in <= C1_SIZE * (C1_SIZE - A1_SIZE);
          end else if (w_end_read_in && w_end_horizontal_in)
            r_count_in <= 0;

          if (w_end_read_in && w_end_horizontal_in)
            r_window_horizontal_in <= 0;
          else if (w_end_read_in && !w_end_horizontal_in)
            r_window_horizontal_in <= r_window_horizontal_in + 1;

          if (w_end_read_in && w_end_channel_in)
            r_window_channel_in <= 0;
          else if (w_end_read_in && !w_end_channel_in)
            r_window_channel_in <= r_window_channel_in + 1;

          if (w_end_read_in && w_end_all_channel_in)
            r_window_all_channel_in <= 0;
          else if (w_end_read_in && !w_end_all_channel_in)
            r_window_all_channel_in <= r_window_all_channel_in + 1;

          if (w_end_read_in && w_end_horizontal_in && w_end_all_channel_in)
          r_addr_in <= N_CHANNEL_IN * N_CHANNEL_OUT + M1_SIZE * M2_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT;
          else if (w_end_read_in && !w_end_horizontal_in)
            r_addr_in  <= r_addr_in + A1_SIZE;
          else if (w_end_read_in && w_end_horizontal_in && !w_end_channel_in)
            r_addr_in  <= r_addr_in + C1_SIZE + FEAT_INPUT_SIZE * (A1_SIZE - 1);
          else if (w_end_read_in && w_end_horizontal_in && w_end_channel_in)
            r_addr_in  <= r_addr_in + C1_SIZE + FEAT_INPUT_SIZE * (C1_SIZE - 1);
        end
      endcase
    end
  end

  // Combinational logic asserting when the input buffer is full and convolution can start
  always_comb begin: W_END_READ_IN_BLOCK
    if ((r_count_in == (C1_SIZE * C2_SIZE)) && p_conv_idle)
      w_end_read_in = 1'b1;
    else
      w_end_read_in = 1'b0;
  end

  // Combinational logic detecting end-of-row for read paths
  always_comb begin: W_END_HORIZONTAL_IN_BLOCK
    if (r_window_horizontal_in < N_WINDOW - 1)
      w_end_horizontal_in = 1'b0;
    else
      w_end_horizontal_in = 1'b1;
  end

  // Combinational logic detecting end of this image channel for read paths
  always_comb begin: W_END_CHANNEL_IN_BLOCK
    if (r_window_channel_in < N_WINDOW * N_WINDOW - 1)
      w_end_channel_in = 1'b0;
    else
      w_end_channel_in = 1'b1;
  end

  // Combinational logic detecting end of all image channel for read paths
  always_comb begin: W_END_ALL_CHANNEL_IN_BLOCK
    if (r_window_all_channel_in < (N_WINDOW * N_WINDOW * N_CHANNEL_IN - 1))
      w_end_all_channel_in = 1'b0;
    else
      w_end_all_channel_in = 1'b1;
  end


  // Combinational logic computing the input read address from the input counter
  always_comb begin: W_ADDR_IN_BLOCK
    unique case (r_count_in)
      default: w_addr_in = r_addr_in + 0; // 00
      01: w_addr_in = r_addr_in + FEAT_INPUT_SIZE + 0; // 05
      02: w_addr_in = r_addr_in + FEAT_INPUT_SIZE * 2 + 0; // 10
      03: w_addr_in = r_addr_in + FEAT_INPUT_SIZE * 3 + 0; // 15
      04: w_addr_in = r_addr_in + FEAT_INPUT_SIZE * 4 + 0; // 20

      05: w_addr_in = r_addr_in + 1; // 01
      06: w_addr_in = r_addr_in + FEAT_INPUT_SIZE + 1; // 06
      07: w_addr_in = r_addr_in + FEAT_INPUT_SIZE * 2 + 1; // 11
      08: w_addr_in = r_addr_in + FEAT_INPUT_SIZE * 3 + 1; // 16
      09: w_addr_in = r_addr_in + FEAT_INPUT_SIZE * 4 + 1; // 21

      10: w_addr_in = r_addr_in + 2; // 02
      11: w_addr_in = r_addr_in + FEAT_INPUT_SIZE + 2; // 07
      12: w_addr_in = r_addr_in + FEAT_INPUT_SIZE * 2 + 2; // 12
      13: w_addr_in = r_addr_in + FEAT_INPUT_SIZE * 3 + 2; // 17
      14: w_addr_in = r_addr_in + FEAT_INPUT_SIZE * 4 + 2; // 22

      15: w_addr_in = r_addr_in + 3; // 03
      16: w_addr_in = r_addr_in + FEAT_INPUT_SIZE + 3; // 08
      17: w_addr_in = r_addr_in + FEAT_INPUT_SIZE * 2 + 3; // 13
      18: w_addr_in = r_addr_in + FEAT_INPUT_SIZE * 3 + 3; // 18
      19: w_addr_in = r_addr_in + FEAT_INPUT_SIZE * 4 + 3; // 23

      20: w_addr_in = r_addr_in + 4; // 04
      21: w_addr_in = r_addr_in + FEAT_INPUT_SIZE + 4; // 09
      22: w_addr_in = r_addr_in + FEAT_INPUT_SIZE * 2 + 4; // 14
      23: w_addr_in = r_addr_in + FEAT_INPUT_SIZE * 3 + 4; // 19
      24: w_addr_in = r_addr_in + FEAT_INPUT_SIZE * 4 + 4; // 24
    endcase
  end

  // Combinational mux selecting which memory region to read (bias, weights, input features, or idle) based on the input state
  always_comb begin
    unique case (current_st_input)
      BIAS: begin
        p_input_addr = r_addr_bias;
        p_input_en = 1'b0;
      end
      WEIGHT: begin
        p_input_addr = r_addr_wh;
        p_input_en = r_read_en;
      end
      READ_INPUT: begin
        p_input_addr = w_addr_in;
        p_input_en = r_read_en;
      end
      FIRST_READ_INPUT: begin
        p_input_addr = w_addr_in;
        p_input_en = r_read_en;
      end
      default: begin
        p_input_addr = 0;
        p_input_en = 1'b0;
      end
    endcase
  end

  // Combinational logic driving output ports from internal registers
  always_comb begin
    p_conv_input  = r_feat_in;
    p_conv_weight = r_weight;
    p_conv_start  = w_handshake_input;
  end


  // Data path: output

  // Sequential logic updating the registers tied to the output state machine
  always_ff @(posedge clk) begin: CURRENT_ST_OUTPUT_BLOCK
    if (reset) begin
      r_addr_out <= 0;
      r_count_read_out <= 0;
      r_count_write_out <= 0;
      r_window_total_out <= 0;
      r_window_all_channel_out <= 0;
      r_window_channel_out <= 0;
      r_window_horizontal_out <= 0;
      r_conv_output   <= '{default: '0};
      r_feat_output   <= '{default: '0};
    end else begin
      unique case (current_st_output)
        IDLE_OUTPUT: begin end
        CONV: begin
          r_count_write_out <= 0;
          if (w_handshake_conv)
            for (int i = 0; i < A1_SIZE * A2_SIZE; i++)
              r_conv_output[i] <= p_conv_output[i];
        end
        FIRST_WRITE_OUTPUT: begin
          // Each cycle increments the output counter to select which register value gets written
          r_count_write_out <= r_count_write_out + 1;
          if(w_end_write_out)
            r_window_total_out <= r_window_total_out + 1;

          // When the output window is full but the row continues:
          // - increment the per-row window counter
          // - move horizontally to the next window
          if (w_end_write_out && w_end_horizontal_out)
            r_window_horizontal_out <= 0;
          else if (w_end_write_out && !w_end_horizontal_out)
            r_window_horizontal_out <= r_window_horizontal_out + 1;

          if (w_end_write_out)
            r_window_channel_out <= r_window_channel_out + 1;

          if (w_end_write_out)
            r_window_all_channel_out <= r_window_all_channel_out + 1;

          // if (w_end_write_out && w_end_all_channel_out && w_end_channel_out)
          //   r_addr_out <= 0;
          // if (w_end_write_out && !w_end_all_channel_out && w_end_channel_out)
          //   // r_addr_out <= 0;
          //   // r_addr_out <= r_addr_out + A1_SIZE - (FEAT_OUTPUT_SIZE + FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE);
          //   r_addr_out <= r_addr_out + A1_SIZE + FEAT_OUTPUT_SIZE * (A1_SIZE - 1) - (FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE);
          // else
          if (w_end_write_out && w_end_horizontal_out)
            r_addr_out <= r_addr_out + A1_SIZE + FEAT_OUTPUT_SIZE * (A1_SIZE - 1);
          else if (w_end_write_out && !w_end_horizontal_out)
            r_addr_out <= r_addr_out + A1_SIZE;
        end
        // Each cycle advances the weight address and stores the returned value in-order
        READ_OUTPUT: begin
          if (p_output_valid && (r_count_read_out < A1_SIZE * A2_SIZE))  begin
            r_count_read_out                <= r_count_read_out + 1;
            r_feat_output[r_count_read_out] <= p_output_data_read;
          end
        end
        // Keep the output counter cleared while waiting for convolution to end; capture output data on completion
        CONV_SUM: begin
          r_count_read_out  <= 0;
          r_count_write_out <= 0;
          if (w_handshake_conv)
            for (int i = 0; i < A1_SIZE * A2_SIZE; i++)
              r_conv_output[i] <= r_feat_output[i] + p_conv_output[i];
          // else
          //   r_feat_output   <= '{default: '0};
          // TODO: Implement logic that adds only after the first layer
          // if (p_conv_end && !w_end_first_channel_out)
          //   r_conv_output <= p_conv_output;
          // else if (p_conv_end && w_end_first_channel_out)
          //   for (int i = 0; i < A1_SIZE * A2_SIZE; i++)
          //     r_conv_output[i] <= r_conv_output[i] + p_conv_output[i];
        end
        // Write output data to memory
        WRITE_OUTPUT: begin
          // Each cycle increments the output counter to select which register value gets written
          r_count_write_out <= r_count_write_out + 1;
          if(w_end_write_out)
            r_window_total_out <= r_window_total_out + 1;

          // When the output window is full but the row continues:
          // - increment the per-row window counter
          // - move horizontally to the next window
          if (w_end_write_out && w_end_horizontal_out)
            r_window_horizontal_out <= 0;
          else if (w_end_write_out && !w_end_horizontal_out)
            r_window_horizontal_out <= r_window_horizontal_out + 1;

          // if (w_end_write_out && w_end_channel_out)
          //   r_window_channel_out <= 0;
          // else
          if (w_end_write_out && !w_end_channel_out)
            r_window_channel_out <= r_window_channel_out + 1;

          // if (w_end_write_out && w_end_all_channel_out)
          //   r_window_all_channel_out <= 0;
          // else
          if (w_end_write_out && !w_end_all_channel_out)
            r_window_all_channel_out <= r_window_all_channel_out + 1;

          // if (w_end_write_out && w_end_all_channel_out && w_end_channel_out)
          //   r_addr_out <= 0;
          // if (w_end_write_out && !w_end_all_channel_out && w_end_channel_out)
          //   // r_addr_out <= 0;
          //   // r_addr_out <= r_addr_out + A1_SIZE - (FEAT_OUTPUT_SIZE + FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE);
          //   r_addr_out <= r_addr_out + A1_SIZE + FEAT_OUTPUT_SIZE * (A1_SIZE - 1) - (FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE);
          // else
          if (w_end_write_out && w_end_horizontal_out)
            r_addr_out <= r_addr_out + A1_SIZE + FEAT_OUTPUT_SIZE * (A1_SIZE - 1);
          else if (w_end_write_out && !w_end_horizontal_out)
            r_addr_out <= r_addr_out + A1_SIZE;
        end
          END_CHANNEL: begin
            r_window_horizontal_out <= 0;
            r_window_channel_out <= 0;

            if (w_end_all_channel_out)
              r_window_all_channel_out <= 0;

            if (!w_end_all_channel_out)
              // r_addr_out <= 0;
              // r_addr_out <= r_addr_out + A1_SIZE - (FEAT_OUTPUT_SIZE + FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE);
              r_addr_out <= r_addr_out + A1_SIZE + FEAT_OUTPUT_SIZE * (A1_SIZE - 1) - (FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE);
            else if (w_end_horizontal_out)
              r_addr_out <= r_addr_out + A1_SIZE + FEAT_OUTPUT_SIZE * (A1_SIZE - 1);
            else if (!w_end_horizontal_out)
              r_addr_out <= r_addr_out + A1_SIZE;
        end
      endcase
    end
  end

  // Combinational logic asserting when the output buffer is full and all data is read from memory
  always_comb begin: W_END_READ_OUT_BLOCK
    if (r_count_read_out == (A1_SIZE * A2_SIZE - 1))
      w_end_read_out = 1'b1;
    else
      w_end_read_out = 1'b0;
  end

  // Combinational logic asserting when the output buffer is empty and all data is written in memory
  always_comb begin: W_END_WRITE_OUT_BLOCK
    if (r_count_write_out == (A1_SIZE * A2_SIZE - 1))
      w_end_write_out = 1'b1;
    else
      w_end_write_out = 1'b0;
  end

  // Combinational logic detecting end-of-row for write paths
  always_latch begin: W_END_HORIZONTAL_OUT_BLOCK
    if (r_window_horizontal_out < (N_WINDOW - 1))
      w_end_horizontal_out = 1'b0;
    else
      w_end_horizontal_out = 1'b1;
  end

  // Combinational logic detecting end of this image channel for write paths
  always_comb begin: W_END_CHANNEL_OUT_BLOCK
    if (r_window_channel_out < (N_WINDOW * N_WINDOW - 2))
      w_end_channel_out = 1'b0;
    else
      w_end_channel_out = 1'b1;
  end

  // Combinational logic detecting if this is the first channel in the image
  always_comb begin: W_END_FIRST_CHANNEL_OUT_BLOCK
    if (r_window_all_channel_out < (N_WINDOW * N_WINDOW - 1))
      w_end_first_channel_out = 1'b0;
    else
      w_end_first_channel_out = 1'b1;
  end

  // Combinational logic detecting if this is the last channel in the image
  always_comb begin: W_END_LAST_CHANNEL_BLOCK
    if (r_window_all_channel_out < (N_WINDOW * N_WINDOW * (N_CHANNEL_IN - 1) - 1))
      w_end_last_channel_out = 1'b0;
    else
      w_end_last_channel_out = 1'b1;
  end

  // Combinational logic detecting end of all image channel for write paths
  always_comb begin: W_END_ALL_CHANNEL_OUT_BLOCK
    if (r_window_all_channel_out < (N_WINDOW * N_WINDOW * N_CHANNEL_IN - 2))
      w_end_all_channel_out = 1'b0;
    else
      w_end_all_channel_out = 1'b1;
  end

  // Address counter for write paths
  always_comb begin: W_COUNT_OUT_BLOCK
    if ((current_st_output == WRITE_OUTPUT) || (current_st_output == FIRST_WRITE_OUTPUT))
      w_count_out <= r_count_write_out;
    else
      w_count_out <= r_count_read_out;
  end

  // Combinational logic computing the write address from the output counter
  always_comb begin: P_OUTPUT_ADDR_BLOCK
    unique case (w_count_out)
      default: p_output_addr = r_addr_out + 0;
      1: p_output_addr = r_addr_out + 1;
      2: p_output_addr = r_addr_out + 2;

      3: p_output_addr = r_addr_out + FEAT_OUTPUT_SIZE + 0;
      4: p_output_addr = r_addr_out + FEAT_OUTPUT_SIZE + 1;
      5: p_output_addr = r_addr_out + FEAT_OUTPUT_SIZE + 2;

      6: p_output_addr = r_addr_out + FEAT_OUTPUT_SIZE * 2 + 0;
      7: p_output_addr = r_addr_out + FEAT_OUTPUT_SIZE * 2 + 1;
      8: p_output_addr = r_addr_out + FEAT_OUTPUT_SIZE * 2 + 2;
    endcase
  end

  // Combinational logic driving output ports from internal registers
  always_comb begin: P_OUTPUT_DATA_WRITE_BLOCK
    p_output_data_write = r_conv_output[r_count_write_out];
    // p_start_channel = r_start_channel;
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
      FIRST_WRITE_OUTPUT: begin
        p_output_en = 1'b1;
        p_output_wr = 1'b1;
      end
      WRITE_OUTPUT: begin
        p_output_en = 1'b1;
        p_output_wr = 1'b1;
      end
    endcase
  end

  always_comb begin: P_END_BLOCK
    p_end = (r_window_total_out == N_WINDOW * N_WINDOW * N_CHANNEL_OUT * N_CHANNEL_IN) ? 1'b1 : 1'b0;
  end

endmodule
