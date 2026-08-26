/*
   CONVOLUTION CONTROLLER - FastConv F(4x4, 3x3)
*/
`timescale 1ns / 1ps

module Conv
  #(
    parameter int unsigned N_CHANNEL_IN        = 3,
    parameter int unsigned N_CHANNEL_OUT       = 3,
    parameter int unsigned FEAT_INPUT_SIZE     = 32,
    parameter int unsigned FEAT_INPUT_WIDTH    = 32,
    parameter int unsigned NADDR               = 16,  // bits to p_input_addr the memory
    parameter int unsigned NBITS               = 20,
    parameter int unsigned QUANT               = 8,
    parameter int unsigned CONV_OUTPUT_SIZE    = 4,
    parameter int unsigned CONV_INPUT_SIZE     = 6,
    parameter int unsigned HADAMARD_SIZE       = 6,
    parameter int unsigned NUM_MULT            = 18,
    parameter int unsigned STATE_MULT          = 2
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

  function automatic int f_width_min1(input int x);
    if (x <= 1)
      f_width_min1 = 1;
    else
      f_width_min1 = $clog2(x);
  endfunction

  localparam FEAT_OUTPUT_SIZE = (FEAT_INPUT_SIZE - 2);

  logic [NBITS-1:0] r_input_feat[(CONV_INPUT_SIZE * CONV_INPUT_SIZE) - 1:0];  // input feature register bank
  logic [NBITS-1:0] w_input_feat_next[(CONV_INPUT_SIZE * CONV_INPUT_SIZE) - 1:0];  // next values for feature shift bank
  logic [NADDR-1:0] r_input_tile_base;
  logic [NADDR-1:0] r_input_addr_kernel;
  logic [(CONV_INPUT_SIZE * CONV_INPUT_SIZE) - 1:0] w_input_feat_en;  // write-enable per feature register
  logic w_input_feat_write_valid;
  logic w_input_sample_in_bounds;
  logic w_input_last_window_col;
  logic w_input_last_window_acc;
  logic w_input_last_channel_output;

  // The 4x4 Winograd tile advances four pixels.  The final row/column is
  // retained as a padded tile because 30 is not divisible by four.
  localparam WINDOW_COUNT_PER_LINE = (FEAT_OUTPUT_SIZE + CONV_OUTPUT_SIZE - 1) / CONV_OUTPUT_SIZE;
  localparam WINDOW_COUNT_PER_COLUMN = (FEAT_OUTPUT_SIZE + CONV_OUTPUT_SIZE - 1) / CONV_OUTPUT_SIZE;

  // Include the terminal count (64) in the counter width.
  localparam WINDOW_COUNTER_WIDTH = f_width_min1((WINDOW_COUNT_PER_LINE * WINDOW_COUNT_PER_COLUMN) + 1);
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
  localparam WEIGHT_WIDTH = f_width_min1(WEIGHT_CYCLES + 1);
  logic [NBITS-1:0] r_input_weight[WEIGHT_CYCLES-1:0];
  logic [WEIGHT_CYCLES-1:0] w_input_weight_en;
  logic [WEIGHT_WIDTH-1:0] r_input_count_kernel;
  logic w_input_weight_done;
  logic w_input_write_done;

  logic [NBITS-1:0] r_conv_temp [HADAMARD_SIZE*HADAMARD_SIZE-1:0];
  logic [NBITS-1:0] w_conv_transform [HADAMARD_SIZE*HADAMARD_SIZE-1:0];
  logic [NBITS-1:0] w_conv_inverse [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0];
  logic [NBITS-1:0] r_conv_input[(CONV_INPUT_SIZE * CONV_INPUT_SIZE) - 1:0];  // convolution input register bank
  logic signed [NBITS-1+QUANT:0] w_conv_product [NUM_MULT-1:0];  // QUANT more bits for the multipliers
  logic [(f_width_min1(STATE_MULT - 1) + 1)-1:0] r_conv_idx_in;
  logic [(f_width_min1((STATE_MULT * NUM_MULT) - 1) + 1)-1:0] r_conv_idx_out[NUM_MULT-1:0];
  logic w_conv_end;

  localparam OUTPUT_RW_COUNT_MAX = (CONV_OUTPUT_SIZE * CONV_OUTPUT_SIZE) - 1;
  localparam OUTPUT_RW_COUNT_WIDTH = f_width_min1(CONV_OUTPUT_SIZE * CONV_OUTPUT_SIZE);
  logic [OUTPUT_RW_COUNT_WIDTH-1:0] r_output_read_count;
  logic [OUTPUT_RW_COUNT_WIDTH-1:0] r_output_write_count;
  logic [NBITS-1:0] r_output_write [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0];
  logic [NBITS-1:0] r_output_read [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0];
  logic [NADDR-1:0] w_output_addr;
  logic w_output_pixel_in_bounds;
  logic [OUTPUT_RW_COUNT_WIDTH-1:0] w_output_element_count;

  // The generated normal-form package stores one bias/header word per
  // input/output channel pair, then all transformed weights, then the feature
  // maps. Keep these bases explicit instead of assuming feature data starts at
  // address zero.
  localparam INPUT_HEADER_SIZE = N_CHANNEL_IN * N_CHANNEL_OUT;
  localparam WEIGHT_MEMORY_BASE = INPUT_HEADER_SIZE;
  localparam FEATURE_MEMORY_BASE = INPUT_HEADER_SIZE +
                                   (N_CHANNEL_IN * N_CHANNEL_OUT * WEIGHT_CYCLES);
  logic [WINDOW_COUNTER_WIDTH-1:0] r_output_window_counter_col;
  logic [WINDOW_ROW_COUNTER_WIDTH-1:0] r_output_window_counter_row;
  logic [WINDOW_COUNTER_WIDTH-1:0] r_output_window_counter_acc;
  logic [CHANNEL_INPUT_COUNTER_WIDTH-1:0] r_output_channel_counter_input;
  logic [CHANNEL_OUTPUT_COUNTER_WIDTH-1:0] r_output_channel_counter_output;

  localparam OUTPUT_ADDR_OFFSET_WIDTH = f_width_min1((CONV_OUTPUT_SIZE * FEAT_OUTPUT_SIZE) + CONV_OUTPUT_SIZE);
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
    READ_IN_6A,
    READ_IN_6B,
    READ_IN_6C,
    READ_IN_6D,
    READ_IN_6E,
    READ_IN_6F,
    HOLD_WRITE,
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

  assign p_input_en   = (st_input_current inside {READ_WEIGHTS, READ_IN_6A, READ_IN_6B, READ_IN_6C, READ_IN_6D, READ_IN_6E, READ_IN_6F});
  assign p_input_addr = (st_input_current == READ_WEIGHTS) ? r_input_addr_kernel :
                        r_input_tile_base +
                        NADDR'(w_input_base_feat * FEAT_INPUT_WIDTH) +
                        NADDR'(r_input_addr_count);  // row-major 6x6 tile address

  // The final 6x6 tile can extend past the 32x32 feature map.  Preserve the
  // controller structure and mask only those samples, rather than allowing a
  // row-end address to alias the following row.
  assign w_input_sample_in_bounds =
      (((r_input_tile_base - NADDR'(FEATURE_MEMORY_BASE) -
         NADDR'(r_input_channel_counter_input * FEAT_INPUT_SIZE * FEAT_INPUT_WIDTH)) %
        FEAT_INPUT_WIDTH) + r_input_addr_count < FEAT_INPUT_WIDTH) &&
      (((r_input_tile_base - NADDR'(FEATURE_MEMORY_BASE) -
         NADDR'(r_input_channel_counter_input * FEAT_INPUT_SIZE * FEAT_INPUT_WIDTH)) /
        FEAT_INPUT_WIDTH) + w_input_base_feat < FEAT_INPUT_SIZE);

  always_ff @(posedge clk or posedge reset) begin: INPUT_TILE_BASE_BLOCK
    if (reset)
      r_input_tile_base <= NADDR'(FEATURE_MEMORY_BASE);
    else if (st_input_current == ADDRESS_INPUT && w_input_last_window_acc) begin
      if (r_input_channel_counter_input == CHANNEL_INPUT_COUNTER_WIDTH'(N_CHANNEL_IN - 1))
        r_input_tile_base <= NADDR'(FEATURE_MEMORY_BASE);
      else
        r_input_tile_base <= NADDR'(FEATURE_MEMORY_BASE) +
                             NADDR'((r_input_channel_counter_input + 1) *
                                    FEAT_INPUT_SIZE * FEAT_INPUT_WIDTH);
    end else if (st_input_current == TRANSFER) begin
      // The counter still denotes the tile being transferred at this edge.
      // The last tile of a row is therefore WINDOW_COUNT_PER_LINE-1;
      // w_input_last_window_col becomes true only after the counter update.
      if (r_input_window_counter_col == WINDOW_ROW_COUNTER_WIDTH'(WINDOW_COUNT_PER_LINE - 1))
        r_input_tile_base <= r_input_tile_base +
                             NADDR'(CONV_OUTPUT_SIZE * FEAT_INPUT_WIDTH) -
                             NADDR'(CONV_OUTPUT_SIZE * (WINDOW_COUNT_PER_LINE - 1));
      else
        r_input_tile_base <= r_input_tile_base + NADDR'(CONV_OUTPUT_SIZE);
    end
  end

  always_ff @(posedge clk or posedge reset) begin: WEIGHT_ADDR_POINTER_BLOCK
    if (reset)
      r_input_addr_kernel <= 0;
    else if (st_input_current == WAIT_INPUT && st_input_next == ADDRESS_INPUT)
      r_input_addr_kernel <= NADDR'(WEIGHT_MEMORY_BASE);
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
        if (w_input_weight_done) st_input_next = READ_IN_6A;
        else if (w_input_last_channel_output) st_input_next = WAIT_INPUT;  //end processing
      READ_IN_6A: if (r_input_addr_count == (CONV_INPUT_SIZE - 1)) st_input_next = READ_IN_6B;  // read one complete 6x6 tile row
      READ_IN_6B: if (r_input_addr_count == (CONV_INPUT_SIZE - 1)) st_input_next = READ_IN_6C;
      READ_IN_6C: if (r_input_addr_count == (CONV_INPUT_SIZE - 1)) st_input_next = READ_IN_6D;
      READ_IN_6D: if (r_input_addr_count == (CONV_INPUT_SIZE - 1)) st_input_next = READ_IN_6E;
      READ_IN_6E: if (r_input_addr_count == (CONV_INPUT_SIZE - 1)) st_input_next = READ_IN_6F;
      READ_IN_6F: if (r_input_addr_count == (CONV_INPUT_SIZE - 1)) st_input_next = CONV_INPUT;
      CONV_INPUT: st_input_next = TRANSFER;
      TRANSFER: st_input_next = HOLD_WRITE;  // p_start the convolution
      HOLD_WRITE:
        if (w_input_last_window_col && w_input_write_done) st_input_next = NEXT_ROW_INPUT;
          else if (w_input_write_done) st_input_next = READ_IN_6A;
        else st_input_next = HOLD_WRITE;
      NEXT_ROW_INPUT:
        if (w_input_last_window_acc) st_input_next = ADDRESS_INPUT;
        else st_input_next = READ_IN_6A;
      default: st_input_next = WAIT_INPUT;
    endcase
  end

  assign w_input_weight_done = (r_input_count_kernel == WEIGHT_WIDTH'(WEIGHT_CYCLES - 1));
  assign w_input_write_done = r_output_write_count == 0 || r_output_write_count == OUTPUT_RW_COUNT_MAX;  // compare to zero for the first write test or the last value (8) in the next convolutions

  assign w_input_last_window_col = (r_input_window_counter_col == WINDOW_ROW_COUNTER_WIDTH'(WINDOW_COUNT_PER_LINE));
  assign w_input_last_window_acc = (r_input_window_counter_acc == WINDOW_COUNTER_WIDTH'(WINDOW_COUNT_PER_LINE * WINDOW_COUNT_PER_COLUMN));
  assign w_input_last_channel_output = (r_input_channel_counter_output == CHANNEL_OUTPUT_COUNTER_WIDTH'(N_CHANNEL_OUT));

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
      else if (st_input_current inside {READ_IN_6A, READ_IN_6B, READ_IN_6C, READ_IN_6D, READ_IN_6E, READ_IN_6F}) begin
        if (r_input_addr_count == (CONV_INPUT_SIZE - 1))
          r_input_addr_count <= 0;
        else
          r_input_addr_count <= r_input_addr_count + 1;
      end
    end
  end

  assign w_input_base_feat = (st_input_current == READ_IN_6A) ? 0 :
                             (st_input_current == READ_IN_6B) ? 1 :
                             (st_input_current == READ_IN_6C) ? 2 :
                             (st_input_current == READ_IN_6D) ? 3 :
                             (st_input_current == READ_IN_6E) ? 4 :
                             (st_input_current == READ_IN_6F) ? 5 : 0;


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
    for (int unsigned i = 0; i < (CONV_INPUT_SIZE * CONV_INPUT_SIZE); i++)
      w_input_feat_next[i] = w_input_sample_in_bounds ? p_input_data : '0;

    // During TRANSFER retain the rightmost two columns for the next 6x6 tile.
    // Read states write complete rows; the transfer only shifts columns 4/5
    // into columns 0/1 before the next four rows are fetched.
    if (st_input_current == TRANSFER) begin
      w_input_feat_next[0]  = r_input_feat[4];
      w_input_feat_next[1]  = r_input_feat[5];
      w_input_feat_next[6]  = r_input_feat[10];
      w_input_feat_next[7]  = r_input_feat[11];
      w_input_feat_next[12] = r_input_feat[16];
      w_input_feat_next[13] = r_input_feat[17];
      w_input_feat_next[18] = r_input_feat[22];
      w_input_feat_next[19] = r_input_feat[23];
      w_input_feat_next[24] = r_input_feat[28];
      w_input_feat_next[25] = r_input_feat[29];
      w_input_feat_next[30] = r_input_feat[34];
      w_input_feat_next[31] = r_input_feat[35];
    end
  end

  // The ROM is row-major: each read state supplies one complete row of the
  // 6x6 tile, so samples are written contiguously in the feature bank.
  assign w_input_feat_wr_index =
      INPUT_FEAT_INDEX_WIDTH'(w_input_base_feat * CONV_INPUT_SIZE) +
      INPUT_FEAT_INDEX_WIDTH'(r_input_addr_count);

  always_comb begin: INPUT_SHIFT_WE_BLOCK  // 'w_input_feat_en' to write into the register bank r_input_feat
    w_input_feat_en = '0;
    case (st_input_current)
      READ_IN_6A, READ_IN_6B, READ_IN_6C, READ_IN_6D, READ_IN_6E, READ_IN_6F:
        w_input_feat_en[w_input_feat_wr_index] = 1'b1;
      TRANSFER:
        w_input_feat_en = 36'b001100110011001100110011001100110011;  // make the shift
      default:
        w_input_feat_en = '0;
    endcase
  end

  assign w_input_feat_write_valid = (st_input_current == TRANSFER) || p_input_valid;

  always_ff @(posedge clk or posedge reset) begin: INPUT_FEATURE_REG_BLOCK  // initializes and write into the register bank and convolution register bank
    if (reset)
      for (int unsigned i = 0; i < (CONV_INPUT_SIZE * CONV_INPUT_SIZE); i++)
        r_input_feat[i] <= '0;
    else
      for (int unsigned i = 0; i < (CONV_INPUT_SIZE * CONV_INPUT_SIZE); i++)
        if (w_input_feat_en[i] && w_input_feat_write_valid)
          r_input_feat[i] <= w_input_feat_next[i];
  end

  // Weight register bank with per-entry write-enable.
  always_comb begin: WEIGHT_WE_BLOCK
    w_input_weight_en = '0;
    if (st_input_current == READ_WEIGHTS)
      w_input_weight_en[r_input_count_kernel] = 1'b1;
  end

  always_ff @(posedge clk or posedge reset) begin: WEIGHT_REG_BLOCK
    if (reset) begin
      for (int unsigned i = 0; i < WEIGHT_CYCLES; i++)
        r_input_weight[i] <= '0;
    end else if (st_input_current == READ_WEIGHTS) begin
      // A new weight load has priority over the final HADAMARD rotation of
      // the preceding window; both FSMs can overlap for one cycle.
      for (int unsigned i = 0; i < WEIGHT_CYCLES; i++)
        if (w_input_weight_en[i])
          r_input_weight[i] <= p_input_data;
    end else if (st_conv_current == HADAMARD) begin         // transform weights into a circular queue
      for (int unsigned i = 0; i < (WEIGHT_CYCLES-NUM_MULT); i++) begin
        r_input_weight[i] <= r_input_weight[i + NUM_MULT];
      end
      for (int unsigned i = (WEIGHT_CYCLES-NUM_MULT); i < WEIGHT_CYCLES; i++) begin
        r_input_weight[i] <= r_input_weight[i - (WEIGHT_CYCLES-NUM_MULT)];
      end
    end else begin
      for (int unsigned i = 0; i < WEIGHT_CYCLES; i++)
        if (w_input_weight_en[i])
          r_input_weight[i] <= p_input_data;
    end
  end

  // ----------------------------------------------------------------------------------------------------
  // -------  PART 3 - CONVOLUTION CONTROL AND CONVOLUTION MODULES --------------------------------------
  // ----------------------------------------------------------------------------------------------------
  logic [(f_width_min1(STATE_MULT + 1))-1:0] r_conv_multiply_count;

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
        if (r_conv_multiply_count == $bits(r_conv_multiply_count)'(STATE_MULT - 1)) begin
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
  // Snapshot each completed tile before the input loader starts overwriting
  // r_input_feat for the next tile.  The transform/multiply pipeline overlaps
  // input loading, so driving it directly from r_input_feat would corrupt an
  // in-flight convolution halfway through its four Hadamard cycles.
  always_ff @(posedge clk or posedge reset) begin: CONV_INPUT_REG_BLOCK
    if (reset)
      r_conv_input <= '{default: '0};
    else if (st_input_current == CONV_INPUT)
      r_conv_input <= r_input_feat;
  end

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

  always_ff @(posedge clk) begin: CONV_DATAPATH_BLOCK
    if (reset) begin
      r_conv_temp <= '{default: '0};
    end else begin
      unique case (st_conv_current)
        TRANSFORM:
          r_conv_temp <= w_conv_transform;
        HADAMARD: begin      // shift the accumulator and append the multiplier products
          for (int unsigned i = 0; i < (WEIGHT_CYCLES-NUM_MULT); i++)
            r_conv_temp[i] <= r_conv_temp[i + NUM_MULT];
          for (int unsigned i = (WEIGHT_CYCLES-NUM_MULT); i < WEIGHT_CYCLES; i++)
            r_conv_temp[i] <= w_conv_product[i - (WEIGHT_CYCLES-NUM_MULT)];
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
      // .pin (r_conv_input[C1_SIZE*C1_SIZE-1:0]),
      .pin (r_conv_input),
      .pout(w_conv_transform)
  );

  MuxMult mux_mult(
    .idx_in(r_conv_idx_in),
    .idx_out(r_conv_idx_out)
  );

  generate
    for (genvar i = 0; i < NUM_MULT; i++) begin : MULTIP_BLOCK    /// only the first 6 indices
      Multip #(
        .QUANT(QUANT),
        .NBITS(NBITS)
      )
      multip(
        .feature(r_conv_temp[i]),
        .weight(r_input_weight[i]),
        .product(w_conv_product[i])
      );
    end
  endgenerate

  // Instance of matrix multiplier "A"
  Inverse #(
    .NBITS(NBITS),
    .CONV_OUTPUT_SIZE(CONV_OUTPUT_SIZE),
    .CONV_INPUT_SIZE(CONV_INPUT_SIZE),
    .HADAMARD_SIZE(HADAMARD_SIZE)
  ) inv (
      .pin (r_conv_temp),
      .pout(w_conv_inverse)
  );


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
          st_output_next = WRITE_OUTPUT;
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
    end else if (st_output_current == WRITE_OUTPUT &&
                 r_output_write_count == OUTPUT_RW_COUNT_WIDTH'(OUTPUT_RW_COUNT_MAX)) begin
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
      if (w_conv_end)
        r_output_write <= w_conv_inverse;
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
      if (st_output_current == WRITE_OUTPUT &&
          r_output_write_count == OUTPUT_RW_COUNT_WIDTH'(OUTPUT_RW_COUNT_MAX)) begin
        if (w_output_last_window_acc) begin
          r_output_addr_col <= '0;
          r_output_addr_row <= '0;
          if (w_output_last_channel_input && !w_output_last_channel_output)
            r_output_addr_channel <= r_output_addr_channel + OUTPUT_ADDR_CHANNEL_WIDTH'(FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE);
        end else if (w_output_last_window_row) begin
          // The input traversal is horizontal-tile first. Advance to the
          // next output row only after the 15 tiles in the current row.
          r_output_addr_col <= '0;
          if (w_output_last_window_col)
            r_output_addr_row <= '0;
          else
            r_output_addr_row <= r_output_addr_row + OUTPUT_ADDR_ROW_WIDTH'(CONV_OUTPUT_SIZE);
        end else begin
          r_output_addr_col <= r_output_addr_col + OUTPUT_ADDR_COL_WIDTH'(CONV_OUTPUT_SIZE);
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
        if (r_output_read_count == 0 ||
            r_output_read_count == OUTPUT_RW_COUNT_WIDTH'(OUTPUT_RW_COUNT_MAX - 1))
          r_output_addr_offset_read <= r_output_addr_offset_read + OUTPUT_ADDR_OFFSET_WIDTH'(1);
        else
          r_output_addr_offset_read <= r_output_addr_offset_read +
                                       OUTPUT_ADDR_OFFSET_WIDTH'(FEAT_OUTPUT_SIZE - 1);
      end

      if (st_output_current != WRITE_OUTPUT) begin
        r_output_addr_offset_write <= '0;
      end else begin
        // Prepare offset for next WRITE cycle without lookup table.
        if (r_output_write_count == OUTPUT_RW_COUNT_WIDTH'(OUTPUT_RW_COUNT_MAX))
          r_output_addr_offset_write <= r_output_addr_offset_write;
        else
        if (r_output_write_count == 0 ||
            r_output_write_count == OUTPUT_RW_COUNT_WIDTH'(OUTPUT_RW_COUNT_MAX - 1))
          r_output_addr_offset_write <= r_output_addr_offset_write + OUTPUT_ADDR_OFFSET_WIDTH'(1);
        else
          r_output_addr_offset_write <= r_output_addr_offset_write +
                                        OUTPUT_ADDR_OFFSET_WIDTH'(FEAT_OUTPUT_SIZE - 1);
      end
    end
  end

  // The output counters describe the current tile row/column.  Generate the
  // row-major address directly from the local 4x4 output index.  Invalid lanes
  // in the padded border remain readable as zero but are not written.
  assign w_output_addr =
      NADDR'(r_output_channel_counter_output * FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE) +
      NADDR'(r_output_window_counter_col * CONV_OUTPUT_SIZE * FEAT_OUTPUT_SIZE) +
      NADDR'(r_output_window_counter_row * CONV_OUTPUT_SIZE);

  assign w_output_element_count = (st_output_current == READ_OUTPUT) ?
                                  r_output_read_count : r_output_write_count;

  assign w_output_pixel_in_bounds =
      ((r_output_window_counter_col * CONV_OUTPUT_SIZE) +
       (w_output_element_count / CONV_OUTPUT_SIZE) < FEAT_OUTPUT_SIZE) &&
      ((r_output_window_counter_row * CONV_OUTPUT_SIZE) +
       (w_output_element_count % CONV_OUTPUT_SIZE) < FEAT_OUTPUT_SIZE);

  assign p_output_data_write = r_output_write[r_output_write_count] +
                               r_output_read[r_output_write_count];
  assign p_output_addr = w_output_pixel_in_bounds ?
      (w_output_addr + NADDR'((w_output_element_count / CONV_OUTPUT_SIZE) * FEAT_OUTPUT_SIZE +
                              (w_output_element_count % CONV_OUTPUT_SIZE))) : '0;
  assign p_output_en = (st_output_current == READ_OUTPUT) ||
                       ((st_output_current == WRITE_OUTPUT) && w_output_pixel_in_bounds);
  assign p_output_wr = (st_output_current == WRITE_OUTPUT) && w_output_pixel_in_bounds;

endmodule
