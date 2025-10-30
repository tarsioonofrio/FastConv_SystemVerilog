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

  typedef enum {
    IDLE_CONTROL,
    BIAS,
    WEIGHT,
    READ_INPUT,
    END_CONTROL
  } state_input_type;

  typedef enum {
    IDLE_OUTPUT,
    READ_OUTPUT,
    SUM,
    WRITE_OUTPUT
  } state_output_type;

  state_input_type current_st_input, next_st_input;
  state_output_type current_st_output, next_st_output;

  // Weight read counter
  logic [$clog2(M1_SIZE*M2_SIZE)-1:0] r_count_wh;
  // Input feature register read counter
  logic [$clog2(C1_SIZE*C2_SIZE)-1:0] r_count_fin;
  // Output feature register write counter
  logic [$clog2(A1_SIZE*A2_SIZE)-1:0] r_count_write_fout;
  // Output feature register read counter
  logic [$clog2(A1_SIZE*A2_SIZE)-1:0] r_count_read_fout;
  // Output counter
  logic [$clog2(A1_SIZE*A2_SIZE)-1:0] w_count_fout;
  // Output feature write counter
  // logic [$floor($clog2(N_CHANNEL_OUT) + 0.5)-1:0] r_count_ch_out;
  // Bias read counter; bias depth is one so it is unused for now
  logic [$floor($clog2(N_CHANNEL_OUT) + 0.5)-1:0] r_addr_bias;
  // Temporary substitute for r_addr_bias
  // logic [2:0] r_addr_bias;
  // Base address register for weight blocks
  logic [$clog2(M1_SIZE * M2_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT)-1:0] r_addr_wh;
  // Base address register for input features
  logic [$clog2(M1_SIZE * M2_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT + N_CHANNEL_IN * FEAT_INPUT_SIZE * FEAT_INPUT_SIZE)-1:0] r_addr_fin;
  // Row-aligned window counter for read-side address updates and reuse control
  logic [$clog2(N_WINDOW):0] r_window_horizontal_in;
  // Total window counter for a channel
  logic [$clog2(N_WINDOW * N_WINDOW)-1:0] r_window_vertical_in;
  // Total window counter for a channel
  logic [$clog2(N_WINDOW * N_WINDOW * N_CHANNEL_IN)-1:0] r_window_channel_in;
  // Total window counter for the read path
  logic [$clog2(N_WINDOW * N_WINDOW * N_CHANNEL_OUT * N_CHANNEL_IN)-1:0] r_window_total_in;

  // Base address register for output features
  logic [$clog2(N_CHANNEL_OUT * FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE)-1:0] r_addr_fout;
  // Total window counter for the write path
  logic [$clog2(N_WINDOW * N_WINDOW * N_CHANNEL_OUT * N_CHANNEL_IN)-1:0] r_window_total_out;
  // Total window counter for all in channel for FSM write
  logic [$clog2(N_WINDOW * N_WINDOW * N_CHANNEL_IN)-1:0] r_window_channel_out;
  // Total window counter for a channel
  logic [$clog2(N_WINDOW * N_WINDOW)-1:0] r_window_vertical_out;
  // Row-aligned window counter for write-side address updates
  logic [$clog2(N_WINDOW):0] r_window_horizontal_out;

  // Flag indicating end-of-row for read memory
  logic w_end_line_in;
  // Flag indicating end-of-row for write memory
  logic w_end_line_out;
  // Flag indicating the input window is ready for convolution
  logic w_end_read_fin;
  // Flag indicating the output window finished reading
  logic w_end_read_fout;
  // Flag indicating the output window finished writing
  logic w_end_write_fout;
  // Flag indicating the input window finished reading (renamed)
  logic w_end_vertical_in;
  // Flag indicating the output channel finished writing (renamed)
  logic w_end_vertical_out;
  logic w_end_layer_in;
  logic w_end_layer_out;
  logic w_end_channel_in;
  logic w_end_channel_out;
  logic w_end_last_channel;
  // Current input feature address
  logic[NADDR-1:0] w_addr_fin;

  logic w_output_en;
  logic r_read_en;
  // Register bank for input features
  type_input  r_feat_in;
  // Register bank for kernel weights
  type_weight r_weight;
  // Register bank for output features
  type_output r_conv_output;
  type_output r_feat_output;

  // Sequential logic that advances the state machines
  always_ff @(posedge clk or posedge reset) begin: FSM_BLOCK
    if (reset) begin
      current_st_input  <= IDLE_CONTROL;
      current_st_output <= IDLE_OUTPUT;
    end else begin
      current_st_input  <= next_st_input;
      current_st_output <= next_st_output;
    end
  end

  // Input state machine block

  // Combinational logic for the input (read) state machine
  always_comb begin: next_st_input_block
    next_st_input = current_st_input;
    unique case (current_st_input)
      // IDLE_CONTROL
      // Waits for start to begin reading weights and then input data; bias handling is currently disabled
      default: begin
        if (p_start)
          next_st_input = WEIGHT;
          // next_st_input = BIAS;
      end
      BIAS: begin
        next_st_input = WEIGHT;
      end
      // Waits for the weight fetch covering the active input/output channel pair before moving on to input data
      WEIGHT: begin
        if (r_count_wh == (M1_SIZE * M2_SIZE) - 1) begin
          next_st_input = READ_INPUT;
        end
      end
      // Waits until the input register bank is full; based on processed windows it may keep reading, reload weights/bias, or finish
      READ_INPUT: begin
        if (w_end_read_fin) begin
          // When all windows across input and output channels have been read, finish control
          if (r_window_total_in == N_WINDOW * N_WINDOW * N_CHANNEL_OUT * N_CHANNEL_IN - 1)
            next_st_input = END_CONTROL;
          else
          // When all output-channel windows are complete, load bias (disabled for now)
          // if (r_window_total_in == N_WINDOW * N_WINDOW * N_CHANNEL_OUT)
          //  next_st_input = BIAS;
          // else
          // When a full set of windows for an input channel is done, reload weights
          if (r_window_vertical_in == N_WINDOW * N_WINDOW - 1)
            next_st_input = WEIGHT;
          else
          // Otherwise keep reading input data
            next_st_input = READ_INPUT;
        end
      end
    endcase
  end

  // Sequential logic updating the registers tied to the input state machine
  always_ff @(posedge clk) begin: current_st_input_block
    if (reset) begin
      r_read_en    <= 1'b0;
      // Bias base address starts at zero
      r_addr_bias  <= 0;
      // Weight base address follows the bias region
      r_addr_wh    <= N_CHANNEL_OUT;
      // Input feature base address follows the weight region
      r_addr_fin   <= N_CHANNEL_OUT + M1_SIZE * M2_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT;
      r_count_wh   <= 0;
      r_count_fin  <= 0;
      r_window_total_in     <= 0;
      r_window_vertical_in   <= 0;
      r_window_horizontal_in  <= 0;
      r_weight     <= '{default: '0};
      r_feat_in    <= '{default: '0};
    end else begin
      unique case (current_st_input)
        default: begin end
        IDLE_CONTROL: begin
          r_read_en   <= 1'b0;
          r_addr_bias <= 0;
          r_addr_wh   <= N_CHANNEL_OUT;
          r_addr_fin  <= N_CHANNEL_OUT + M1_SIZE * M2_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT;
          r_count_wh  <= 0;
          r_count_fin <= 0;
          r_window_total_in    <= 0;
          r_window_vertical_in   <= 0;
          r_window_horizontal_in  <= 0;
          r_window_channel_in  <= 0;
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
          r_count_fin <= 0;
          if (p_input_valid) begin
            r_addr_wh            <= r_addr_wh + 1;
            r_count_wh           <= r_count_wh + 1;
            r_weight[r_count_wh] <= p_input_data;
          end
        end
        // Each cycle advances the input address and stores the returned value in the indexed slot
        READ_INPUT: begin
          r_read_en  <= 1'b1;
          r_count_wh <= 0;
          if (p_input_valid && (r_count_fin < C1_SIZE * C1_SIZE)) begin
            r_count_fin                     <= r_count_fin + 1;
            r_feat_in[c_index[r_count_fin]] <= p_input_data;
          end

          // When the input buffer is full, increment the total window counter
          if(w_end_read_fin)
            r_window_total_in <= r_window_total_in + 1;

          // If the input buffer is full but the row has not ended:
          // - increment the per-row window counter
          // - position the input feature counter at the reuse start column
          // - move the base pointer to the next window horizontally
          if (w_end_read_fin && !w_end_line_in) begin
            // Preserve overlapping columns locally to enable horizontal window reuse
            // TODO perform test using an index table
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

            r_count_fin <= C1_SIZE * (C1_SIZE - A1_SIZE);
          end else if (w_end_read_fin && w_end_line_in)
            r_count_fin <= 0;

          if (w_end_read_fin && w_end_line_in)
            r_window_horizontal_in <= 0;
          else if (w_end_read_fin && !w_end_line_in)
            r_window_horizontal_in <= r_window_horizontal_in + 1;

          if (w_end_read_fin && w_end_vertical_in)
            r_window_vertical_in <= 0;
          else if (w_end_read_fin && !w_end_vertical_in)
            r_window_vertical_in <= r_window_vertical_in + 1;

          if (w_end_read_fin && w_end_channel_in)
            r_window_channel_in <= 0;
          else if (w_end_read_fin && !w_end_channel_in)
            r_window_channel_in <= r_window_channel_in + 1;

          if (w_end_read_fin && w_end_line_in && w_end_channel_in)
              r_addr_fin <= N_CHANNEL_OUT + M1_SIZE * M2_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT;
          else if (w_end_read_fin && !w_end_line_in)
            r_addr_fin  <= r_addr_fin + A1_SIZE;
          else if (w_end_read_fin && w_end_line_in && !w_end_vertical_in)
            r_addr_fin  <= r_addr_fin + C1_SIZE + FEAT_INPUT_SIZE * (A1_SIZE - 1);
          else if (w_end_read_fin && w_end_line_in && w_end_vertical_in)
            r_addr_fin  <= r_addr_fin + C1_SIZE + FEAT_INPUT_SIZE * (C1_SIZE - 1);
        end
      endcase
    end
  end

  // Combinational logic detecting end-of-row for read paths
  always_comb begin: w_end_line_in_block
    if (r_window_horizontal_in < N_WINDOW - 1)
      w_end_line_in = 1'b0;
    else
      w_end_line_in = 1'b1;
  end

  // Combinational logic detecting end-of-channel for read paths
  always_comb begin: w_end_vertical_in_block
    if (r_window_vertical_in < N_WINDOW * N_WINDOW - 1)
      w_end_vertical_in = 1'b0;
    else
      w_end_vertical_in = 1'b1;
  end

  always_comb begin: w_end_channel_in_block
    if (r_window_channel_in < (N_WINDOW * N_WINDOW * N_CHANNEL_IN - 1))
      w_end_channel_in = 1'b0;
    else
      w_end_channel_in = 1'b1;
  end


  // Combinational logic driving output ports from internal registers
  always_comb begin
    p_conv_input  = r_feat_in;
    p_conv_weight = r_weight;
    p_conv_start  = w_end_read_fin;
  end


  // Combinational logic asserting when the input buffer is full and convolution can start
  always_comb begin: w_end_read_fin_block
    if ((r_count_fin == (C1_SIZE * C2_SIZE)) && p_conv_idle)
      w_end_read_fin = 1'b1;
    else
      w_end_read_fin = 1'b0;
  end


  // Combinational logic computing the input read address from the input counter
  always_comb begin: w_addr_fin_block
    unique case (r_count_fin)
      default: w_addr_fin = r_addr_fin + 0; // 00
      01: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE + 0; // 05
      02: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 2 + 0; // 10
      03: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 3 + 0; // 15
      04: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 4 + 0; // 20

      05: w_addr_fin = r_addr_fin + 1; // 01
      06: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE + 1; // 06
      07: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 2 + 1; // 11
      08: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 3 + 1; // 16
      09: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 4 + 1; // 21

      10: w_addr_fin = r_addr_fin + 2; // 02
      11: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE + 2; // 07
      12: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 2 + 2; // 12
      13: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 3 + 2; // 17
      14: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 4 + 2; // 22

      15: w_addr_fin = r_addr_fin + 3; // 03
      16: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE + 3; // 08
      17: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 2 + 3; // 13
      18: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 3 + 3; // 18
      19: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 4 + 3; // 23

      20: w_addr_fin = r_addr_fin + 4; // 04
      21: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE + 4; // 09
      22: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 2 + 4; // 14
      23: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 3 + 4; // 19
      24: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 4 + 4; // 24
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
        p_input_addr = w_addr_fin;
        p_input_en = r_read_en;
      end
      default: begin
        p_input_addr = 0;
        p_input_en = 1'b0;
      end
    endcase
  end


  // Output state machine block

  // Combinational logic for the output (write) state machine
  always_comb begin: next_st_output_block
    next_st_output = current_st_output;
    unique case (current_st_output)
      IDLE_OUTPUT: begin
        if ((p_start && w_end_layer_out) || w_end_read_fin)
          next_st_output = READ_OUTPUT;
        else if ((p_start && !w_end_layer_out) || w_end_read_fin)
          next_st_output = SUM;
      end
      READ_OUTPUT: begin
        if (w_end_read_fout)
          next_st_output = SUM;
      end
      // Waits for the convolution-complete signal
      SUM: begin
        if (p_conv_end)
          next_st_output = WRITE_OUTPUT;
      end
      // Waits for the output data write to memory to complete and then returns to idle
      WRITE_OUTPUT: begin
        // if (w_end_write_fout)
        //   next_st_output = SUM;
        if (w_end_write_fout && w_end_layer_out && !w_end_vertical_out)
          next_st_output = READ_OUTPUT;
        else if (w_end_write_fout && !w_end_layer_out && !w_end_vertical_out)
          next_st_output = SUM;
        else if (w_end_write_fout && w_end_vertical_out)
          next_st_output = IDLE_OUTPUT;
        // else if (w_end_write_fout && r_window_total_out == (N_WINDOW * N_WINDOW * N_CHANNEL_IN) - 1)
          // next_st_output = IDLE_OUTPUT;
        else if (w_end_write_fout && r_window_total_out == (N_WINDOW * N_WINDOW * N_CHANNEL_OUT * N_CHANNEL_IN - 1))
          next_st_output = IDLE_OUTPUT;
      end
    endcase
  end

  // Sequential logic updating the registers tied to the output state machine
  always_ff @(posedge clk) begin: current_st_output_block
    if (reset) begin
      r_addr_fout <= 0;
      r_count_read_fout <= 0;
      r_count_write_fout <= 0;
      r_window_total_out <= 0;
      r_window_channel_out <= 0;
      r_window_vertical_out <= 0;
      r_window_horizontal_out <= 0;
      r_conv_output   <= '{default: '0};
      r_feat_output   <= '{default: '0};
    end else begin
      unique case (current_st_output)
        IDLE_OUTPUT: begin end
        // Each cycle advances the weight address and stores the returned value in-order
        READ_OUTPUT: begin
          if (p_output_valid && (r_count_read_fout < A1_SIZE * A2_SIZE))  begin
            r_count_read_fout                <= r_count_read_fout + 1;
            r_feat_output[r_count_read_fout] <= p_output_data_read;
          end
        end
        // Keep the output counter cleared while waiting for convolution to end; capture output data on completion
        SUM: begin
          r_count_read_fout  <= 0;
          r_count_write_fout <= 0;
          if (p_conv_end)
            for (int i = 0; i < A1_SIZE * A2_SIZE; i++)
              r_conv_output[i] <= r_feat_output[i] + p_conv_output[i];
          // else
          //   r_feat_output   <= '{default: '0};
          // TODO: Implement logic that adds only after the first layer
          // if (p_conv_end && !w_end_layer_out)
          //   r_conv_output <= p_conv_output;
          // else if (p_conv_end && w_end_layer_out)
          //   for (int i = 0; i < A1_SIZE * A2_SIZE; i++)
          //     r_conv_output[i] <= r_conv_output[i] + p_conv_output[i];
        end
        // Write output data to memory
        WRITE_OUTPUT: begin
          // Each cycle increments the output counter to select which register value gets written
          r_count_write_fout <= r_count_write_fout + 1;
          if(w_end_write_fout)
            r_window_total_out <= r_window_total_out + 1;

          // When the output window is full but the row continues:
          // - increment the per-row window counter
          // - move horizontally to the next window
          if (w_end_write_fout && w_end_line_out)
            r_window_horizontal_out <= 0;
          else if (w_end_write_fout && !w_end_line_out)
            r_window_horizontal_out <= r_window_horizontal_out + 1;

          if (w_end_write_fout && w_end_vertical_out)
            r_window_vertical_out <= 0;
          else if (w_end_write_fout && !w_end_vertical_out)
            r_window_vertical_out <= r_window_vertical_out + 1;

          if (w_end_write_fout && w_end_channel_out)
            r_window_channel_out <= 0;
          else if (w_end_write_fout && !w_end_channel_out)
            r_window_channel_out <= r_window_channel_out + 1;

          // if (w_end_write_fout && w_end_channel_out && w_end_vertical_out)
          //   r_addr_fout <= 0;
          if (w_end_write_fout && !w_end_channel_out && w_end_vertical_out)
            // r_addr_fout <= 0;
            // r_addr_fout <= r_addr_fout + A1_SIZE - (FEAT_OUTPUT_SIZE + FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE);
            r_addr_fout <= r_addr_fout + A1_SIZE + FEAT_OUTPUT_SIZE * (A1_SIZE - 1) - (FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE);
          else if (w_end_write_fout && w_end_line_out)
            r_addr_fout <= r_addr_fout + A1_SIZE + FEAT_OUTPUT_SIZE * (A1_SIZE - 1);
          else if (w_end_write_fout && !w_end_line_out)
            r_addr_fout <= r_addr_fout + A1_SIZE;
        end
      endcase
    end
  end

  always_comb begin: p_end_block
    p_end = (r_window_total_out == N_WINDOW * N_WINDOW * N_CHANNEL_OUT * N_CHANNEL_IN) ? 1'b1 : 1'b0;
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

  // Combinational logic asserting when the output buffer is full and all data is read from memory
  always_comb begin: w_end_read_fout_block
    if (r_count_read_fout == (A1_SIZE * A2_SIZE - 1))
      w_end_read_fout = 1'b1;
    else
      w_end_read_fout = 1'b0;
  end

  // Combinational logic asserting when the output buffer is empty and all data is written in memory
  always_comb begin: w_end_write_fout_block
    if (r_count_write_fout == (A1_SIZE * A2_SIZE - 1))
      w_end_write_fout = 1'b1;
    else
      w_end_write_fout = 1'b0;
  end

  // Combinational logic detecting end-of-row for write paths
  always_comb begin: w_end_line_out_block
    if (r_window_horizontal_out < (N_WINDOW - 1))
      w_end_line_out = 1'b0;
    else
      w_end_line_out = 1'b1;
  end

  // Combinational logic asserting when the output buffer is empty and all data is written in memory
  always_comb begin: w_end_vertical_out_block
    if (r_window_vertical_out < (N_WINDOW * N_WINDOW - 1))
      w_end_vertical_out = 1'b0;
    else
      w_end_vertical_out = 1'b1;
  end

  always_comb begin: w_end_layer_out_block
    if (r_window_channel_out < (N_WINDOW * N_WINDOW - 1))
      w_end_layer_out = 1'b0;
    else
      w_end_layer_out = 1'b1;
  end

  always_comb begin: w_end_last_channel_block
    if (r_window_channel_out < (N_WINDOW * N_WINDOW * (N_CHANNEL_IN - 1)))
      w_end_last_channel = 1'b0;
    else
      w_end_last_channel = 1'b1;
  end

  always_comb begin: w_end_channel_out_block
    if (r_window_channel_out < (N_WINDOW * N_WINDOW * N_CHANNEL_IN - 1))
      w_end_channel_out = 1'b0;
    else
      w_end_channel_out = 1'b1;
  end

  always_comb begin: w_count_fout_block
    if (current_st_output == WRITE_OUTPUT)
      w_count_fout <= r_count_write_fout;
    else
      w_count_fout <= r_count_read_fout;
  end

  // Combinational logic computing the write address from the output counter
  always_comb begin: p_output_addr_block
    unique case (w_count_fout)
      default: p_output_addr = r_addr_fout + 0;
      1: p_output_addr = r_addr_fout + 1;
      2: p_output_addr = r_addr_fout + 2;

      3: p_output_addr = r_addr_fout + FEAT_OUTPUT_SIZE + 0;
      4: p_output_addr = r_addr_fout + FEAT_OUTPUT_SIZE + 1;
      5: p_output_addr = r_addr_fout + FEAT_OUTPUT_SIZE + 2;

      6: p_output_addr = r_addr_fout + FEAT_OUTPUT_SIZE * 2 + 0;
      7: p_output_addr = r_addr_fout + FEAT_OUTPUT_SIZE * 2 + 1;
      8: p_output_addr = r_addr_fout + FEAT_OUTPUT_SIZE * 2 + 2;
    endcase
  end

  // Combinational logic driving output ports from internal registers
  always_comb begin: p_output_data_write_block
    p_output_data_write = r_conv_output[r_count_write_fout];
    // p_start_channel = r_start_channel;
  end

endmodule
