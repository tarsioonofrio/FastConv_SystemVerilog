/*
   CONVOLUTION CONTROLLER  - (V0 - FERNANDO MORAES)  - 24/ABRIL
*/
`timescale 1ns / 1ps

module Conv
  #(
    parameter int unsigned N_CHANNEL_IN        = 3,
    parameter int unsigned N_CHANNEL_OUT       = 3,
    // parameter int unsigned KERNEL_SIZE         = 6,
    parameter int unsigned FEAT_INPUT_SIZE     = 32,
    parameter int unsigned FEAT_INPUT_WIDTH    = 32,
    parameter int unsigned NADDR               = 16,  // bits to p_input_addr the memory
    parameter int unsigned NBITS               = 20,
    parameter int unsigned QUANT               = 8,
    parameter int unsigned CONV_OUTPUT_SIZE    = 2,
    parameter int unsigned CONV_INPUT_SIZE     = 4,
    parameter int unsigned HADAMARD_SIZE       = 4,
    // Compatibility parameter for the shared testbench; hardware stays fixed at four MACs.
    parameter int unsigned NUM_MULT            = 4
  ) (
    input  logic clk,
    input  logic reset,
    input  logic p_start,
    output logic p_end,

    output logic p_input_en,                       // Enables a read operation on the input RAM
    output logic [NADDR-1:0] p_input_addr,
    input  logic [NBITS-1:0] p_input_data,
    input  logic p_input_valid,                    // Read-valid flag from the input RAM

    output logic p_output_en,                      // Enables access to the output RAM port
    output logic p_output_wr,                      // Write strobe for the output RAM port
    output logic [NADDR-1:0] p_output_addr,        // Address issued to the output RAM
    output logic [NBITS-1:0] p_output_data_write,  // Data driven into the output RAM on writes
    input  logic [NBITS-1:0] p_output_data_read,   // Data captured from the output RAM on reads
    input  logic p_output_valid                    // Read-valid flag from the output RAM
  );

  localparam int unsigned FIXED_NUM_MULT = 4;

  function automatic int f_width_min1(input int x);
    if (x <= 1)
      f_width_min1 = 1;
    else
      f_width_min1 = $clog2(x);
  endfunction

  logic [NBITS-1:0] r_input_feat[(CONV_INPUT_SIZE * CONV_INPUT_SIZE) - 1:0];  // input feature register bank
  logic [NBITS-1:0] w_input_feat_next[(CONV_INPUT_SIZE * CONV_INPUT_SIZE) - 1:0];  // next values for feature shift bank
  logic [NADDR-1:0] r_input_addr_feat;
  logic [NADDR-1:0] r_input_addr_kernel;
  logic [NADDR-1:0] r_input_window_next;
  logic [(CONV_INPUT_SIZE * CONV_INPUT_SIZE) - 1:0] w_input_feat_en;  // write-enable per feature register
  logic w_input_feat_write_valid;
  // Four-word prefetch bank for the first new column of the next tile.
  localparam int unsigned PREFETCH_WORDS = CONV_INPUT_SIZE;
  logic [NBITS-1:0] r_input_prefetch[PREFETCH_WORDS-1:0];
  logic r_input_prefetch_full;
  logic w_input_prefetch_commit;
  logic w_input_prefetch_mode;
  logic w_input_last_window_col;
  logic w_input_last_window_acc;
  logic w_input_last_channel_output;

  localparam WINDOW_COUNT_PER_LINE = (FEAT_INPUT_SIZE - 2 + CONV_OUTPUT_SIZE - 1) / CONV_OUTPUT_SIZE;
  localparam WINDOW_COUNT_PER_COLUMN = (FEAT_INPUT_SIZE - 2 + CONV_OUTPUT_SIZE - 1) / CONV_OUTPUT_SIZE;

  localparam WINDOW_COUNTER_WIDTH = f_width_min1(WINDOW_COUNT_PER_LINE * WINDOW_COUNT_PER_COLUMN);
  logic [WINDOW_COUNTER_WIDTH-1:0] r_input_window_counter_acc;

  localparam WINDOW_ROW_COUNTER_WIDTH = f_width_min1(WINDOW_COUNT_PER_LINE + 1);
  logic [WINDOW_ROW_COUNTER_WIDTH-1:0] r_input_window_counter_col;

  localparam ADDR_INPUT_COUNTER_WIDTH = f_width_min1(CONV_INPUT_SIZE);
  localparam INPUT_FEAT_INDEX_WIDTH = f_width_min1(CONV_INPUT_SIZE * CONV_INPUT_SIZE);
  logic [ADDR_INPUT_COUNTER_WIDTH-1:0] w_input_base_feat;
  logic [ADDR_INPUT_COUNTER_WIDTH-1:0] r_input_addr_count;
  logic [INPUT_FEAT_INDEX_WIDTH-1:0] w_input_feat_wr_index;

  localparam CHANNEL_INPUT_COUNTER_WIDTH = f_width_min1(N_CHANNEL_IN + 1);
  logic [CHANNEL_INPUT_COUNTER_WIDTH-1:0] r_input_channel_counter_input;

  localparam CHANNEL_OUTPUT_COUNTER_WIDTH = f_width_min1(N_CHANNEL_OUT + 1);
  logic [CHANNEL_OUTPUT_COUNTER_WIDTH-1:0] r_input_channel_counter_output;

  // REGISTER BANK FOR THE WEIGHTS ////////////////////////////////////////////
  localparam WEIGHT_CYCLES = HADAMARD_SIZE * HADAMARD_SIZE;
  localparam STREAM_CYCLES = 4;
  logic [(f_width_min1(STREAM_CYCLES + 1))-1:0] r_conv_multiply_count;
  localparam WEIGHT_WIDTH = f_width_min1(WEIGHT_CYCLES + 1);
  logic [NBITS-1:0] r_input_weight[WEIGHT_CYCLES-1:0];
  logic [WEIGHT_CYCLES-1:0] w_input_weight_en;
  logic [WEIGHT_WIDTH-1:0] r_input_count_kernel;
  logic w_input_weight_done;
  logic w_input_write_done;

  logic [NBITS-1:0] w_conv_transform [HADAMARD_SIZE*HADAMARD_SIZE-1:0];
  logic signed [NBITS-1+QUANT:0] w_conv_product [FIXED_NUM_MULT-1:0];  // QUANT more bits for the multipliers
  logic w_conv_end;
  logic w_conv_input_release;

  // Row-streaming state. FIXED_NUM_MULT is restricted to divisors 2, 4 and 8
  // for the TC2x2 transform (16 total Hadamard products).
  localparam int ROW_INDEX_WIDTH = f_width_min1(HADAMARD_SIZE);
  localparam int PRODUCT_INDEX_WIDTH = f_width_min1(WEIGHT_CYCLES);
  logic [NBITS-1:0] r_transform_row [HADAMARD_SIZE-1:0];
  logic [NBITS-1:0] r_inverse_row [HADAMARD_SIZE-1:0];
  logic [NBITS-1:0] r_output_accumulator [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0];
  logic [ROW_INDEX_WIDTH-1:0] r_inverse_row_idx;
  logic [PRODUCT_INDEX_WIDTH-1:0] r_transform_product_idx;
  logic [NBITS-1:0] w_inverse_partial [CONV_OUTPUT_SIZE-1:0];
  logic [NBITS-1:0] w_inverse_partial_current [CONV_OUTPUT_SIZE-1:0];
  logic [NBITS-1:0] w_output_acc_next [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0];
  logic [NBITS-1:0] w_output_final [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0];
  logic [NBITS-1:0] w_output_capture [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0];
  logic [NBITS-1:0] w_inverse_product_row [HADAMARD_SIZE-1:0];
  logic [NBITS-1:0] w_transform_feature [FIXED_NUM_MULT-1:0];
`ifdef STREAM_DEBUG
  integer stream_debug_had_count;
`endif
  localparam OUTPUT_RW_COUNT_MAX = (CONV_OUTPUT_SIZE * CONV_OUTPUT_SIZE) - 1;
  localparam OUTPUT_RW_COUNT_WIDTH = f_width_min1(CONV_OUTPUT_SIZE * CONV_OUTPUT_SIZE);
  logic [OUTPUT_RW_COUNT_WIDTH-1:0] r_output_read_count;
  logic [OUTPUT_RW_COUNT_WIDTH-1:0] r_output_write_count;
  logic [NBITS-1:0] r_output_write [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0];
  logic [NBITS-1:0] r_output_read [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0];
  logic [NADDR-1:0] w_output_addr;

  localparam FEAT_OUTPUT_SIZE = (FEAT_INPUT_SIZE - 2);
  logic [WINDOW_COUNTER_WIDTH-1:0] r_output_window_counter_col;
  logic [WINDOW_ROW_COUNTER_WIDTH-1:0] r_output_window_counter_row;
  logic [WINDOW_COUNTER_WIDTH-1:0] r_output_window_counter_acc;
  logic [CHANNEL_INPUT_COUNTER_WIDTH-1:0] r_output_channel_counter_input;
  logic [CHANNEL_OUTPUT_COUNTER_WIDTH-1:0] r_output_channel_counter_output;

  localparam OUTPUT_ADDR_OFFSET_WIDTH =
      f_width_min1((CONV_OUTPUT_SIZE * FEAT_OUTPUT_SIZE) + CONV_OUTPUT_SIZE);
  logic [OUTPUT_ADDR_OFFSET_WIDTH-1:0] r_output_addr_offset_read;
  logic [OUTPUT_ADDR_OFFSET_WIDTH-1:0] r_output_addr_offset_write;

  localparam OUTPUT_ADDR_CHANNEL_WIDTH = f_width_min1(N_CHANNEL_OUT * FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE);
  logic [OUTPUT_ADDR_CHANNEL_WIDTH-1:0] r_output_addr_channel;

  localparam OUTPUT_ADDR_COL_WIDTH = f_width_min1(FEAT_OUTPUT_SIZE);
  logic [OUTPUT_ADDR_COL_WIDTH-1:0] r_output_addr_col;

  localparam OUTPUT_ADDR_ROW_WIDTH = f_width_min1(FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE);
  logic [OUTPUT_ADDR_ROW_WIDTH-1:0] r_output_addr_row;

  logic w_output_last_window_row;
  logic w_output_last_window_col;
  logic w_output_last_channel_input;
  logic w_output_last_channel_output;
  logic w_output_last_window_acc;


  // -------------------------------------------------------------------------
  // FSM STATES DECLARION
  // -------------------------------------------------------------------------
  typedef enum logic [3:0] {
    WAIT_INPUT,
    ADDRESS_INPUT,
    READ_WEIGHTS,
    READ_IN_10A,
    READ_IN_10B,
    READ_IN_8C,
    READ_IN_8D,
    HOLD_WRITE,
    WAIT_PREFETCH,
    CONV_INPUT,
    TRANSFER,
    NEXT_ROW_INPUT
  } type_st_input;
  type_st_input st_input_current;
  type_st_input st_input_next;

  typedef enum logic [1:0] {
    WAIT_CONV,
    TRANSFORM,
    HADAMARD,
    INVERSE
  } type_st_conv;
  type_st_conv st_conv_current;
  type_st_conv st_conv_next;

  typedef enum logic [2:0] {
    WAIT_OUTPUT,
    ADDRESS_OUTPUT,
    RESET_OUTPUT,
    WRITE_OUTPUT,
    READ_OUTPUT,
    NEXT_ROW_OUTPUT
  } type_st_output;
  type_st_output st_output_current;
  type_st_output st_output_next;

  // ----------------------------------------------------------------------------------------------------
  // -------  PART 1 - ADDRESS TO ACCESS THE IFMAP AND WEIGHT MEMORY ------------------------------------
  // ----------------------------------------------------------------------------------------------------

  assign p_input_en   = (st_input_current inside {READ_WEIGHTS, READ_IN_10A, READ_IN_10B, READ_IN_8C, READ_IN_8D});
  assign p_input_addr = (st_input_current == READ_WEIGHTS) ? r_input_addr_kernel : r_input_addr_feat + NADDR'(r_input_addr_count);  // p_input_addr mux

  always_ff @(posedge clk or posedge reset) begin: INPUT_ADDR_POINTER_BLOCK
    if (reset) begin
      r_input_addr_feat <= '0;
      r_input_window_next <= CONV_OUTPUT_SIZE;
    end
    else if ((st_input_current == READ_IN_10A && st_input_next == READ_IN_10B) || (st_input_current == READ_IN_10B && st_input_next == READ_IN_8C) || (st_input_current == READ_IN_8C && st_input_next == READ_IN_8D) || (st_input_current == WAIT_PREFETCH && st_input_next == READ_IN_8D) || st_input_current == TRANSFER)
      r_input_addr_feat <= r_input_addr_feat + NADDR'(FEAT_INPUT_WIDTH);    // change internal p_input_addr in the state transition or in the TRANSFER state (CAUTION: PE)
    else if (st_input_current == NEXT_ROW_INPUT && !w_input_last_window_acc) begin  // when change the line, the read pointer moves 'r_input_window_next'
      r_input_addr_feat <= r_input_window_next + NADDR'(r_input_channel_counter_input * FEAT_INPUT_SIZE * FEAT_INPUT_WIDTH);  // restart for the first line
      r_input_window_next <= r_input_window_next + CONV_OUTPUT_SIZE;
    end else if (st_input_current == ADDRESS_INPUT && w_input_last_window_acc) begin
      r_input_window_next <= CONV_OUTPUT_SIZE;

      if (r_input_channel_counter_input == CHANNEL_INPUT_COUNTER_WIDTH'(N_CHANNEL_IN-1) ) begin               // change the IFMAP
        r_input_addr_feat <= 0;
        `ifdef SIMULATION
            $display(
                "RESETANDO PARA O CANAL 0 - DEU A VOLTA NOS IFMAPS time=%0t %d (%0d) st_input_current = %s",
                $time, r_input_channel_counter_input, N_CHANNEL_IN, st_input_current.name()
            );
        `endif
      end else begin
        r_input_addr_feat <= NADDR'((r_input_channel_counter_input + 1) *
                                    FEAT_INPUT_SIZE * FEAT_INPUT_WIDTH);
      end
    end
  end

  always_ff @(posedge clk or posedge reset) begin: WEIGHT_ADDR_POINTER_BLOCK
    if (reset)
      r_input_addr_kernel <= 0;
    else if (st_input_current == WAIT_INPUT && st_input_next == ADDRESS_INPUT)    // initializes only ONCE the weight p_input_addr (after the IFMAPs in the memory) (CAUTION: PE)
      r_input_addr_kernel <= NADDR'(N_CHANNEL_IN * FEAT_INPUT_SIZE * FEAT_INPUT_WIDTH);
    else if (st_input_current == READ_WEIGHTS)
      r_input_addr_kernel <= r_input_addr_kernel + 1;  // next weight
  end

  // ----------------------------------------------------------------------------------------------------
  // -------  PART 2 - INPUT FSM AND REGISTERS -----------------------------------------------------------
  // ----------------------------------------------------------------------------------------------------
  always_ff @(posedge clk or posedge reset) begin: INPUT_STATE_REG_BLOCK
    if (reset)
      st_input_current <= WAIT_INPUT;
    else
      st_input_current <= st_input_next;
  end

  always_comb begin: INPUT_NEXT_STATE_BLOCK
    st_input_next = st_input_current;
    priority case (st_input_current)
      WAIT_INPUT: if (p_start) st_input_next = ADDRESS_INPUT;
      ADDRESS_INPUT: st_input_next = READ_WEIGHTS;
      READ_WEIGHTS:
        if (w_input_weight_done) st_input_next = READ_IN_10A;
        else if (w_input_last_channel_output) st_input_next = WAIT_INPUT;  //end processing
      READ_IN_10A: if (r_input_addr_count == (CONV_INPUT_SIZE - 1)) st_input_next = READ_IN_10B;  // read 5*5 values
      READ_IN_10B: if (r_input_addr_count == (CONV_INPUT_SIZE - 1)) st_input_next = READ_IN_8C;
      // Capture the first new column while the current convolution runs.
      READ_IN_8C: if (r_input_addr_count == (CONV_INPUT_SIZE - 1))
                    st_input_next = w_input_prefetch_mode ? WAIT_PREFETCH : READ_IN_8D;
      WAIT_PREFETCH:
        if (w_input_prefetch_commit) st_input_next = READ_IN_8D;
      READ_IN_8D: if (r_input_addr_count == (CONV_INPUT_SIZE - 1)) st_input_next = CONV_INPUT;
      CONV_INPUT: st_input_next = TRANSFER;
      TRANSFER: st_input_next = HOLD_WRITE;  // p_start the convolution
      HOLD_WRITE:
        if ((w_conv_input_release || w_conv_end) && w_input_last_window_col && w_input_write_done) st_input_next = NEXT_ROW_INPUT;
          else if (!w_input_last_window_col && w_input_write_done) st_input_next = READ_IN_8C;
        else st_input_next = HOLD_WRITE;
      NEXT_ROW_INPUT:
        if (w_input_last_window_acc) st_input_next = ADDRESS_INPUT;
        else st_input_next = READ_IN_10A;
      default: st_input_next = WAIT_INPUT;
    endcase
  end

  assign w_input_weight_done = (r_input_count_kernel == WEIGHT_WIDTH'(WEIGHT_CYCLES - 1));
  assign w_input_write_done = r_output_write_count == 0 || r_output_write_count == OUTPUT_RW_COUNT_MAX;  // compare to zero for the first write test or the last value (8) in the next convolutions

  assign w_input_last_window_col = (r_input_window_counter_col == WINDOW_ROW_COUNTER_WIDTH'(WINDOW_COUNT_PER_LINE));
  assign w_input_last_window_acc = (r_input_window_counter_acc == WINDOW_COUNTER_WIDTH'(WINDOW_COUNT_PER_LINE * WINDOW_COUNT_PER_COLUMN));
  assign w_input_last_channel_output = (r_input_channel_counter_output == CHANNEL_OUTPUT_COUNTER_WIDTH'(N_CHANNEL_OUT));
  assign w_input_prefetch_mode = (r_input_window_counter_col != '0);

  // Release point for the current feature tile.  The prefetch bank may fill
  // before this point, but the tile itself remains untouched until release.
  assign w_conv_input_release =
                                (st_conv_current == INVERSE) ||
                                ((st_conv_current == HADAMARD) &&
                                 (r_conv_multiply_count == $bits(r_conv_multiply_count)'(STREAM_CYCLES - 1)));

  // Make the prefetched column visible only after the current tile is safe to
  // overwrite.  The output-side write guard preserves the existing overlap
  // contract between convolution and output accumulation.
  assign w_input_prefetch_commit = r_input_prefetch_full &&
                                   (w_conv_input_release || w_conv_end) &&
                                   w_input_write_done;

  assign p_end = (st_output_current == WRITE_OUTPUT) &&
                 (r_output_write_count == OUTPUT_RW_COUNT_WIDTH'(OUTPUT_RW_COUNT_MAX)) &&
                 w_input_last_channel_output;  // Signal completion only after the final output write.

  // -------------------------------------------------------------------------
  // READING REGISTERS
  // -------------------------------------------------------------------------

  always_ff @(posedge clk or posedge reset) begin: INPUT_READ_COUNTER_BLOCK
    if (reset) begin
      r_input_addr_count <= 0;
    end else begin
      if (st_input_current == READ_WEIGHTS) begin
        r_input_addr_count <= 0;
      end
      else if (st_input_current inside {READ_IN_10A, READ_IN_10B, READ_IN_8C, READ_IN_8D}) begin
        if (r_input_addr_count == (CONV_INPUT_SIZE - 1))
          r_input_addr_count <= 0;
        else
          r_input_addr_count <= r_input_addr_count + 1;
      end
    end
  end

  assign w_input_base_feat = (st_input_current == READ_IN_10A) ? 0 :
                             (st_input_current == READ_IN_10B) ? 1 :
                             (st_input_current == READ_IN_8C) ? 2 :
                             (st_input_current == READ_IN_8D) ? 3 : 0;


  // SET OF FIVE CONTROL REGISTERS:
  // r_input_channel_counter_input: number of the current IFMAP channel being read
  // r_input_channel_counter_output: number of the current OFMAP channel being processed
  // r_input_window_counter_acc: number of convolutions in a given IFMAP channel
  // r_input_window_counter_col :  number of horizontal convolutions in a given IFMAP channel - detect the last line
  // r_input_count_kernel:        number of weights read from memory
  always_ff @(posedge clk or posedge reset) begin: INPUT_CONTROL_COUNTERS_BLOCK
    if (reset) begin
      r_input_count_kernel           <= 0;
      r_input_window_counter_acc     <= 0;
      r_input_window_counter_col     <= 0;
      r_input_channel_counter_input  <= '1;  // p_start with all bits in '1' - IFchannel must be {0,1,2}
      r_input_channel_counter_output <= 0;
    end else begin
      if (st_input_current == ADDRESS_INPUT) begin
        if (r_input_channel_counter_input == CHANNEL_INPUT_COUNTER_WIDTH'(N_CHANNEL_IN - 1)) begin
          r_input_channel_counter_input  <= '0;
          r_input_channel_counter_output <= r_input_channel_counter_output + 1;
        end else begin
          r_input_channel_counter_input <= r_input_channel_counter_input + 1;
        end
        r_input_count_kernel       <= 0;
        r_input_window_counter_acc <= 0;  // reset counters
        r_input_window_counter_col <= 0;
      end

      if (st_input_current == NEXT_ROW_INPUT) begin
        r_input_window_counter_col <= 0;
      end

      if (st_input_current == TRANSFER) begin
        r_input_window_counter_acc <= r_input_window_counter_acc + 1;
        r_input_window_counter_col <= r_input_window_counter_col + 1;
      end

      if (st_input_current == READ_WEIGHTS) begin
        r_input_count_kernel <= r_input_count_kernel + 1;
      end
    end
  end

  // -------------------------------------------------------------------------
  // READING REGISTER BANK
  // -------------------------------------------------------------------------
  always_comb begin: INPUT_SHIFT_DATA_BLOCK
    // The direct-read path uses the memory sample as its default.  Only the
    // commit path below replaces selected entries with retained tile values.
    for (int unsigned i = 0; i < (CONV_INPUT_SIZE * CONV_INPUT_SIZE); i++)
      w_input_feat_next[i] = p_input_data;

    w_input_feat_next[0] = (st_input_current == READ_IN_10A) ? p_input_data : r_input_feat[2];
    w_input_feat_next[1] = (st_input_current == READ_IN_10B) ? p_input_data : r_input_feat[3];
    w_input_feat_next[4] = (st_input_current == READ_IN_10A) ? p_input_data : r_input_feat[6];
    w_input_feat_next[5] = (st_input_current == READ_IN_10B) ? p_input_data : r_input_feat[7];

    if (w_input_prefetch_commit) begin
      w_input_feat_next[0] = r_input_feat[2];
      w_input_feat_next[1] = r_input_feat[3];
      w_input_feat_next[2] = r_input_prefetch[0];
      w_input_feat_next[4] = r_input_feat[6];
      w_input_feat_next[5] = r_input_feat[7];
      w_input_feat_next[6] = r_input_prefetch[1];
      w_input_feat_next[8] = r_input_feat[10];
      w_input_feat_next[9] = r_input_feat[11];
      w_input_feat_next[10] = r_input_prefetch[2];
      w_input_feat_next[12] = r_input_feat[14];
      w_input_feat_next[13] = r_input_feat[15];
      w_input_feat_next[14] = r_input_prefetch[3];
    end

    // READ_IN_8D supplies the second new column after the prefetch commit.
    if (st_input_current == READ_IN_8D) begin
      w_input_feat_next[3]  = p_input_data;
      w_input_feat_next[7]  = p_input_data;
      w_input_feat_next[11] = p_input_data;
      w_input_feat_next[15] = p_input_data;
    end
  end

  assign w_input_feat_wr_index = INPUT_FEAT_INDEX_WIDTH'(w_input_base_feat) +
                                 (INPUT_FEAT_INDEX_WIDTH'(r_input_addr_count) *
                                  INPUT_FEAT_INDEX_WIDTH'(CONV_INPUT_SIZE));

  always_comb begin: INPUT_SHIFT_WE_BLOCK  // 'w_input_feat_en' to write into the register bank r_input_feat
    w_input_feat_en = '0;
    case (st_input_current)
      READ_IN_10A, READ_IN_10B, READ_IN_8C, READ_IN_8D:
        if ((st_input_current != READ_IN_8C) || !w_input_prefetch_mode)
          w_input_feat_en[w_input_feat_wr_index] = 1'b1;
      default:
        if (w_input_prefetch_commit)
          w_input_feat_en = 16'b0111011101110111;
    endcase
  end

  assign w_input_feat_write_valid = w_input_prefetch_commit || p_input_valid;

  always_ff @(posedge clk or posedge reset) begin: INPUT_PREFETCH_BUFFER_BLOCK
    if (reset) begin
      r_input_prefetch <= '{default: '0};
      r_input_prefetch_full <= 1'b0;
    end else begin
      if (st_input_current == READ_IN_8C && w_input_prefetch_mode && p_input_valid) begin
        r_input_prefetch[r_input_addr_count] <= p_input_data;
        if (r_input_addr_count == (CONV_INPUT_SIZE - 1))
          r_input_prefetch_full <= 1'b1;
      end else if (w_input_prefetch_commit) begin
        r_input_prefetch_full <= 1'b0;
      end
    end
  end

  always_ff @(posedge clk or posedge reset) begin: INPUT_FEATURE_REG_BLOCK  // initializes and write into the register bank and convolution register bank
    if (reset) begin
      r_input_feat[0] <= '0; r_input_feat[1] <= '0; r_input_feat[2] <= '0; r_input_feat[3] <= '0;
      r_input_feat[4] <= '0; r_input_feat[5] <= '0; r_input_feat[6] <= '0; r_input_feat[7] <= '0;
      r_input_feat[8] <= '0; r_input_feat[9] <= '0; r_input_feat[10] <= '0; r_input_feat[11] <= '0;
      r_input_feat[12] <= '0; r_input_feat[13] <= '0; r_input_feat[14] <= '0; r_input_feat[15] <= '0;
    end else begin
      if (w_input_feat_en[0] && w_input_feat_write_valid) r_input_feat[0] <= w_input_feat_next[0];
      if (w_input_feat_en[1] && w_input_feat_write_valid) r_input_feat[1] <= w_input_feat_next[1];
      if (w_input_feat_en[2] && w_input_feat_write_valid) r_input_feat[2] <= w_input_feat_next[2];
      if (w_input_feat_en[3] && w_input_feat_write_valid) r_input_feat[3] <= w_input_feat_next[3];
      if (w_input_feat_en[4] && w_input_feat_write_valid) r_input_feat[4] <= w_input_feat_next[4];
      if (w_input_feat_en[5] && w_input_feat_write_valid) r_input_feat[5] <= w_input_feat_next[5];
      if (w_input_feat_en[6] && w_input_feat_write_valid) r_input_feat[6] <= w_input_feat_next[6];
      if (w_input_feat_en[7] && w_input_feat_write_valid) r_input_feat[7] <= w_input_feat_next[7];
      if (w_input_feat_en[8] && w_input_feat_write_valid) r_input_feat[8] <= w_input_feat_next[8];
      if (w_input_feat_en[9] && w_input_feat_write_valid) r_input_feat[9] <= w_input_feat_next[9];
      if (w_input_feat_en[10] && w_input_feat_write_valid) r_input_feat[10] <= w_input_feat_next[10];
      if (w_input_feat_en[11] && w_input_feat_write_valid) r_input_feat[11] <= w_input_feat_next[11];
      if (w_input_feat_en[12] && w_input_feat_write_valid) r_input_feat[12] <= w_input_feat_next[12];
      if (w_input_feat_en[13] && w_input_feat_write_valid) r_input_feat[13] <= w_input_feat_next[13];
      if (w_input_feat_en[14] && w_input_feat_write_valid) r_input_feat[14] <= w_input_feat_next[14];
      if (w_input_feat_en[15] && w_input_feat_write_valid) r_input_feat[15] <= w_input_feat_next[15];
    end
  end

  // Weight register bank with per-entry write-enable.
  always_comb begin: WEIGHT_WE_BLOCK
    w_input_weight_en = '0;
    if (st_input_current == READ_WEIGHTS)
      w_input_weight_en[r_input_count_kernel] = 1'b1;
  end

  always_ff @(posedge clk or posedge reset) begin: WEIGHT_REG_BLOCK
    if (reset) begin
      r_input_weight[0] <= '0; r_input_weight[1] <= '0; r_input_weight[2] <= '0; r_input_weight[3] <= '0;
      r_input_weight[4] <= '0; r_input_weight[5] <= '0; r_input_weight[6] <= '0; r_input_weight[7] <= '0;
      r_input_weight[8] <= '0; r_input_weight[9] <= '0; r_input_weight[10] <= '0; r_input_weight[11] <= '0;
      r_input_weight[12] <= '0; r_input_weight[13] <= '0; r_input_weight[14] <= '0; r_input_weight[15] <= '0;
    end else if (st_input_current == READ_WEIGHTS) begin
      // A new weight load has priority over the final HADAMARD rotation.
      if (w_input_weight_en[0]) r_input_weight[0] <= p_input_data;
      if (w_input_weight_en[1]) r_input_weight[1] <= p_input_data;
      if (w_input_weight_en[2]) r_input_weight[2] <= p_input_data;
      if (w_input_weight_en[3]) r_input_weight[3] <= p_input_data;
      if (w_input_weight_en[4]) r_input_weight[4] <= p_input_data;
      if (w_input_weight_en[5]) r_input_weight[5] <= p_input_data;
      if (w_input_weight_en[6]) r_input_weight[6] <= p_input_data;
      if (w_input_weight_en[7]) r_input_weight[7] <= p_input_data;
      if (w_input_weight_en[8]) r_input_weight[8] <= p_input_data;
      if (w_input_weight_en[9]) r_input_weight[9] <= p_input_data;
      if (w_input_weight_en[10]) r_input_weight[10] <= p_input_data;
      if (w_input_weight_en[11]) r_input_weight[11] <= p_input_data;
      if (w_input_weight_en[12]) r_input_weight[12] <= p_input_data;
      if (w_input_weight_en[13]) r_input_weight[13] <= p_input_data;
      if (w_input_weight_en[14]) r_input_weight[14] <= p_input_data;
      if (w_input_weight_en[15]) r_input_weight[15] <= p_input_data;
    end else if (st_conv_current == HADAMARD) begin         // rotate four active weights
      r_input_weight[0]  <= r_input_weight[4];
      r_input_weight[1]  <= r_input_weight[5];
      r_input_weight[2]  <= r_input_weight[6];
      r_input_weight[3]  <= r_input_weight[7];
      r_input_weight[4]  <= r_input_weight[8];
      r_input_weight[5]  <= r_input_weight[9];
      r_input_weight[6]  <= r_input_weight[10];
      r_input_weight[7]  <= r_input_weight[11];
      r_input_weight[8]  <= r_input_weight[12];
      r_input_weight[9]  <= r_input_weight[13];
      r_input_weight[10] <= r_input_weight[14];
      r_input_weight[11] <= r_input_weight[15];
      r_input_weight[12] <= r_input_weight[0];
      r_input_weight[13] <= r_input_weight[1];
      r_input_weight[14] <= r_input_weight[2];
      r_input_weight[15] <= r_input_weight[3];
    end
  end

  // ----------------------------------------------------------------------------------------------------
  // -------  PART 3 - CONVOLUTION CONTROL AND CONVOLUTION MODULES --------------------------------------
  // ----------------------------------------------------------------------------------------------------
  always_ff @(posedge clk or posedge reset) begin: CONV_STATE_REG_BLOCK
    if (reset)
      st_conv_current <= WAIT_CONV;
    else
      st_conv_current <= st_conv_next;
  end

  always_comb begin: CONV_NEXT_STATE_BLOCK
    st_conv_next = st_conv_current;  // default prevents latch inference
    priority case (st_conv_current)
      WAIT_CONV: begin
        if (st_input_current == CONV_INPUT) begin
          st_conv_next = TRANSFORM;  // starts the convolution after moving data to the convolution register bank
        end
      end
      TRANSFORM:
        st_conv_next = HADAMARD;
      HADAMARD: begin
        if (r_conv_multiply_count == $bits(r_conv_multiply_count)'(STREAM_CYCLES - 1)) begin
          st_conv_next = INVERSE;
        end
      end
      INVERSE:
        st_conv_next = WAIT_CONV;
      default: st_conv_next = WAIT_CONV;
    endcase
  end

  // -------------------------------------------------------------------------
  // CONVOLUTION REGISTER BANK AND CONVOLUTION REGISTERS:  w_conv_end  -- r_conv_multiply_count
  // -------------------------------------------------------------------------
// `ifdef SIMULATION
//   time prev_time, curr_time;  // debug
// `endif

  always_ff @(posedge clk or posedge reset) begin: CONV_END_FLAG_BLOCK
    if (reset)
      w_conv_end <= 0;
    else begin
      if (st_conv_next == INVERSE)  // *** CAUTION: PE
        w_conv_end <= 1;
      else if (st_output_current == WRITE_OUTPUT)
        w_conv_end <= 0;
        // else if (st_output_current == WRITE_OUTPUT || st_conv_current == WAIT_CONV) w_conv_end <= 0;
    end
  end

  always_ff @(posedge clk or posedge reset) begin: CONV_MULTIPLY_COUNTER_BLOCK
    if (reset)
      r_conv_multiply_count <= 0;
    else begin
      if (st_conv_current == TRANSFORM)
          r_conv_multiply_count <= 0;
      // if (st_conv_current == WAIT_CONV || st_conv_current == TRANSFORM) r_conv_multiply_count <= 0;
      else if (st_conv_current == HADAMARD)
        r_conv_multiply_count <= r_conv_multiply_count + 1;
    end
  end

  // Transform produces the complete combinational matrix, but only one row
  // (or a partial row) is consumed at a time. FIXED_NUM_MULT is one of the
  // supported factors of the 16 Hadamard products.
  always_ff @(posedge clk or posedge reset) begin: STREAMING_DATAPATH_BLOCK
    if (reset) begin
      r_transform_row          <= '{default: '0};
      r_inverse_row          <= '{default: '0};
      r_output_accumulator        <= '{default: '0};
      r_inverse_row_idx <= '0;
      r_transform_product_idx <= '0;
`ifdef STREAM_DEBUG
      stream_debug_had_count <= 0;
`endif
    end else begin
      unique case (st_conv_current)
        TRANSFORM: begin
          r_transform_row[0] <= w_conv_transform[0];
          r_transform_row[1] <= w_conv_transform[1];
          r_transform_row[2] <= w_conv_transform[2];
          r_transform_row[3] <= w_conv_transform[3];
          r_inverse_row              <= '{default: '0};
          r_output_accumulator            <= '{default: '0};
          r_inverse_row_idx     <= '0;
          r_transform_product_idx <= '0;
`ifdef STREAM_DEBUG
          $display("STREAM TRANSFORM");
          for (int unsigned d = 0; d < HADAMARD_SIZE*HADAMARD_SIZE; d++)
            $write(" %0d", $signed(w_conv_transform[d]));
          $write("\n");
`endif
        end
        HADAMARD: begin
          r_transform_product_idx <= r_transform_product_idx + PRODUCT_INDEX_WIDTH'(FIXED_NUM_MULT);
          if (r_transform_product_idx == 0) begin
            r_transform_row[0] <= w_conv_transform[4];
            r_transform_row[1] <= w_conv_transform[5];
            r_transform_row[2] <= w_conv_transform[6];
            r_transform_row[3] <= w_conv_transform[7];
          end else if (r_transform_product_idx == 4) begin
            r_transform_row[0] <= w_conv_transform[8];
            r_transform_row[1] <= w_conv_transform[9];
            r_transform_row[2] <= w_conv_transform[10];
            r_transform_row[3] <= w_conv_transform[11];
          end else if (r_transform_product_idx == 8) begin
            r_transform_row[0] <= w_conv_transform[12];
            r_transform_row[1] <= w_conv_transform[13];
            r_transform_row[2] <= w_conv_transform[14];
            r_transform_row[3] <= w_conv_transform[15];
          end
          r_output_accumulator        <= w_output_acc_next;
          r_inverse_row_idx <= r_inverse_row_idx + 1'b1;
          r_inverse_row          <= w_inverse_product_row;
`ifdef STREAM_DEBUG
          $display("STREAM HAD product_base=%0d row=%0d", r_transform_product_idx, r_inverse_row_idx);
          $write("  F:"); for (int unsigned d = 0; d < FIXED_NUM_MULT; d++) $write(" %0d", $signed(w_transform_feature[d])); $write("\n");
          $write("  G:"); for (int unsigned d = 0; d < FIXED_NUM_MULT; d++) $write(" %0d", $signed(r_input_weight[d])); $write("\n");
          $write("  P:"); for (int unsigned d = 0; d < FIXED_NUM_MULT; d++) $write(" %0d", $signed(w_conv_product[d][NBITS-1:0])); $write("\n");
          $write("  ACC_NEXT:"); for (int unsigned d = 0; d < CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE; d++) $write(" %0d", $signed(w_output_acc_next[d])); $write("\n");
          stream_debug_had_count <= stream_debug_had_count + 1;
`endif
        end
        INVERSE: begin
`ifdef STREAM_DEBUG
          $display("STREAM FINAL");
          $write("  ACC:"); for (int unsigned d = 0; d < CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE; d++) $write(" %0d", $signed(r_output_accumulator[d])); $write("\n");
          $write("  Slast:"); for (int unsigned d = 0; d < HADAMARD_SIZE; d++) $write(" %0d", $signed(r_inverse_row[d])); $write("\n");
          $write("  SIG:"); for (int unsigned d = 0; d < CONV_OUTPUT_SIZE; d++) $write(" %0d", $signed(w_inverse_partial[d])); $write("\n");
          $write("  OUT:"); for (int unsigned d = 0; d < CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE; d++) $write(" %0d", $signed(w_output_final[d])); $write("\n");
`endif
        end
        default: begin end
      endcase
    end
  end

     // Instance of matrix multiplier "C"
  Transform #(
    .NBITS(NBITS),
    .CONV_OUTPUT_SIZE(CONV_OUTPUT_SIZE),
    .CONV_INPUT_SIZE(CONV_INPUT_SIZE),
    .HADAMARD_SIZE(HADAMARD_SIZE)
  ) trf (
      .pin (r_input_feat),
      .pout(w_conv_transform)
  );

  assign w_transform_feature[0] = r_transform_row[0];
  assign w_transform_feature[1] = r_transform_row[1];
  assign w_transform_feature[2] = r_transform_row[2];
  assign w_transform_feature[3] = r_transform_row[3];
  Multip #(.QUANT(QUANT), .NBITS(NBITS)) multip0(
    .feature(w_transform_feature[0]), .weight(r_input_weight[0]), .product(w_conv_product[0]));
  Multip #(.QUANT(QUANT), .NBITS(NBITS)) multip1(
    .feature(w_transform_feature[1]), .weight(r_input_weight[1]), .product(w_conv_product[1]));
  Multip #(.QUANT(QUANT), .NBITS(NBITS)) multip2(
    .feature(w_transform_feature[2]), .weight(r_input_weight[2]), .product(w_conv_product[2]));
  Multip #(.QUANT(QUANT), .NBITS(NBITS)) multip3(
    .feature(w_transform_feature[3]), .weight(r_input_weight[3]), .product(w_conv_product[3]));

  InverseRow inverse_row(.inverse_input_row(r_inverse_row), .inverse_partial(w_inverse_partial));
  assign w_inverse_product_row[0] = w_conv_product[0];
  assign w_inverse_product_row[1] = w_conv_product[1];
  assign w_inverse_product_row[2] = w_conv_product[2];
  assign w_inverse_product_row[3] = w_conv_product[3];
  InverseRow inverse_row_current(.inverse_input_row(w_inverse_product_row), .inverse_partial(w_inverse_partial_current));
  InverseRowAccumulate inverse_row_acc(
    .inverse_row_idx(r_inverse_row_idx), .accumulator_in(r_output_accumulator), .inverse_partial(w_inverse_partial_current), .accumulator_out(w_output_acc_next));
  assign w_output_final = (st_conv_current == INVERSE) ? r_output_accumulator : w_output_acc_next;
  assign w_output_capture = w_output_acc_next;


  // ----------------------------------------------------------------------------------------------------
  // -------  PART 4 - OUTPUT FSM AND READ/WRITE COUNTER -------------------------------------------------
  // ----------------------------------------------------------------------------------------------------



  always_ff @(posedge clk or posedge reset) begin: OUTPUT_STATE_REG_BLOCK
    if (reset) st_output_current <= WAIT_OUTPUT;
    else st_output_current <= st_output_next;
  end

  always_comb begin: OUTPUT_NEXT_STATE_BLOCK
    st_output_next = st_output_current;  // default
    priority case (st_output_current)
      WAIT_OUTPUT:
        if (st_input_current == ADDRESS_INPUT)
          st_output_next = RESET_OUTPUT;
      RESET_OUTPUT:
        if (w_conv_end)
          st_output_next = (r_output_channel_counter_input > 0) ? READ_OUTPUT : WRITE_OUTPUT;
      READ_OUTPUT:
        if (w_conv_end && r_output_read_count == OUTPUT_RW_COUNT_WIDTH'(OUTPUT_RW_COUNT_MAX))
          st_output_next = WRITE_OUTPUT;
      WRITE_OUTPUT:
        if (r_output_write_count == OUTPUT_RW_COUNT_WIDTH'(OUTPUT_RW_COUNT_MAX)) begin
          if (((r_output_channel_counter_input) > 0) && !w_output_last_window_row)
            st_output_next = READ_OUTPUT;      // accumulate next input channel
          else if ((r_output_channel_counter_input) == 0 && !w_output_last_window_row)
            st_output_next = RESET_OUTPUT;     // next window, same output channel
          else if (w_input_last_channel_output)
            st_output_next = WAIT_OUTPUT;      // global termination from input traversal
          else if (w_output_last_window_row)
            st_output_next = NEXT_ROW_OUTPUT;   // change output channel only
        end
      NEXT_ROW_OUTPUT:
      // I need to use r_input_channel_counter because output version have delay
        if (w_output_last_window_col)
          st_output_next = ADDRESS_OUTPUT;      // accumulate next input channel
        else if ((r_input_channel_counter_input) == 0)
          st_output_next = RESET_OUTPUT;     // next window, same output channel
        else if ((r_input_channel_counter_input) > 0)
          st_output_next = READ_OUTPUT;      // accumulate next input channel
      ADDRESS_OUTPUT:
        // if (st_input_current != READ_WEIGHTS)
          if ((r_input_channel_counter_input) == 0)
            st_output_next = RESET_OUTPUT;     // next window, same output channel
          else if ((r_input_channel_counter_input) > 0)
            st_output_next = READ_OUTPUT;      // accumulate next input channel
      default:
        st_output_next = WAIT_OUTPUT;
    endcase
  end

  assign w_output_last_channel_input = (r_output_channel_counter_input == CHANNEL_INPUT_COUNTER_WIDTH'(N_CHANNEL_IN - 1));
  assign w_output_last_channel_output = (r_output_channel_counter_output == CHANNEL_OUTPUT_COUNTER_WIDTH'(N_CHANNEL_OUT - 1));

  assign w_output_last_window_col = (r_output_window_counter_col == WINDOW_COUNTER_WIDTH'(WINDOW_COUNT_PER_COLUMN - 1));
  assign w_output_last_window_row = (r_output_window_counter_row == WINDOW_ROW_COUNTER_WIDTH'(WINDOW_COUNT_PER_LINE - 1));
  assign w_output_last_window_acc = (r_output_window_counter_acc == $bits(r_output_window_counter_acc)'((WINDOW_COUNT_PER_LINE * WINDOW_COUNT_PER_COLUMN) - 1));

  always_ff @(posedge clk or posedge reset) begin: OUTPUT_CONTROL_COUNTERS_BLOCK
    if (reset) begin
      r_output_channel_counter_input  <= '0;
      r_output_channel_counter_output <= '0;
    end else if (st_output_current == ADDRESS_OUTPUT) begin
      if (w_output_last_channel_input)  begin
        r_output_channel_counter_input <= '0;
        r_output_channel_counter_output <= r_output_channel_counter_output + 1'b1;
      end else
        r_output_channel_counter_input <= r_output_channel_counter_input + 1'b1;
    end
  end

  always_ff @(posedge clk or posedge reset) begin: OUTPUT_WINDOW_COUNTERS_BLOCK
    if (reset) begin
      r_output_window_counter_acc <= '0;
      r_output_window_counter_col <= '0;
      r_output_window_counter_row <= '0;
    end else if (st_output_current == WRITE_OUTPUT && r_output_write_count == OUTPUT_RW_COUNT_WIDTH'(OUTPUT_RW_COUNT_MAX)) begin
      // Advance window only after accumulating all input channels for this output window.
      r_output_window_counter_acc <= r_output_window_counter_acc + 1'b1;
      r_output_window_counter_row <= r_output_window_counter_row + 1'b1;
    end else if (st_output_current == NEXT_ROW_OUTPUT) begin
      r_output_window_counter_col <= r_output_window_counter_col + 1'b1;
      r_output_window_counter_row <= 0;
    end else if (st_output_current == ADDRESS_OUTPUT) begin
      // New output channel starts from first window
      r_output_window_counter_acc <= '0;
      r_output_window_counter_col <= '0;
      r_output_window_counter_row <= '0;
    end
  end

  // -------------------------------------------------------------------------
  // WRITE REGISTERS - r_output_read_count e r_output_write_count
  // -------------------------------------------------------------------------
  always_ff @(posedge clk or posedge reset) begin: OUTPUT_RW_COUNTER_BLOCK
    if (reset) begin
      r_output_read_count  <= 0;
      r_output_write_count <= 0;
    end else begin
      if (st_output_current == WRITE_OUTPUT) begin
        r_output_read_count <= 0;
        if (r_output_write_count < OUTPUT_RW_COUNT_WIDTH'(OUTPUT_RW_COUNT_MAX))
          r_output_write_count <= r_output_write_count + 1;
        else
          r_output_write_count <= OUTPUT_RW_COUNT_WIDTH'(OUTPUT_RW_COUNT_MAX);
      end else if (st_output_current == RESET_OUTPUT || st_output_current == READ_OUTPUT) begin
        r_output_write_count <= 0;
        if (p_output_valid) begin
          if (r_output_read_count < OUTPUT_RW_COUNT_WIDTH'(OUTPUT_RW_COUNT_MAX))
            r_output_read_count <= r_output_read_count + 1;
          else
            r_output_read_count <= OUTPUT_RW_COUNT_WIDTH'(OUTPUT_RW_COUNT_MAX);
        end
      end
    end
  end

  always_ff @(posedge clk) begin: OUTPUT_DATA_BLOCK
    if (reset) begin
      r_output_write <= '{default: '0};
      r_output_read <= '{default: '0};
    end else begin
      if (st_output_current == RESET_OUTPUT) begin
        // r_output_write <= '{default: '0};
        r_output_read <= '{default: '0};
      end else if ((st_output_current == READ_OUTPUT) && p_output_valid) begin
        r_output_read[r_output_read_count] <= p_output_data_read;
      end
      if (st_conv_current == HADAMARD &&
          r_conv_multiply_count == $bits(r_conv_multiply_count)'(STREAM_CYCLES - 1))
        r_output_write <= w_output_capture;
    end
  end

  always_ff @(posedge clk or posedge reset) begin: OUTPUT_ADDR_POINTER_BLOCK
    if (reset) begin
      r_output_addr_channel <= '0;
      r_output_addr_col <= '0;
      r_output_addr_row <= '0;
    end else begin
      // Address generation for output map:
      // - slide window every completed WRITE_OUTPUT window
      // - when one input-channel pass finishes, restart window scan at channel base
      // - when last input channel finishes, advance to next output channel base
      if (st_output_current == WRITE_OUTPUT && r_output_write_count == OUTPUT_RW_COUNT_WIDTH'(OUTPUT_RW_COUNT_MAX)) begin
        if (w_output_last_window_acc) begin
          r_output_addr_col <= '0;
          r_output_addr_row <= '0;
          if (w_output_last_channel_input && !w_output_last_channel_output)
            r_output_addr_channel <= r_output_addr_channel + OUTPUT_ADDR_CHANNEL_WIDTH'(FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE);
        end else if (w_output_last_window_row) begin
          r_output_addr_row <= '0;
          if (w_output_last_window_col)
            r_output_addr_col <= '0;
          else
            r_output_addr_col <= r_output_addr_col + OUTPUT_ADDR_COL_WIDTH'(CONV_OUTPUT_SIZE);
        end else begin
          r_output_addr_row <= r_output_addr_row + OUTPUT_ADDR_ROW_WIDTH'(FEAT_OUTPUT_SIZE * CONV_OUTPUT_SIZE);
        end
      end
      if (st_output_current == ADDRESS_OUTPUT) begin
        // New channel starts at first window position.
        r_output_addr_col <= '0;
        r_output_addr_row <= '0;
      end
    end
  end

  always_ff @(posedge clk or posedge reset) begin: OUTPUT_ADDR_OFFSET_BLOCK
    if (reset) begin
      r_output_addr_offset_read <= '0;
      r_output_addr_offset_write <= '0;
    end else begin
      if (st_output_current != READ_OUTPUT) begin
        r_output_addr_offset_read <= '0;
      end else begin
        // Prepare offset for next READ cycle without lookup table.
        if (r_output_read_count == OUTPUT_RW_COUNT_WIDTH'(OUTPUT_RW_COUNT_MAX))
          r_output_addr_offset_read <= r_output_addr_offset_read;
        else
        if ((r_output_read_count % CONV_OUTPUT_SIZE) == (CONV_OUTPUT_SIZE - 1))
          r_output_addr_offset_read <= r_output_addr_offset_read - OUTPUT_ADDR_OFFSET_WIDTH'(((CONV_OUTPUT_SIZE - 1) * FEAT_OUTPUT_SIZE) - 1);
        else
          r_output_addr_offset_read <= r_output_addr_offset_read + OUTPUT_ADDR_OFFSET_WIDTH'(FEAT_OUTPUT_SIZE);
      end

      if (st_output_current != WRITE_OUTPUT) begin
        r_output_addr_offset_write <= '0;
      end else begin
        // Prepare offset for next WRITE cycle without lookup table.
        if (r_output_write_count == OUTPUT_RW_COUNT_WIDTH'(OUTPUT_RW_COUNT_MAX))
          r_output_addr_offset_write <= r_output_addr_offset_write;
        else
        if ((r_output_write_count % CONV_OUTPUT_SIZE) == (CONV_OUTPUT_SIZE - 1))
          r_output_addr_offset_write <= r_output_addr_offset_write - OUTPUT_ADDR_OFFSET_WIDTH'(((CONV_OUTPUT_SIZE - 1) * FEAT_OUTPUT_SIZE) - 1);
        else
          r_output_addr_offset_write <= r_output_addr_offset_write + OUTPUT_ADDR_OFFSET_WIDTH'(FEAT_OUTPUT_SIZE);
      end
    end
  end

  assign w_output_addr = NADDR'(r_output_addr_channel) + NADDR'(r_output_addr_col) + NADDR'(r_output_addr_row);
  assign p_output_data_write = r_output_write[r_output_write_count] + r_output_read[r_output_write_count];
  assign p_output_addr = (st_output_current == READ_OUTPUT) ?
    (w_output_addr + NADDR'(r_output_addr_offset_read)) :
    (w_output_addr + NADDR'(r_output_addr_offset_write));  // p_input_addr mux
  // Keep read enabled through index 8 so the 9th output element is fetched.
  assign p_output_en = (((st_output_current == READ_OUTPUT) && r_output_read_count <= OUTPUT_RW_COUNT_WIDTH'(OUTPUT_RW_COUNT_MAX)) || (st_output_current == WRITE_OUTPUT)) ? '1 : '0;
  // Keep write enabled for every WRITE_OUTPUT beat, including the final window/channel.
  assign p_output_wr = (st_output_current == WRITE_OUTPUT) ? '1 : '0;

endmodule
