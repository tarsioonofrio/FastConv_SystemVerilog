// TODO
// Avaliar se é melhor remover os contadores de janelas e comparar com os endereços.

module ChannelSum
  import pack_def::*;
  import pack_typedef::*;
  import pack_param::*;
#(
    parameter int NADDR            = 16,
    parameter int NBITS            = 20,
    parameter int LATENCY          = 1,
    parameter int ROM              = 0,
    parameter int QUANT            = 8,
    parameter int N_WINDOW         = 10,
    parameter int N_CHANNEL_IN     = 1,
    parameter int N_CHANNEL_OUT    = 1,
    parameter int FEAT_INPUT_SIZE  = 32,
    parameter int FEAT_OUTPUT_SIZE = 30,
    parameter int LAST_WINDOW      = 0
) (
    input  logic clk,
    input  logic reset,

    input  logic p_start, // p_conv_end from conv
    output logic p_end, // p_start from control

    input  type_output p_input, // from convolution
    output type_output p_output, // to control

    output logic p_read_en, // to memory output
    output logic[NADDR-1:0] p_read_addr,  // to memory output
    input  logic_vector p_read_data,  // to memory output
    input  logic p_read_valid  // to memory output

    // input  logic p_write_en, // from control
    // input  logic[NADDR-1:0] p_write_addr // from control
    // output logic p_write_en_out, // to memory
    // output logic[NADDR-1:0] p_write_addr_out, // to memory
    // output logic_vector p_write_data // to memory
);

  timeunit 1ns; timeprecision 1ps;

  typedef enum {
    IDLE_READ,
    SUM,
    READ
  } state_read_type;

  // typedef enum {
  //   IDLE_OUTPUT,
  //   SUM,
  //   OUTPUT
  // } state_output_type;

  state_read_type current_st_read, next_st_read;
  // state_output_type current_st_output, next_st_output;

  // Input feature read counter
  logic [$clog2(A1_SIZE*A2_SIZE)-1:0] r_count_fout;
  // Base address register for output features
  logic [$clog2(N_CHANNEL_OUT * FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE)-1:0] r_addr_fout;
  // Base address register for channel output features
  logic [$clog2(N_CHANNEL_OUT * FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE)-1:0] r_addr_ch_out;
  // Total window counter for the write path
  logic [$clog2(N_WINDOW * N_WINDOW * N_CHANNEL_OUT)-1:0] r_window_out_total;
  // Row-aligned window counter for write-side address updates
  logic [$clog2(N_WINDOW):0] r_window_out_horizontal;

  // Flag indicating end-of-row for read memory
  logic w_end_line_in;
  // Flag indicating end-of-row for write memory
  logic w_end_line_out;
  // Flag indicating the input window is ready for convolution
  logic w_end_fin;
  // Flag indicating the output window finished writing
  logic w_end_fout;
  // Flag indicating the output channel finished writing
  logic w_end_channel_out;
  // Current input feature address
  logic[NADDR-1:0] w_addr;

  // Register bank for input data from convolution
  type_output r_data;
  // Register bank for read data
  type_output r_input;

  // Sequential logic that advances the state machines
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      current_st_read <= IDLE_READ;
      // current_st_output <= IDLE_OUTPUT;
    end else begin
      current_st_read <= next_st_read;
      // current_st_output <= next_st_output;
    end
  end

  // Read state machine block

  // // Combinational logic for the input (read) state machine
  always_comb begin
    next_st_read = current_st_read;
    unique case (current_st_read)
      // IDLE_CONTROL
      // Waits for start to begin reading weights and then input data; bias handling is currently disabled
      IDLE_READ:
        if (p_start)
          next_st_read = READ;
      // Waits for the weight fetch covering the active input/output channel pair before moving on to input data
      READ:
        if (w_end_fout)
          next_st_read = SUM;
      SUM:
        next_st_read = IDLE_READ;
    endcase
  end

  // If the current state is FEAT_OUTPUT, enable write
  always_comb begin
    if (current_st_read == READ)
      p_read_en = 1'b1;
    else
      p_read_en = 1'b0;
  end

  // Combinational logic asserting when the output buffer is empty and all data is written in memory
  always_comb begin
    if (r_count_fout == (A1_SIZE * A2_SIZE) - 1)
      w_end_fout = 1'b1;
    else
      w_end_fout = 1'b0;
  end

  // Combinational logic detecting end-of-row for write paths
  always_comb begin
    if (r_window_out_horizontal < N_WINDOW - 1)
      w_end_line_out = 1'b0;
    else
      w_end_line_out = 1'b1;
  end

  // Combinational logic asserting when the output buffer is empty and all data is written in memory
  always_comb begin
    if (r_window_out_total < N_WINDOW * N_WINDOW)
      w_end_channel_out = 1'b0;
    else
      w_end_channel_out = 1'b1;
  end


  // Combinational logic computing the write address from the output counter
  always_comb begin
    unique case (r_count_fout)
      default: p_read_addr = r_addr_fout + 0;
      1: p_read_addr = r_addr_fout + 1;
      2: p_read_addr = r_addr_fout + 2;

      3: p_read_addr = r_addr_fout + FEAT_OUTPUT_SIZE + 0;
      4: p_read_addr = r_addr_fout + FEAT_OUTPUT_SIZE + 1;
      5: p_read_addr = r_addr_fout + FEAT_OUTPUT_SIZE + 2;

      6: p_read_addr = r_addr_fout + FEAT_OUTPUT_SIZE * 2 + 0;
      7: p_read_addr = r_addr_fout + FEAT_OUTPUT_SIZE * 2 + 1;
      8: p_read_addr = r_addr_fout + FEAT_OUTPUT_SIZE * 2 + 2;
    endcase
  end

  // Sequential logic updating the registers tied to the input state machine
  always_ff @(posedge clk) begin
    if (reset) begin
      r_addr_fout  <= 0;
      r_count_fout <= 0;
      r_window_out_horizontal <= 0;
      r_data   <= '{default: '0};
    end else begin
      unique case (current_st_read)
        default: begin end
        IDLE_READ: begin
          r_count_fout <= 0;
          r_data   <= '{default: '0};
        end
        // Each cycle advances the weight address and stores the returned value in-order
        READ: begin
          if (p_read_valid) begin
            r_count_fout         <= r_count_fout + 1;
            r_data[r_count_fout] <= p_read_data;
          end
          // Each cycle increments the output counter to select which register value gets written
          r_count_fout <= r_count_fout + 1;
          // When the output window is stored and the row ended:
          // - reset the window counter
          // - jump vertically to the first address of the next row group without overlap
          if (w_end_fout && w_end_line_out && !w_end_channel_out) begin
          // if (w_end_fout && w_end_line_out) begin
            r_addr_fout  <= r_addr_fout + A1_SIZE + FEAT_OUTPUT_SIZE * (A1_SIZE - 1);
            r_window_out_total <= r_window_out_total + 1;
            r_window_out_horizontal <= 0;
          // When the output window is full but the row continues:
          // - increment the per-row window counter
          // - move horizontally to the next window
          end else if (w_end_fout && !w_end_line_out && !w_end_channel_out) begin
          // end else if (w_end_fout && !w_end_line_out) begin
            r_window_out_horizontal <= r_window_out_horizontal + 1;
            r_window_out_total <= r_window_out_total + 1;
            r_addr_fout  <= r_addr_fout + A1_SIZE;
          end else if (w_end_fout && w_end_line_out && w_end_channel_out) begin
          // end else if (w_end_fout && w_end_line_out) begin
            r_window_out_total <= r_window_out_total + 1;
            r_window_out_horizontal <= 0;
            r_addr_ch_out <= 0;
            r_addr_fout  <= 0;
          end
        end
        SUM: begin
          for (int i = 0; i < A1_SIZE * A2_SIZE; i++)
            r_data[i] <= r_data[i] + p_input[i];
        end
      endcase
    end
  end

  // // Output state machine block

  // // Combinational logic for the input (read) state machine
  // always_comb begin
  //   next_st_output = current_st_output;
  //   unique case (current_st_output)
  //     // IDLE_CONTROL
  //     // Waits for start to begin reading weights and then input data; bias handling is currently disabled
  //     IDLE_READ:
  //       if (p_start)
  //         next_st_output = SUM;
  //     SUM:
  //       next_st_output = OUTPUT;
  //     // Waits for the weight fetch covering the active input/output channel pair before moving on to input data
  //     OUTPUT:
  //       next_st_output = IDLE_READ;
  //   endcase
  // end


  // // Combinational logic driving output ports from internal registers
  always_comb begin
    p_output     = r_data;
    p_end        = w_end_fout;
  end

endmodule
