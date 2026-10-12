/*
   WPN16 streaming column convolution with transformed integer weights,
   a complete feature-transform register bank, and a Hadamard/inverse barrier.

   Algorithm: wpn16   input tile 6x6   Hadamard 8x8   output tile 4x4
   This is the WPN16 integer-weight counterpart of the TCN16 transformed-frac6
   column architecture. The canonical package supplies the 8x8 transformed
   integer weights; no fractional weight bits or wide-weight multiplier are used.
*/
`timescale 1ns / 1ps

module Conv
  #(
    parameter int unsigned N_CHANNEL_IN        = 3,
    parameter int unsigned N_CHANNEL_OUT       = 3,
    parameter int unsigned FEAT_INPUT_SIZE     = 32,
    parameter int unsigned FEAT_INPUT_WIDTH    = 32,
    parameter int unsigned NADDR               = 16,  // bits to p_input_addr the memory
    parameter int unsigned NBITS               = 16,
    parameter int unsigned QUANT               = 8,
    parameter int unsigned CONV_OUTPUT_SIZE    = 4,
    parameter int unsigned CONV_KERNEL_SIZE    = 3,
    parameter int unsigned CONV_INPUT_SIZE     = 6,
    parameter int unsigned HADAMARD_SIZE       = 8,
    // Number of parallel multipliers; must be a whole number of Hadamard rows.
    parameter int unsigned NUM_MULT            = 32
  ) (
    input  logic clk,
    input  logic reset,
    input  logic p_start,
    output logic p_end,

    output logic p_input_en,                       // Enables a read operation on the input RAM
    output logic [NADDR-1:0] p_input_addr,
    input  logic [CONV_INPUT_SIZE*NBITS-1:0] p_input_data,
    input  logic p_input_valid,                    // Read-valid flag from the input RAM

    output logic p_output_en,                      // Enables access to the output RAM port
    output logic p_output_wr,                      // Write strobe for the output RAM port
    output logic [NADDR-1:0] p_output_addr,        // Address issued to the output RAM
    output logic [CONV_OUTPUT_SIZE*NBITS-1:0] p_output_data_write,  // One output column per write beat
    input  logic [CONV_OUTPUT_SIZE*NBITS-1:0] p_output_data_read,   // One output column per read beat
    input  logic p_output_valid                    // Read-valid flag from the output RAM
  );

  localparam int unsigned FIXED_NUM_MULT = NUM_MULT;
  localparam int unsigned ROWS_PER_CYCLE = FIXED_NUM_MULT / HADAMARD_SIZE;

  // Elaboration checks for the fixed geometry of this streaming variant.
  if ((NUM_MULT < HADAMARD_SIZE) || ((NUM_MULT % HADAMARD_SIZE) != 0) ||
      (((HADAMARD_SIZE * HADAMARD_SIZE) % NUM_MULT) != 0)) begin: NUM_MULT_CHECK
    $error("NUM_MULT (%0d) must be a positive whole number of Hadamard rows", NUM_MULT);
  end
  if (CONV_INPUT_SIZE != CONV_OUTPUT_SIZE + CONV_KERNEL_SIZE - 1) begin: TILE_GEOMETRY_CHECK
    $error("CONV_INPUT_SIZE (%0d) must equal CONV_OUTPUT_SIZE + CONV_KERNEL_SIZE - 1", CONV_INPUT_SIZE);
  end

  function automatic int f_width_min1(input int x);
    if (x <= 1)
      f_width_min1 = 1;
    else
      f_width_min1 = $clog2(x);
  endfunction

  // Feature tile: bank index is lane*CONV_INPUT_SIZE + beat, where a beat is one
  // input-memory column transfer and a lane is one word of that beat.
  localparam int unsigned TILE_WORDS = CONV_INPUT_SIZE * CONV_INPUT_SIZE;
  // Consecutive windows share KEEP_COLUMNS columns and fetch NEW_COLUMNS new ones.
  localparam int unsigned KEEP_COLUMNS = CONV_KERNEL_SIZE - 1;
  localparam int unsigned NEW_COLUMNS = CONV_OUTPUT_SIZE;
  localparam int unsigned BEAT_COUNT_WIDTH = f_width_min1(CONV_INPUT_SIZE);

  logic [NBITS-1:0] r_input_feat[TILE_WORDS - 1:0];  // input feature register bank
  logic [NBITS-1:0] w_input_feat_next[TILE_WORDS - 1:0];  // next values for feature shift bank
  logic [NADDR-1:0] r_input_addr_feat;
  logic [NADDR-1:0] r_input_addr_kernel;
  logic [NADDR-1:0] r_input_window_next;
  logic [TILE_WORDS - 1:0] w_input_feat_en;  // write-enable per feature register
  logic w_input_feat_write_valid;
  // Prefetch bank for the NEW_COLUMNS columns of the next tile.
  localparam int unsigned PREFETCH_WORDS = NEW_COLUMNS * CONV_INPUT_SIZE;
  logic [NBITS-1:0] r_input_prefetch[PREFETCH_WORDS-1:0];
  logic r_input_prefetch_full;
  logic r_input_prefetch_active;
  logic r_input_prefetch_enabled;
  logic [NADDR-1:0] r_input_prefetch_addr;
  // Column beat index inside the prefetch bank.
  localparam int unsigned PREFETCH_PHASE_WIDTH = f_width_min1(NEW_COLUMNS);
  logic [PREFETCH_PHASE_WIDTH-1:0] r_input_prefetch_phase;
  logic w_input_prefetch_commit;
  logic r_stream_transfer_pending;
  logic w_input_feature_shift;
  logic w_input_prefetch_mode;
  logic w_input_last_window_col;
  logic w_input_last_window_acc;
  logic w_input_last_channel;
  logic w_input_last_output_channel;
  logic w_input_job_complete;
  logic w_input_read_weights;  // debug/testbench visibility of the weight-read state

  localparam WINDOW_COUNT_PER_LINE = (FEAT_INPUT_SIZE - 2 + CONV_OUTPUT_SIZE - 1) / CONV_OUTPUT_SIZE;
  localparam WINDOW_COUNT_PER_COLUMN = (FEAT_INPUT_SIZE - 2 + CONV_OUTPUT_SIZE - 1) / CONV_OUTPUT_SIZE;

  // Input-window progress reaches the terminal count itself (0..TOTAL_WINDOWS),
  // so reserve a representable bit even when TOTAL_WINDOWS is a power of two.
  localparam WINDOW_COUNTER_WIDTH =
      f_width_min1((WINDOW_COUNT_PER_LINE * WINDOW_COUNT_PER_COLUMN) + 1);
  logic [WINDOW_COUNTER_WIDTH-1:0] r_input_window_counter_acc;

  localparam WINDOW_ROW_COUNTER_WIDTH = f_width_min1(WINDOW_COUNT_PER_LINE + 1);
  logic [WINDOW_ROW_COUNTER_WIDTH-1:0] r_input_window_counter_col;

  // Column beat currently written into the feature bank.
  logic [BEAT_COUNT_WIDTH-1:0] r_input_beat;

  localparam CHANNEL_INPUT_COUNTER_WIDTH = f_width_min1(N_CHANNEL_IN + 1);
  logic [CHANNEL_INPUT_COUNTER_WIDTH-1:0] r_input_channel_counter_input;

  localparam CHANNEL_OUTPUT_COUNTER_WIDTH = f_width_min1(N_CHANNEL_OUT + 1);
  logic [CHANNEL_OUTPUT_COUNTER_WIDTH-1:0] r_input_channel_counter_output;

  // REGISTER BANK FOR THE WEIGHTS ////////////////////////////////////////////
  localparam WEIGHT_CYCLES = HADAMARD_SIZE * HADAMARD_SIZE;
  // The canonical WPN16 package stores each truncated 8x8 transformed kernel
  // after the feature maps. The six-word column port needs eleven beats; the last
  // beat contains two padding words that are ignored.
  localparam int PRETRANSFORMED_WEIGHT_WORDS = HADAMARD_SIZE * HADAMARD_SIZE;
  localparam int PRETRANSFORMED_WEIGHT_COUNT_WIDTH =
      f_width_min1(PRETRANSFORMED_WEIGHT_WORDS + CONV_INPUT_SIZE);
  localparam int WEIGHT_READ_BEATS =
      (PRETRANSFORMED_WEIGHT_WORDS + CONV_INPUT_SIZE - 1) / CONV_INPUT_SIZE;
  localparam int WEIGHT_LAST_BEAT_OFFSET = (WEIGHT_READ_BEATS - 1) * CONV_INPUT_SIZE;
  localparam int PRETRANSFORMED_WEIGHT_BASE =
      N_CHANNEL_IN * FEAT_INPUT_SIZE * FEAT_INPUT_WIDTH;
  // Process ROWS_PER_CYCLE Hadamard rows in parallel per streaming cycle.
  localparam STREAM_CYCLES = WEIGHT_CYCLES / FIXED_NUM_MULT;
  logic [(f_width_min1(STREAM_CYCLES + 1))-1:0] r_conv_multiply_count;
  // Cache the complete pretransformed 8x8 kernel, then select the rows needed
  // by each batch of MAC lanes. No weight-transform datapath is instantiated.
  logic signed [NBITS-1:0] r_weight_pretransformed[PRETRANSFORMED_WEIGHT_WORDS-1:0];
  localparam WEIGHT_ROW_COUNT_WIDTH = PRETRANSFORMED_WEIGHT_COUNT_WIDTH;
  logic [WEIGHT_ROW_COUNT_WIDTH-1:0] r_weight_row_count;
  logic r_weight_tile_valid;
  logic [NADDR-1:0] r_input_addr_kernel_base;
  logic w_input_write_done;

  logic [NBITS-1:0] w_conv_transform [HADAMARD_SIZE*HADAMARD_SIZE-1:0];
  logic signed [NBITS-1:0] w_conv_product [FIXED_NUM_MULT-1:0];
  logic w_conv_end;
  logic w_conv_input_release;

  // WPN16 transforms the 6x6 input tile into a full 8x8 Hadamard feature tile.
  logic [NBITS-1:0] r_transform_feature_reg [WEIGHT_CYCLES-1:0];
  // Store the complete 8x8 Hadamard matrix over the two 32-MAC cycles.
  logic [NBITS-1:0] r_hadamard_product_reg [WEIGHT_CYCLES-1:0];
  logic [NBITS-1:0] w_inverse_transform [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0];
  logic [NBITS-1:0] w_output_acc_next [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0];
  logic [NBITS-1:0] w_hadamard_product_current [FIXED_NUM_MULT-1:0];
  logic [NBITS-1:0] w_transform_feature [FIXED_NUM_MULT-1:0];

  localparam OUTPUT_RW_COUNT_MAX = CONV_OUTPUT_SIZE - 1;
  localparam OUTPUT_RW_COUNT_WIDTH = f_width_min1(CONV_OUTPUT_SIZE);
  logic [OUTPUT_RW_COUNT_WIDTH-1:0] r_output_read_count;
  logic [OUTPUT_RW_COUNT_WIDTH-1:0] r_output_write_count;
  logic [NBITS-1:0] r_output_write [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0];
  logic [NBITS-1:0] r_output_read [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0];
  logic [NADDR-1:0] w_output_addr;

  localparam FEAT_OUTPUT_SIZE = (FEAT_INPUT_SIZE - 2);
  // The output memory is laid out on a physical grid made of whole windows, so
  // the last window never wraps into the next row; the logical map is the
  // FEAT_OUTPUT_SIZE x FEAT_OUTPUT_SIZE corner of that grid.
  localparam OUTPUT_PHYSICAL_SIZE = WINDOW_COUNT_PER_LINE * CONV_OUTPUT_SIZE;
  logic [WINDOW_COUNTER_WIDTH-1:0] r_output_window_counter_col;
  logic [WINDOW_ROW_COUNTER_WIDTH-1:0] r_output_window_counter_row;
  logic [WINDOW_COUNTER_WIDTH-1:0] r_output_window_counter_acc;
  logic [CHANNEL_INPUT_COUNTER_WIDTH-1:0] r_output_channel_counter_input;
  logic [CHANNEL_OUTPUT_COUNTER_WIDTH-1:0] r_output_channel_counter_output;

  localparam OUTPUT_ADDR_OFFSET_WIDTH =
      f_width_min1((CONV_OUTPUT_SIZE * OUTPUT_PHYSICAL_SIZE) + CONV_OUTPUT_SIZE);
  logic [OUTPUT_ADDR_OFFSET_WIDTH-1:0] r_output_addr_offset_read;
  logic [OUTPUT_ADDR_OFFSET_WIDTH-1:0] r_output_addr_offset_write;

  localparam OUTPUT_ADDR_CHANNEL_WIDTH = f_width_min1(N_CHANNEL_OUT * OUTPUT_PHYSICAL_SIZE * OUTPUT_PHYSICAL_SIZE);
  logic [OUTPUT_ADDR_CHANNEL_WIDTH-1:0] r_output_addr_channel;

  localparam OUTPUT_ADDR_COL_WIDTH = f_width_min1(OUTPUT_PHYSICAL_SIZE);
  logic [OUTPUT_ADDR_COL_WIDTH-1:0] r_output_addr_col;

  localparam OUTPUT_ADDR_ROW_WIDTH = f_width_min1(OUTPUT_PHYSICAL_SIZE * OUTPUT_PHYSICAL_SIZE);
  logic [OUTPUT_ADDR_ROW_WIDTH-1:0] r_output_addr_row;

  logic w_output_last_window_row;
  logic w_output_last_window_col;
  logic w_output_last_channel_input;
  logic w_output_last_channel_output;
  logic w_output_job_complete;
  logic w_output_last_window_acc;


  // -------------------------------------------------------------------------
  // FSM STATES DECLARION
  // -------------------------------------------------------------------------
  // READ_WEIGHTS must keep encoding 2: the shared testbenches decode it.
  typedef enum logic [3:0] {
    WAIT_INPUT,
    ADDRESS_INPUT,
    READ_WEIGHTS,
    READ_IN,
    HOLD_WRITE,
    CONV_INPUT,
    TRANSFER,
    NEXT_ROW_INPUT
  } type_st_input;
  type_st_input st_input_current;
  type_st_input st_input_next;

  typedef enum logic [2:0] {
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

  assign w_input_read_weights = (st_input_current == READ_WEIGHTS);

  // ----------------------------------------------------------------------------------------------------
  // -------  PART 1 - ADDRESS TO ACCESS THE IFMAP AND WEIGHT MEMORY ------------------------------------
  // ----------------------------------------------------------------------------------------------------

  assign p_input_en = r_input_prefetch_active ||
                      (st_input_current inside {READ_WEIGHTS, READ_IN});
  assign p_input_addr = r_input_prefetch_active
                      ? r_input_prefetch_addr
                      : (st_input_current == READ_WEIGHTS)
                      ? r_input_addr_kernel
                      : r_input_addr_feat;  // One input-column address per beat.

  // r_input_addr_feat always points at the last column already loaded for the
  // current tile.  The next window starts one column after it (TRANSFER) and
  // fetches NEW_COLUMNS columns, either directly (READ_IN) or from the prefetch
  // bank (commit), so the pointer moves NEW_COLUMNS columns per window.
  always_ff @(posedge clk or posedge reset) begin: INPUT_ADDR_POINTER_BLOCK
    if (reset) begin
      r_input_addr_feat <= '0;
      r_input_window_next <= CONV_OUTPUT_SIZE;
    end
    else if ((st_input_current == READ_IN && p_input_valid && r_input_beat != BEAT_COUNT_WIDTH'(CONV_INPUT_SIZE - 1)))
      r_input_addr_feat <= r_input_addr_feat + NADDR'(FEAT_INPUT_WIDTH);    // next column beat inside a tile load
    else if (st_input_current == HOLD_WRITE && st_input_next == CONV_INPUT && w_input_prefetch_commit)
      r_input_addr_feat <= r_input_addr_feat + NADDR'((NEW_COLUMNS - 1) * FEAT_INPUT_WIDTH);  // remaining prefetched columns
    else if (st_input_current == TRANSFER)
      r_input_addr_feat <= r_input_addr_feat + NADDR'(FEAT_INPUT_WIDTH);    // first column of the next window
    else if (st_input_current == NEXT_ROW_INPUT && !w_input_last_window_acc) begin  // when change the line, the read pointer moves 'r_input_window_next'
      r_input_addr_feat <= r_input_window_next + NADDR'(r_input_channel_counter_input * FEAT_INPUT_SIZE * FEAT_INPUT_WIDTH);  // restart for the first line
      r_input_window_next <= r_input_window_next + CONV_OUTPUT_SIZE;
    end else if (st_input_current == ADDRESS_INPUT && w_input_last_window_acc) begin
      r_input_window_next <= CONV_OUTPUT_SIZE;

      if (st_input_next != WAIT_INPUT) begin
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
  end

  always_ff @(posedge clk or posedge reset) begin: WEIGHT_ADDR_POINTER_BLOCK
    if (reset) begin
      r_input_addr_kernel <= '0;
      r_input_addr_kernel_base <= '0;
    end else if (st_input_current == WAIT_INPUT && st_input_next == ADDRESS_INPUT) begin
      // The first weight tile starts immediately after all input feature maps.
      r_input_addr_kernel <= NADDR'(PRETRANSFORMED_WEIGHT_BASE);
      r_input_addr_kernel_base <= NADDR'(PRETRANSFORMED_WEIGHT_BASE);
    end else if (st_input_current == ADDRESS_INPUT && st_input_next != WAIT_INPUT &&
                 !((r_input_channel_counter_input == '1) && (r_input_channel_counter_output == '0))) begin
      // Advance to the next input/output-channel weight tile.  A tile is
      // revisited for every spatial window, so keep its base address separate.
      r_input_addr_kernel_base <= r_input_addr_kernel_base + NADDR'(PRETRANSFORMED_WEIGHT_WORDS);
      r_input_addr_kernel <= r_input_addr_kernel_base + NADDR'(PRETRANSFORMED_WEIGHT_WORDS);
    end else if (st_input_current == HOLD_WRITE && st_input_next == READ_WEIGHTS) begin
      // Restart at the first beat of the pretransformed 8x8 kernel.
      r_input_addr_kernel <= r_input_addr_kernel_base;
    end else if (st_input_current == READ_WEIGHTS) begin
      r_input_addr_kernel <= r_input_addr_kernel + NADDR'(CONV_INPUT_SIZE);
    end
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
      ADDRESS_INPUT:
        if (w_input_job_complete) st_input_next = WAIT_INPUT;
        else st_input_next = READ_IN;
      READ_WEIGHTS:
        if (r_weight_row_count == WEIGHT_ROW_COUNT_WIDTH'(WEIGHT_LAST_BEAT_OFFSET)) st_input_next = HOLD_WRITE;
      // Load one column beat per valid read; the last beat completes the tile.
      READ_IN: if (p_input_valid && (r_input_beat == BEAT_COUNT_WIDTH'(CONV_INPUT_SIZE - 1)))
                 st_input_next = CONV_INPUT;
      CONV_INPUT: if ((st_conv_current == WAIT_CONV) && (st_output_next != WRITE_OUTPUT))
                    st_input_next = TRANSFER;
      TRANSFER: st_input_next = HOLD_WRITE;  // p_start the convolution
      HOLD_WRITE:
        if ((st_conv_current == TRANSFORM) && !r_weight_tile_valid)
          st_input_next = READ_WEIGHTS;
        else if ((w_conv_input_release || w_conv_end) && w_input_last_window_col && w_input_write_done) st_input_next = NEXT_ROW_INPUT;
          else if (!w_input_last_window_col && w_input_write_done) begin
            // The direct path must wait for the same release boundary as the
            // legacy stream-shift.  Otherwise READ_IN overwrites a column
            // before it can be copied into the shared leftmost columns.
            if (!w_input_prefetch_mode && !w_conv_input_release)
              st_input_next = HOLD_WRITE;
            else if (w_input_prefetch_mode && r_input_prefetch_full && w_input_prefetch_commit)
              st_input_next = CONV_INPUT;
            else if (w_input_prefetch_mode)
              st_input_next = HOLD_WRITE;
            else
              st_input_next = READ_IN;
          end
        else st_input_next = HOLD_WRITE;
      NEXT_ROW_INPUT:
        if (w_input_last_window_acc) st_input_next = ADDRESS_INPUT;
        else st_input_next = READ_IN;
      default: st_input_next = WAIT_INPUT;
    endcase
  end

  assign w_input_write_done = r_output_write_count == 0 || r_output_write_count == OUTPUT_RW_COUNT_MAX;  // compare to zero for the first write test or the last value in the next convolutions

  assign w_input_last_window_col = (r_input_window_counter_col == WINDOW_ROW_COUNTER_WIDTH'(WINDOW_COUNT_PER_LINE));
  assign w_input_last_window_acc = (r_input_window_counter_acc == WINDOW_COUNTER_WIDTH'(WINDOW_COUNT_PER_LINE * WINDOW_COUNT_PER_COLUMN));
  assign w_input_last_channel =
      (r_input_channel_counter_input == CHANNEL_INPUT_COUNTER_WIDTH'(N_CHANNEL_IN - 1));
  assign w_input_last_output_channel =
      (r_input_channel_counter_output == CHANNEL_OUTPUT_COUNTER_WIDTH'(N_CHANNEL_OUT - 1));
  // ADDRESS_INPUT is reached after the final spatial window of each input
  // channel. Stop at the boundary after the final input/output-channel pair,
  // instead of incrementing the output counter and launching an unused tile.
  assign w_input_job_complete = w_input_last_channel && w_input_last_output_channel;
  assign w_output_job_complete = w_output_last_channel_input &&
                                 w_output_last_channel_output &&
                                 w_output_last_window_acc;

  assign w_input_prefetch_mode = r_input_prefetch_enabled;

  // STREAM_FREEZE lifetime policy: the current feature tile remains stable
  // until the last transform row has been consumed by the Hadamard stage.
  assign w_conv_input_release =
                                (st_conv_current == INVERSE) ||
                                ((st_conv_current == HADAMARD) &&
                                 (r_conv_multiply_count == $bits(r_conv_multiply_count)'(STREAM_CYCLES - 1)));

  // The next tile may replace the current feature bank only after the
  // convolution has consumed its final Hadamard row.
  assign w_input_prefetch_commit = r_input_prefetch_full &&
                                   (w_conv_input_release || w_conv_end ||
                                    ((st_conv_current == WAIT_CONV) &&
                                     (st_output_current inside {RESET_OUTPUT, READ_OUTPUT}))) &&
                                   w_input_write_done;

  // When no prefetch is available (the first tile and the right edge), retain
  // the stream-freeze shift: the KEEP_COLUMNS rightmost columns of the current
  // tile become the leftmost columns of the next tile.
  assign w_input_feature_shift = r_stream_transfer_pending && w_conv_input_release;

  assign p_end = (st_output_current == WRITE_OUTPUT) &&
                 (r_output_write_count == OUTPUT_RW_COUNT_WIDTH'(OUTPUT_RW_COUNT_MAX)) &&
                 w_output_job_complete;  // Signal completion only after the final output write.

  // -------------------------------------------------------------------------
  // READING REGISTER BANK
  // -------------------------------------------------------------------------

  // SET OF CONTROL REGISTERS:
  // r_input_channel_counter_input: number of the current IFMAP channel being read
  // r_input_channel_counter_output: number of the current OFMAP channel being processed
  // r_input_window_counter_acc: number of convolutions in a given IFMAP channel
  // r_input_window_counter_col :  number of horizontal convolutions in a given IFMAP channel - detect the last line
  // r_weight_row_count:          transformed weight words loaded for the active tile
  // r_input_beat:                column beat written by READ_IN
  always_ff @(posedge clk or posedge reset) begin: INPUT_CONTROL_COUNTERS_BLOCK
    if (reset) begin
      r_weight_row_count            <= '0;
      r_weight_tile_valid           <= 1'b0;
      r_input_window_counter_acc     <= 0;
      r_input_window_counter_col     <= 0;
      r_input_channel_counter_input  <= '1;  // p_start with all bits in '1' - IFchannel must be {0,1,2}
      r_input_channel_counter_output <= 0;
      r_input_beat                   <= '0;
    end else begin
      if (st_input_current == ADDRESS_INPUT) begin
        if (!w_input_job_complete) begin
          if (r_input_channel_counter_input == CHANNEL_INPUT_COUNTER_WIDTH'(N_CHANNEL_IN - 1)) begin
            r_input_channel_counter_input  <= '0;
            r_input_channel_counter_output <= r_input_channel_counter_output + 1;
          end else begin
            r_input_channel_counter_input <= r_input_channel_counter_input + 1;
          end
        end
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

      // A full tile load starts at beat 0; the direct path after a shift only
      // loads the new columns, which start right after the KEEP_COLUMNS shared ones.
      if (st_input_current == ADDRESS_INPUT || st_input_current == NEXT_ROW_INPUT)
        r_input_beat <= '0;
      else if (st_input_current == HOLD_WRITE && st_input_next == READ_IN)
        r_input_beat <= BEAT_COUNT_WIDTH'(KEEP_COLUMNS);
      else if (st_input_current == READ_IN && p_input_valid) begin
        if (r_input_beat == BEAT_COUNT_WIDTH'(CONV_INPUT_SIZE - 1))
          r_input_beat <= '0;
        else
          r_input_beat <= r_input_beat + 1'b1;
      end

      if (st_input_current == ADDRESS_INPUT)
        r_weight_tile_valid <= 1'b0;
      else if (st_input_current == HOLD_WRITE && st_input_next == READ_WEIGHTS)
        r_weight_row_count <= '0;
      else if (st_input_current == READ_WEIGHTS && p_input_valid) begin
        if (r_weight_row_count != WEIGHT_ROW_COUNT_WIDTH'(WEIGHT_LAST_BEAT_OFFSET))
          r_weight_row_count <= r_weight_row_count + WEIGHT_ROW_COUNT_WIDTH'(CONV_INPUT_SIZE);
        else begin
          r_weight_tile_valid <= 1'b1;
        end
      end
    end
  end

  // -------------------------------------------------------------------------
  // FEATURE BANK NEXT-VALUE AND WRITE-ENABLE LOGIC
  // -------------------------------------------------------------------------
  always_comb begin: INPUT_SHIFT_DATA_BLOCK
    for (int unsigned i = 0; i < TILE_WORDS; i++)
      w_input_feat_next[i] = p_input_data[0 +: NBITS];

    // Direct column load: lane l of the beat goes to bank word l*IN + beat.
    if (st_input_current == READ_IN) begin
      for (int unsigned lane = 0; lane < CONV_INPUT_SIZE; lane++)
        w_input_feat_next[lane * CONV_INPUT_SIZE + int'(r_input_beat)] = p_input_data[lane*NBITS +: NBITS];
    end

    // Stream shift: the KEEP_COLUMNS rightmost columns become the leftmost ones.
    if (w_input_feature_shift) begin
      for (int unsigned lane = 0; lane < CONV_INPUT_SIZE; lane++)
        for (int unsigned c = 0; c < KEEP_COLUMNS; c++)
          w_input_feat_next[lane * CONV_INPUT_SIZE + c] =
              r_input_feat[lane * CONV_INPUT_SIZE + (CONV_INPUT_SIZE - KEEP_COLUMNS) + c];
    end

    // Prefetch commit: shift plus the NEW_COLUMNS prefetched columns.
    if (w_input_prefetch_commit) begin
      for (int unsigned lane = 0; lane < CONV_INPUT_SIZE; lane++) begin
        for (int unsigned c = 0; c < KEEP_COLUMNS; c++)
          w_input_feat_next[lane * CONV_INPUT_SIZE + c] =
              r_input_feat[lane * CONV_INPUT_SIZE + (CONV_INPUT_SIZE - KEEP_COLUMNS) + c];
        for (int unsigned k = 0; k < NEW_COLUMNS; k++)
          w_input_feat_next[lane * CONV_INPUT_SIZE + KEEP_COLUMNS + k] =
              r_input_prefetch[k * CONV_INPUT_SIZE + lane];
      end
    end

  end

  always_comb begin: INPUT_SHIFT_WE_BLOCK  // 'w_input_feat_en' to write into the register bank r_input_feat
    w_input_feat_en = '0;
    if (w_input_prefetch_commit) begin
      w_input_feat_en = '1;
    end else begin
      if (w_input_feature_shift) begin
        for (int unsigned lane = 0; lane < CONV_INPUT_SIZE; lane++)
          for (int unsigned c = 0; c < KEEP_COLUMNS; c++)
            w_input_feat_en[lane * CONV_INPUT_SIZE + c] = 1'b1;
      end
      // The load of a new column happens on a valid beat, after the shift has
      // already copied the shared columns (the shift precedes the first beat).
      if (st_input_current == READ_IN && p_input_valid) begin
        for (int unsigned lane = 0; lane < CONV_INPUT_SIZE; lane++)
          w_input_feat_en[lane * CONV_INPUT_SIZE + int'(r_input_beat)] = 1'b1;
      end
    end
  end

  assign w_input_feat_write_valid = w_input_prefetch_commit || w_input_feature_shift || p_input_valid;

  always_ff @(posedge clk or posedge reset) begin: STREAM_TRANSFER_PENDING_BLOCK
    if (reset)
      r_stream_transfer_pending <= 1'b0;
    else if (st_input_current == TRANSFER)
      r_stream_transfer_pending <= 1'b1;
    else if (w_input_feature_shift)
      r_stream_transfer_pending <= 1'b0;
  end

  always_ff @(posedge clk or posedge reset) begin: INPUT_PREFETCH_BUFFER_BLOCK
    if (reset) begin
      r_input_prefetch <= '{default: '0};
      r_input_prefetch_full <= 1'b0;
      r_input_prefetch_active <= 1'b0;
      r_input_prefetch_enabled <= 1'b0;
      r_input_prefetch_addr <= '0;
      r_input_prefetch_phase <= '0;
    end else begin
      // Issue the first new-column read one cycle before TRANSFORM.  The
      // main tile remains untouched until commit.
      // The row-constant variant loads its nine spatial weights after the
      // first input tile.  Do not let the prefetch port steal those reads;
      // start overlapping only once the weight tile is cached.  CONV_INPUT may
      // last several cycles, so issue the prefetch only once per tile.
      if (st_input_current == CONV_INPUT && r_weight_tile_valid &&
          !r_input_prefetch_active && !r_input_prefetch_full &&
          (r_input_window_counter_col < WINDOW_ROW_COUNTER_WIDTH'(WINDOW_COUNT_PER_LINE - 1))) begin
        r_input_prefetch_active <= 1'b1;
        r_input_prefetch_addr <= r_input_addr_feat + NADDR'(FEAT_INPUT_WIDTH);
        r_input_prefetch_phase <= '0;
        r_input_prefetch_full <= 1'b0;
      end else if (r_input_prefetch_active && p_input_valid) begin
        for (int unsigned lane = 0; lane < CONV_INPUT_SIZE; lane++)
          r_input_prefetch[(int'(r_input_prefetch_phase) * CONV_INPUT_SIZE) + lane] <=
              p_input_data[lane*NBITS +: NBITS];
        r_input_prefetch_addr <= r_input_prefetch_addr + NADDR'(FEAT_INPUT_WIDTH);  // next column beat
        if (r_input_prefetch_phase == (NEW_COLUMNS - 1)) begin
          r_input_prefetch_active <= 1'b0;
          r_input_prefetch_full <= 1'b1;
        end else begin
          r_input_prefetch_phase <= r_input_prefetch_phase + 1'b1;
        end
      end
      if (st_input_current == NEXT_ROW_INPUT || st_input_current == ADDRESS_INPUT) begin
        r_input_prefetch_active <= 1'b0;
        r_input_prefetch_full <= 1'b0;
      end
      if (st_input_current == ADDRESS_INPUT || st_input_current == NEXT_ROW_INPUT)
        r_input_prefetch_enabled <= 1'b0;
      else if (st_input_current == CONV_INPUT && st_conv_current == WAIT_CONV)
        r_input_prefetch_enabled <= r_weight_tile_valid &&
                                    (r_input_window_counter_col < WINDOW_ROW_COUNTER_WIDTH'(WINDOW_COUNT_PER_LINE - 1));
      if (w_input_prefetch_commit)
        r_input_prefetch_full <= 1'b0;
    end
  end

  always_ff @(posedge clk or posedge reset) begin: INPUT_FEATURE_REG_BLOCK  // initializes and write into the register bank and convolution register bank
    if (reset) begin
      for (int unsigned i = 0; i < TILE_WORDS; i++)
        r_input_feat[i] <= '0;
    end else begin
      for (int unsigned i = 0; i < TILE_WORDS; i++)
        if (w_input_feat_en[i] && w_input_feat_write_valid) r_input_feat[i] <= w_input_feat_next[i];
    end
  end

  always_ff @(posedge clk or posedge reset) begin: WEIGHT_REG_BLOCK
    if (reset) begin
      for (int unsigned i = 0; i < PRETRANSFORMED_WEIGHT_WORDS; i++)
        r_weight_pretransformed[i] <= '0;
    end else if (st_input_current == READ_WEIGHTS && p_input_valid) begin
      for (int unsigned lane = 0; lane < CONV_INPUT_SIZE; lane++) begin
        if ((int'(r_weight_row_count) + lane) < PRETRANSFORMED_WEIGHT_WORDS)
          r_weight_pretransformed[int'(r_weight_row_count) + lane] <=
              $signed(p_input_data[lane*NBITS +: NBITS]);
      end
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
        if ((st_input_current == CONV_INPUT) && (st_output_next != WRITE_OUTPUT)) begin
          st_conv_next = TRANSFORM;  // starts the convolution after moving data to the convolution register bank
        end
      end
      TRANSFORM:
        // The first tile remains here while the pretransformed weight tile is read.
        // For subsequent windows the cached tile is already valid, so the
        // first transformed row is consumed on the next cycle.
        if (r_weight_tile_valid)
          st_conv_next = HADAMARD;
      HADAMARD: begin
        if (r_conv_multiply_count == $bits(r_conv_multiply_count)'(STREAM_CYCLES - 1)) begin
          st_conv_next = INVERSE;
        end else
          st_conv_next = HADAMARD;
      end
      INVERSE:
        st_conv_next = WAIT_CONV;
      default: st_conv_next = WAIT_CONV;
    endcase
  end

  // -------------------------------------------------------------------------
  // CONVOLUTION REGISTER BANK AND CONVOLUTION REGISTERS:  w_conv_end  -- r_conv_multiply_count
  // -------------------------------------------------------------------------
  always_ff @(posedge clk or posedge reset) begin: CONV_END_FLAG_BLOCK
    if (reset)
      w_conv_end <= 0;
    else begin
      if (st_conv_current == INVERSE)
        w_conv_end <= 1;
      else if (st_output_current == WRITE_OUTPUT)
        w_conv_end <= 0;
    end
  end

  always_ff @(posedge clk or posedge reset) begin: CONV_MULTIPLY_COUNTER_BLOCK
    if (reset)
      r_conv_multiply_count <= 0;
    else begin
      if (st_conv_current == TRANSFORM)
          r_conv_multiply_count <= 0;
      else if (st_conv_current == HADAMARD)
        r_conv_multiply_count <= r_conv_multiply_count + 1;
    end
  end

  // Register transformed features before Hadamard and register Hadamard
  // products before the inverse. Each product batch contains ROWS_PER_CYCLE
  // adjacent Hadamard rows, aligned by its first row index.
  always_ff @(posedge clk or posedge reset) begin: STREAMING_DATAPATH_BLOCK
    if (reset) begin
      r_transform_feature_reg <= '{default: '0};
      r_hadamard_product_reg <= '{default: '0};
      // The output-write bank also carries the streaming accumulation state.
      // Sharing this bank removes the duplicate accumulator bank.
      r_output_write              <= '{default: '0};
    end else begin
      unique case (st_conv_current)
        TRANSFORM: begin
          // Capture the full transformed feature tile once. MAC batches select
          // their operands from this bank without rewriting it between cycles.
          for (int unsigned feature = 0; feature < WEIGHT_CYCLES; feature++)
            r_transform_feature_reg[feature] <= w_conv_transform[feature];
          r_output_write              <= '{default: '0};
        end
        HADAMARD: begin
          // Fill the full row-major 8x8 product matrix in two 32-lane batches.
          for (int unsigned lane = 0; lane < FIXED_NUM_MULT; lane++)
            r_hadamard_product_reg[(int'(r_conv_multiply_count) * FIXED_NUM_MULT) + lane] <=
                w_hadamard_product_current[lane];
        end
        INVERSE: begin
          r_output_write <= w_output_acc_next;
        end
        default: begin end
      endcase
    end
  end

  // Instance of the feature transform "C".
  Transform #(
    .NBITS(NBITS),
    .CONV_OUTPUT_SIZE(CONV_OUTPUT_SIZE),
    .CONV_INPUT_SIZE(CONV_INPUT_SIZE),
    .HADAMARD_SIZE(HADAMARD_SIZE)
  ) trf (
      .pin (r_input_feat),
      .pout(w_conv_transform)
  );

  for (genvar lane = 0; lane < FIXED_NUM_MULT; lane++) begin: MAC_LANES
    assign w_transform_feature[lane] =
        r_transform_feature_reg[(int'(r_conv_multiply_count) * FIXED_NUM_MULT) + lane];
    assign w_hadamard_product_current[lane] = w_conv_product[lane];
    Multip #(.QUANT(QUANT), .NBITS(NBITS)) multip(
      .feature(w_transform_feature[lane]),
      .weight(r_weight_pretransformed[(int'(r_conv_multiply_count) * FIXED_NUM_MULT) + lane]),
      .product(w_conv_product[lane]));
  end
  InverseFull #(
    .NBITS(NBITS),
    .CONV_OUTPUT_SIZE(CONV_OUTPUT_SIZE),
    .CONV_INPUT_SIZE(CONV_INPUT_SIZE),
    .HADAMARD_SIZE(HADAMARD_SIZE)
  ) inverse_transform(
    .pin(r_hadamard_product_reg),
    .pout(w_inverse_transform)
  );
  always_comb begin: INVERSE_OUTPUT_ACCUMULATE_BLOCK
    for (int unsigned output_index = 0;
         output_index < CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE;
         output_index++)
      w_output_acc_next[output_index] =
          r_output_write[output_index] + w_inverse_transform[output_index];
  end
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
          else if (w_output_job_complete)
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

  always_ff @(posedge clk or posedge reset) begin: OUTPUT_DATA_BLOCK
    if (reset) begin
      r_output_read <= '{default: '0};
    end else begin
      if (st_output_current == RESET_OUTPUT) begin
        r_output_read <= '{default: '0};
      end else if ((st_output_current == READ_OUTPUT) && p_output_valid) begin
        for (int unsigned lane = 0; lane < CONV_OUTPUT_SIZE; lane++)
          r_output_read[(r_output_read_count * CONV_OUTPUT_SIZE) + lane] <=
              p_output_data_read[lane*NBITS +: NBITS];
      end
    end
  end

  always_ff @(posedge clk or posedge reset) begin: OUTPUT_ADDR_POINTER_BLOCK
    if (reset) begin
      r_output_addr_channel <= '0;
      r_output_addr_col <= '0;
      r_output_addr_row <= '0;
    end else begin
      // Address generation for output map (row-major physical grid):
      // - slide window every completed WRITE_OUTPUT window
      // - when one input-channel pass finishes, restart window scan at channel base
      // - when last input channel finishes, advance to next output channel base
      if (st_output_current == WRITE_OUTPUT && r_output_write_count == OUTPUT_RW_COUNT_WIDTH'(OUTPUT_RW_COUNT_MAX)) begin
        if (w_output_last_window_acc) begin
          r_output_addr_col <= '0;
          r_output_addr_row <= '0;
          if (w_output_last_channel_input && !w_output_last_channel_output)
            r_output_addr_channel <= r_output_addr_channel + OUTPUT_ADDR_CHANNEL_WIDTH'(OUTPUT_PHYSICAL_SIZE * OUTPUT_PHYSICAL_SIZE);
        end else if (w_output_last_window_row) begin
          r_output_addr_row <= '0;
          if (w_output_last_window_col)
            r_output_addr_col <= '0;
          else
            r_output_addr_col <= r_output_addr_col + OUTPUT_ADDR_COL_WIDTH'(CONV_OUTPUT_SIZE);
        end else begin
          r_output_addr_row <= r_output_addr_row + OUTPUT_ADDR_ROW_WIDTH'(OUTPUT_PHYSICAL_SIZE * CONV_OUTPUT_SIZE);
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
        r_output_addr_offset_read <= r_output_addr_offset_read + OUTPUT_ADDR_OFFSET_WIDTH'(1);
      end

      if (st_output_current != WRITE_OUTPUT) begin
        r_output_addr_offset_write <= '0;
      end else begin
        // Prepare offset for next WRITE cycle without lookup table.
        if (r_output_write_count == OUTPUT_RW_COUNT_WIDTH'(OUTPUT_RW_COUNT_MAX))
          r_output_addr_offset_write <= r_output_addr_offset_write;
        else
        r_output_addr_offset_write <= r_output_addr_offset_write + OUTPUT_ADDR_OFFSET_WIDTH'(1);
      end
    end
  end

  assign w_output_addr = NADDR'(r_output_addr_channel) + NADDR'(r_output_addr_col) + NADDR'(r_output_addr_row);
  always_comb begin: OUTPUT_COLUMN_DATA_BLOCK
    for (int unsigned lane = 0; lane < CONV_OUTPUT_SIZE; lane++)
      p_output_data_write[lane*NBITS +: NBITS] =
          r_output_write[(r_output_write_count * CONV_OUTPUT_SIZE) + lane] +
          r_output_read[(r_output_write_count * CONV_OUTPUT_SIZE) + lane];
  end
  assign p_output_addr = (st_output_current == READ_OUTPUT) ?
    (w_output_addr + NADDR'(r_output_addr_offset_read)) :
    (w_output_addr + NADDR'(r_output_addr_offset_write));  // p_input_addr mux
  // Keep read enabled through the last beat so the final column is fetched.
  assign p_output_en = (((st_output_current == READ_OUTPUT) && r_output_read_count <= OUTPUT_RW_COUNT_WIDTH'(OUTPUT_RW_COUNT_MAX)) || (st_output_current == WRITE_OUTPUT)) ? '1 : '0;
  // Keep write enabled for every WRITE_OUTPUT beat, including the final window/channel.
  assign p_output_wr = (st_output_current == WRITE_OUTPUT) ? '1 : '0;

endmodule

// -----------------------------------------------------------------------------
// Full-matrix inverse transform. With M as the registered 8x8 Hadamard product
// matrix, compute Y = A0^T * M * A1 in one combinational stage. Arithmetic wraps
// at NBITS, matching the canonical fixed-width datapath.
// -----------------------------------------------------------------------------
module InverseFull #(
    parameter int NBITS = 16,
    parameter int CONV_OUTPUT_SIZE = 4,
    parameter int CONV_INPUT_SIZE = 6,
    parameter int HADAMARD_SIZE = 8
  ) (
    input  logic [NBITS-1:0] pin [HADAMARD_SIZE*HADAMARD_SIZE-1:0],
    output logic [NBITS-1:0] pout [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0]
  );
  timeunit 1ns;
  timeprecision 1ps;

  logic [NBITS-1:0] partial [CONV_INPUT_SIZE*HADAMARD_SIZE-1:0];

  // First inverse dimension: M * A1.
  assign partial[0]  = pin[0]  + pin[1]  + pin[2]  + pin[4]  + pin[5];
  assign partial[1]  = pin[2]  + pin[3]  + pin[5]  + pin[6];
  assign partial[2]  = pin[1]  + pin[2]  - pin[4]  - pin[5];
  assign partial[3]  = pin[2]  + pin[3]  + pin[7]  - pin[5]  - pin[6];
  assign partial[4]  = pin[8]  + pin[9]  + pin[10] + pin[12] + pin[13];
  assign partial[5]  = pin[10] + pin[11] + pin[13] + pin[14];
  assign partial[6]  = pin[9]  + pin[10] - pin[12] - pin[13];
  assign partial[7]  = pin[10] + pin[11] + pin[15] - pin[13] - pin[14];
  assign partial[8]  = pin[16] + pin[17] + pin[18] + pin[20] + pin[21];
  assign partial[9]  = pin[18] + pin[19] + pin[21] + pin[22];
  assign partial[10] = pin[17] + pin[18] - pin[20] - pin[21];
  assign partial[11] = pin[18] + pin[19] + pin[23] - pin[21] - pin[22];
  assign partial[12] = pin[24] + pin[25] + pin[26] + pin[28] + pin[29];
  assign partial[13] = pin[26] + pin[27] + pin[29] + pin[30];
  assign partial[14] = pin[25] + pin[26] - pin[28] - pin[29];
  assign partial[15] = pin[26] + pin[27] + pin[31] - pin[29] - pin[30];
  assign partial[16] = pin[32] + pin[33] + pin[34] + pin[36] + pin[37];
  assign partial[17] = pin[34] + pin[35] + pin[37] + pin[38];
  assign partial[18] = pin[33] + pin[34] - pin[36] - pin[37];
  assign partial[19] = pin[34] + pin[35] + pin[39] - pin[37] - pin[38];
  assign partial[20] = pin[40] + pin[41] + pin[42] + pin[44] + pin[45];
  assign partial[21] = pin[42] + pin[43] + pin[45] + pin[46];
  assign partial[22] = pin[41] + pin[42] - pin[44] - pin[45];
  assign partial[23] = pin[42] + pin[43] + pin[47] - pin[45] - pin[46];
  assign partial[24] = pin[48] + pin[49] + pin[50] + pin[52] + pin[53];
  assign partial[25] = pin[50] + pin[51] + pin[53] + pin[54];
  assign partial[26] = pin[49] + pin[50] - pin[52] - pin[53];
  assign partial[27] = pin[50] + pin[51] + pin[55] - pin[53] - pin[54];
  assign partial[28] = pin[56] + pin[57] + pin[58] + pin[60] + pin[61];
  assign partial[29] = pin[58] + pin[59] + pin[61] + pin[62];
  assign partial[30] = pin[57] + pin[58] - pin[60] - pin[61];
  assign partial[31] = pin[58] + pin[59] + pin[63] - pin[61] - pin[62];

  // Combine the eight inverse rows in the same output-lane order as the
  // former ROWS_PER_CYCLE=4 accumulator, but in one full-matrix expression.
  assign pout[0]  = partial[0]  + partial[4]  + partial[8]  + partial[16] + partial[20];
  assign pout[1]  = partial[1]  + partial[5]  + partial[9]  + partial[17] + partial[21];
  assign pout[2]  = partial[2]  + partial[6]  + partial[10] + partial[18] + partial[22];
  assign pout[3]  = partial[3]  + partial[7]  + partial[11] + partial[19] + partial[23];
  assign pout[4]  = partial[8]  + partial[12] + partial[20] + partial[24];
  assign pout[5]  = partial[9]  + partial[13] + partial[21] + partial[25];
  assign pout[6]  = partial[10] + partial[14] + partial[22] + partial[26];
  assign pout[7]  = partial[11] + partial[15] + partial[23] + partial[27];
  assign pout[8]  = partial[4]  + partial[8]  - partial[16] - partial[20];
  assign pout[9]  = partial[5]  + partial[9]  - partial[17] - partial[21];
  assign pout[10] = partial[6]  + partial[10] - partial[18] - partial[22];
  assign pout[11] = partial[7]  + partial[11] - partial[19] - partial[23];
  assign pout[12] = partial[8]  + partial[12] - partial[20] - partial[24] + partial[28];
  assign pout[13] = partial[9]  + partial[13] - partial[21] - partial[25] + partial[29];
  assign pout[14] = partial[10] + partial[14] - partial[22] - partial[26] + partial[30];
  assign pout[15] = partial[11] + partial[15] - partial[23] - partial[27] + partial[31];
endmodule
