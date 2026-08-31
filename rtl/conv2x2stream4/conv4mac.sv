/*
   CONVOLUTION CONTROLLER  - (V0 - FERNANDO MORAES)  - 24/ABRIL
*/
`timescale 1ns / 1ps

// Fixed four-MAC streaming controller for the F(2x2, 3x3) Winograd tile.
// The input and output FSMs surround a row-streamed transform/Hadamard/inverse
// datapath so the complete 4x4 Hadamard matrix does not need to be registered.
// Status: functionally changed.
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

  // This source is intentionally fixed at four parallel products per cycle.
  // Keeping the value local prevents an elaboration parameter from silently
  // changing the datapath width or the row schedule.
  localparam int unsigned FIXED_NUM_MULT = 4;

  // Return a legal one-bit counter width for singleton ranges.
  // This helper is important because $clog2(1) is zero in SystemVerilog.
  // Status: practically unchanged functionally.
  function automatic int f_width_min1(input int x);
    if (x <= 1)
      f_width_min1 = 1;
    else
      f_width_min1 = $clog2(x);
  endfunction

  // Input tile storage and control signals. The bank holds the current tile
  // while the combinational Transform consumes it; write enables preserve the
  // overlap between loading the next tile and computing the current tile.
  // Modified: the tile lifetime is now protected until the final Hadamard row
  // has been consumed; the transform still reads the same 16-word bank.
  logic [NBITS-1:0] r_input_feat[(CONV_INPUT_SIZE * CONV_INPUT_SIZE) - 1:0];  // input feature register bank
  // Modified structurally: the generic loop was expanded into fixed assignments
  // for this four-MAC implementation; the values and indexing remain equivalent.
  logic [NBITS-1:0] w_input_feat_next[(CONV_INPUT_SIZE * CONV_INPUT_SIZE) - 1:0];  // next values for feature shift bank
  logic [NADDR-1:0] r_input_addr_feat;
  logic [NADDR-1:0] r_input_addr_kernel;
  logic [NADDR-1:0] r_input_window_next;
  // Modified: the feature-bank write mask is asserted only when the pending
  // transfer coincides with the stream release point.
  logic [(CONV_INPUT_SIZE * CONV_INPUT_SIZE) - 1:0] w_input_feat_en;  // write-enable per feature register
  // Modified: valid data now includes the deferred stream-transfer handshake.
  logic w_input_feat_write_valid;
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

  // Weight storage and Hadamard schedule. Sixteen weights are rotated four at
  // a time, matching the four explicit Multip instances below.
  // REGISTER BANK FOR THE WEIGHTS ////////////////////////////////////////////
  localparam WEIGHT_CYCLES = HADAMARD_SIZE * HADAMARD_SIZE;
  localparam STREAM_CYCLES = 4;
  // Modified: this counter now counts the four streamed Hadamard cycles rather
  // than the conventional multiply schedule controlled by STATE_MULT.
  logic [(f_width_min1(STREAM_CYCLES + 1))-1:0] r_conv_multiply_count;
  localparam WEIGHT_WIDTH = f_width_min1(WEIGHT_CYCLES + 1);
  // Modified structurally: the 16-word rotation is written explicitly instead
  // of using a loop, while preserving the original weight order.
  logic [NBITS-1:0] r_input_weight[WEIGHT_CYCLES-1:0];
  logic [WEIGHT_CYCLES-1:0] w_input_weight_en;
  logic [WEIGHT_WIDTH-1:0] r_input_count_kernel;
  logic w_input_weight_done;
  logic w_input_write_done;

  logic [NBITS-1:0] w_conv_transform [HADAMARD_SIZE*HADAMARD_SIZE-1:0];
  // Modified structurally: the product bus is now explicitly four lanes,
  // matching the fixed four-MAC implementation instead of a generic NUM_MULT
  // schedule. The product arithmetic remains the same.
  logic signed [NBITS-1+QUANT:0] w_conv_product [FIXED_NUM_MULT-1:0];  // QUANT more bits for the multipliers
  // Modified functionally: completion is asserted on the last streamed row
  // rather than after the conventional full Inverse state.
  logic w_conv_end;
`ifdef STREAM_DEBUG
  integer stream_debug_had_count;
`endif
  localparam OUTPUT_RW_COUNT_MAX = (CONV_OUTPUT_SIZE * CONV_OUTPUT_SIZE) - 1;
  localparam OUTPUT_RW_COUNT_WIDTH = f_width_min1(CONV_OUTPUT_SIZE * CONV_OUTPUT_SIZE);
  logic [OUTPUT_RW_COUNT_WIDTH-1:0] r_output_read_count;
  logic [OUTPUT_RW_COUNT_WIDTH-1:0] r_output_write_count;
  // Modified: this bank now receives the final row-accumulator value directly;
  // the conventional w_conv_inverse full-matrix bus no longer exists.
  logic [NBITS-1:0] r_output_write [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0];
  logic [NBITS-1:0] r_output_read [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0];
  logic [NADDR-1:0] w_output_addr;

  // Output traversal state. These counters map each 2x2 result tile into the
  // output feature map and are also used to detect the final channel/window.
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
  // STREAMING-ONLY SIGNALS
  // -------------------------------------------------------------------------
  // These declarations do not exist in the conventional Conv datapath. They
  // are kept together before the FSM declarations so the additional state and
  // combinational plumbing can be audited independently from legacy signals.

  // Width constants for the streaming cursors. They are adjacent to the
  // signals they size and avoid zero-width declarations for singleton ranges.
  localparam int ROW_INDEX_WIDTH = f_width_min1(HADAMARD_SIZE);
  localparam int PRODUCT_INDEX_WIDTH = f_width_min1(WEIGHT_CYCLES);

  // Holds a transfer request when the input FSM reaches TRANSFER before the
  // final streamed Hadamard cycle is complete. This prevents overwriting the
  // tile that is still being consumed by Transform.
  // Status: added.
  logic r_stream_transfer_pending;

  // Marks the first streamed Hadamard cycle and resets the row/product cursors
  // and output accumulator at the beginning of a new transformed tile.
  // Status: added.
  logic w_hadamard_start;

  // Marks the fourth and final streamed Hadamard cycle for the fixed four-MAC
  // schedule. It is shared by convolution completion and input release.
  // Status: added.
  logic w_hadamard_last;

  // Releases the deferred input transfer only after the last Hadamard row has
  // been consumed, preserving the input tile lifetime without a second bank.
  // Status: added.
  logic w_conv_input_release;

  // Stores the partial 2x2 output across streamed inverse rows. This is the
  // only output datapath register bank introduced by row-wise accumulation.
  // Status: added.
  logic [NBITS-1:0] r_out_acc [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0];

  // Selects the inverse row currently being accumulated (0 through 3).
  // Status: added.
  logic [ROW_INDEX_WIDTH-1:0] r_stream_row_idx;

  // Selects the first transformed value of the four-value group feeding the
  // explicit MACs in the current Hadamard cycle.
  // Status: added.
  logic [PRODUCT_INDEX_WIDTH-1:0] r_stream_product_idx;

  // Contains the current row's inverse result before it is merged into the
  // registered partial output accumulator.
  // Status: added.
  logic [NBITS-1:0] w_stream_sigma_current [CONV_OUTPUT_SIZE-1:0];

  // Reserved second inverse-row lane for a future folded schedule. It is kept
  // as an explicit signal to document the planned two-row extension.
  // Status: added (reserved).
  logic [NBITS-1:0] w_stream_sigma_current_2 [CONV_OUTPUT_SIZE-1:0];

  // Combinational next value of the accumulated output, used as the D input of
  // r_out_acc and as the source for final output capture.
  // Status: added.
  logic [NBITS-1:0] w_stream_acc_next [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0];

  // Reserved diagnostic value for the first-row accumulation checkpoint. It is
  // not required by the fixed four-MAC datapath.
  // Status: added (reserved).
  logic [NBITS-1:0] w_stream_acc_after_first [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0];

  // Alias for the completed accumulated tile retained for waveform/debug
  // visibility; output writing uses w_stream_final_capture below.
  // Status: added (alias/debug visibility).
  logic [NBITS-1:0] w_stream_final_output [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0];

  // Captures the final accumulated tile on the last Hadamard cycle and feeds
  // the output register bank without an intermediate full Inverse matrix.
  // Status: added.
  logic [NBITS-1:0] w_stream_final_capture [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0];

  // Packs the four explicit products into the row-shaped interface expected by
  // InverseRow; all four entries are driven in the fixed four-MAC variant.
  // Status: added.
  logic [NBITS-1:0] w_stream_product_row [HADAMARD_SIZE-1:0];

  // Reserved second product row for a future two-row folded schedule. It is not
  // consumed by the current four-MAC implementation.
  // Status: added (reserved).
  logic [NBITS-1:0] w_stream_product_row_2 [HADAMARD_SIZE-1:0];

  // Selects the four transformed values consumed by the explicit MAC instances
  // in the current streamed cycle.
  // Status: added.
  logic [NBITS-1:0] w_conv_feature [FIXED_NUM_MULT-1:0];


  // -------------------------------------------------------------------------
  // FSM STATES DECLARION
  // -------------------------------------------------------------------------
  // The input FSM owns memory reads and tile loading, the convolution FSM
  // owns the four Hadamard cycles, and the output FSM owns accumulation and
  // writes. Separating these responsibilities makes each handshake explicit.
  // Status: practically unchanged functionally.
  typedef enum logic [3:0] {
    WAIT_INPUT,
    ADDRESS_INPUT,
    READ_WEIGHTS,
    READ_IN_10A,
    READ_IN_10B,
    READ_IN_8C,
    READ_IN_8D,
    HOLD_WRITE,
    CONV_INPUT,
    TRANSFER,
    NEXT_ROW_INPUT
  } type_st_input;
  type_st_input st_input_current;
  type_st_input st_input_next;

  // Modified: TRANSFORM and INVERSE were removed because the transform is
  // combinational and the inverse is consumed one row per Hadamard cycle.
  // Status: functionally changed.
  typedef enum logic {
    WAIT_CONV,
    HADAMARD
  } type_st_conv;
  type_st_conv st_conv_current;
  type_st_conv st_conv_next;

  // Status: practically unchanged functionally.
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

  // Select the memory port for either a weight read or one row of the input
  // tile. These signals are combinational so the RAM sees the address for the
  // state currently active in the input FSM.
  assign p_input_en   = (st_input_current inside {READ_WEIGHTS, READ_IN_10A, READ_IN_10B, READ_IN_8C, READ_IN_8D});
  assign p_input_addr = (st_input_current == READ_WEIGHTS) ? r_input_addr_kernel : r_input_addr_feat + NADDR'(r_input_addr_count);  // p_input_addr mux

  // Advance the feature-map base after each loaded row/window and return to
  // the next channel when the complete input traversal has finished.
  // Status: practically unchanged functionally.
  always_ff @(posedge clk or posedge reset) begin: INPUT_ADDR_POINTER_BLOCK
    if (reset) begin
      r_input_addr_feat <= '0;
      r_input_window_next <= CONV_OUTPUT_SIZE;
    end
    else if ((st_input_current == READ_IN_10A && st_input_next == READ_IN_10B) || (st_input_current == READ_IN_10B && st_input_next == READ_IN_8C) || (st_input_current == READ_IN_8C && st_input_next == READ_IN_8D) || st_input_current == TRANSFER)
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

  // Point the shared input memory at the weight region once per run, then
  // advance one address for every weight captured into the local bank.
  // Status: practically unchanged functionally.
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
  // Register the sequential input-FSM state. This is the timing boundary
  // between memory/control decisions and the next input operation.
  // Status: practically unchanged functionally.
  always_ff @(posedge clk or posedge reset) begin: INPUT_STATE_REG_BLOCK
    if (reset)
      st_input_current <= WAIT_INPUT;
    else
      st_input_current <= st_input_next;
  end

  // Decode the input schedule: start, load weights, load the four tile rows,
  // wait for the streaming core, and proceed to the next window or channel.
  // Correct sequencing is required to keep the feature bank stable during
  // all four Hadamard cycles.
  // Status: practically unchanged functionally.
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
      READ_IN_8C: if (r_input_addr_count == (CONV_INPUT_SIZE - 1)) st_input_next = READ_IN_8D;
      READ_IN_8D: if (r_input_addr_count == (CONV_INPUT_SIZE - 1)) st_input_next = CONV_INPUT;
      CONV_INPUT: st_input_next = TRANSFER;
      TRANSFER: st_input_next = HOLD_WRITE;  // p_start the convolution
      HOLD_WRITE:
        if (w_conv_input_release && w_input_last_window_col && w_input_write_done) st_input_next = NEXT_ROW_INPUT;
          else if (w_conv_input_release && w_input_write_done) st_input_next = READ_IN_8C;
        else st_input_next = HOLD_WRITE;
      NEXT_ROW_INPUT:
        if (w_input_last_window_acc) st_input_next = ADDRESS_INPUT;
        else st_input_next = READ_IN_10A;
      default: st_input_next = WAIT_INPUT;
    endcase
  end

  // Completion predicates are shared by the input and output FSMs. They avoid
  // duplicating terminal-count arithmetic in multiple sequential blocks.
  assign w_input_weight_done = (r_input_count_kernel == WEIGHT_WIDTH'(WEIGHT_CYCLES - 1));
  assign w_input_write_done = r_output_write_count == 0 || r_output_write_count == OUTPUT_RW_COUNT_MAX;  // compare to zero for the first write test or the last value (8) in the next convolutions

  assign w_input_last_window_col = (r_input_window_counter_col == WINDOW_ROW_COUNTER_WIDTH'(WINDOW_COUNT_PER_LINE));
  assign w_input_last_window_acc = (r_input_window_counter_acc == WINDOW_COUNTER_WIDTH'(WINDOW_COUNT_PER_LINE * WINDOW_COUNT_PER_COLUMN));
  assign w_input_last_channel_output = (r_input_channel_counter_output == CHANNEL_OUTPUT_COUNTER_WIDTH'(N_CHANNEL_OUT));

  // STREAM_FREEZE lifetime policy: the current feature tile remains stable
  // until the last transform row has been consumed by the Hadamard stage.
  // Start/last delimit the lifetime of one streamed tile. The input bank is
  // released only after the last Hadamard row has been consumed.
  assign w_hadamard_start = (st_conv_current == WAIT_CONV) &&
                            (st_input_current == CONV_INPUT);
  assign w_hadamard_last = (st_conv_current == HADAMARD) &&
                           (r_conv_multiply_count == $bits(r_conv_multiply_count)'(STREAM_CYCLES - 1));
  assign w_conv_input_release = w_hadamard_last;

  // p_end is asserted only on the final output write of the final output
  // channel, never merely when the convolution datapath becomes idle.
  assign p_end = (st_output_current == WRITE_OUTPUT) &&
                 (r_output_write_count == OUTPUT_RW_COUNT_WIDTH'(OUTPUT_RW_COUNT_MAX)) &&
                 w_input_last_channel_output;  // Signal completion only after the final output write.

  // -------------------------------------------------------------------------
  // READING REGISTERS
  // -------------------------------------------------------------------------

  // Count the samples within each of the four input rows. Resetting at the
  // row boundary makes the address expression remain row-major and local.
  // Status: practically unchanged functionally.
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
  // Track kernel position, window position, and input/output channel position.
  // These counters are the progress record for the complete nested traversal.
  // Status: practically unchanged functionally.
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
  // Form the next 4x4 feature tile from the RAM value and retained samples.
  // Only the positions enabled below are written, allowing horizontal
  // windows to reuse the overlapping columns without an extra tile buffer.
  // Status: functionally changed.
  always_comb begin: INPUT_SHIFT_DATA_BLOCK
    w_input_feat_next[0] = p_input_data;
    w_input_feat_next[1] = p_input_data;
    w_input_feat_next[2] = p_input_data;
    w_input_feat_next[3] = p_input_data;
    w_input_feat_next[4] = p_input_data;
    w_input_feat_next[5] = p_input_data;
    w_input_feat_next[6] = p_input_data;
    w_input_feat_next[7] = p_input_data;
    w_input_feat_next[8] = p_input_data;
    w_input_feat_next[9] = p_input_data;
    w_input_feat_next[10] = p_input_data;
    w_input_feat_next[11] = p_input_data;
    w_input_feat_next[12] = p_input_data;
    w_input_feat_next[13] = p_input_data;
    w_input_feat_next[14] = p_input_data;
    w_input_feat_next[15] = p_input_data;

    w_input_feat_next[0] = (st_input_current == READ_IN_10A) ? p_input_data : r_input_feat[2];
    w_input_feat_next[1] = (st_input_current == READ_IN_10B) ? p_input_data : r_input_feat[3];
    w_input_feat_next[4] = (st_input_current == READ_IN_10A) ? p_input_data : r_input_feat[6];
    w_input_feat_next[5] = (st_input_current == READ_IN_10B) ? p_input_data : r_input_feat[7];

    if (r_stream_transfer_pending && w_conv_input_release) begin
      w_input_feat_next[0] = r_input_feat[2];
      w_input_feat_next[1] = r_input_feat[3];
      w_input_feat_next[4] = r_input_feat[6];
      w_input_feat_next[5] = r_input_feat[7];
      w_input_feat_next[8] = r_input_feat[10];
      w_input_feat_next[9] = r_input_feat[11];
      w_input_feat_next[12] = r_input_feat[14];
      w_input_feat_next[13] = r_input_feat[15];
    end
  end

  assign w_input_feat_wr_index = INPUT_FEAT_INDEX_WIDTH'(w_input_base_feat) +
                                 (INPUT_FEAT_INDEX_WIDTH'(r_input_addr_count) *
                                  INPUT_FEAT_INDEX_WIDTH'(CONV_INPUT_SIZE));

  // Generate one-hot writes for row loading, or the overlap mask used when a
  // completed streamed tile hands ownership back to the input loader.
  // Status: functionally changed.
  always_comb begin: INPUT_SHIFT_WE_BLOCK  // 'w_input_feat_en' to write into the register bank r_input_feat
    w_input_feat_en = '0;
    case (st_input_current)
      READ_IN_10A, READ_IN_10B, READ_IN_8C, READ_IN_8D:
        w_input_feat_en[w_input_feat_wr_index] = 1'b1;
      default:
        if (r_stream_transfer_pending && w_conv_input_release)
          w_input_feat_en = 16'b0011001100110011;
    endcase
  end

  assign w_input_feat_write_valid = (r_stream_transfer_pending && w_conv_input_release) ||
                                    p_input_valid;

  // Remember that a tile transfer is pending across the input/streaming
  // boundary. This flag prevents the overlap update from occurring early.
  // Status: added.
  always_ff @(posedge clk or posedge reset) begin: STREAM_TRANSFER_PENDING_BLOCK
    if (reset)
      r_stream_transfer_pending <= 1'b0;
    else if (st_input_current == TRANSFER)
      r_stream_transfer_pending <= 1'b1;
    else if (r_stream_transfer_pending && w_conv_input_release)
      r_stream_transfer_pending <= 1'b0;
  end

  // Capture feature samples into the tile register bank. This is the storage
  // boundary that must remain frozen while the Transform and inverse consume
  // the tile.
  // Status: functionally changed.
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
  // Decode the active weight-bank entry for the current memory read.
  // Status: practically unchanged functionally.
  always_comb begin: WEIGHT_WE_BLOCK
    w_input_weight_en = '0;
    if (st_input_current == READ_WEIGHTS)
      w_input_weight_en[r_input_count_kernel] = 1'b1;
  end

  // Load all sixteen weights during READ_WEIGHTS, then rotate the bank by one
  // transformed row during each Hadamard cycle. The rotation aligns weights
  // with the four selected transform values without a large mux network.
  // Status: functionally changed.
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
  // Register the two-state streaming controller. WAIT_CONV marks the tile
  // boundary; HADAMARD covers all four row-product cycles.
  // Status: practically unchanged functionally.
  always_ff @(posedge clk or posedge reset) begin: CONV_STATE_REG_BLOCK
    if (reset)
      st_conv_current <= WAIT_CONV;
    else
      st_conv_current <= st_conv_next;
  end

  // Enter HADAMARD after the tile is loaded and return to WAIT_CONV after the
  // last row. There is no separate transform or inverse FSM state because the
  // associated work is combinational and is finalized on that last cycle.
  // Status: functionally changed.
  always_comb begin: CONV_NEXT_STATE_BLOCK
    st_conv_next = st_conv_current;  // default prevents latch inference
    priority case (st_conv_current)
      WAIT_CONV: begin
        if (st_input_current == CONV_INPUT) begin
          st_conv_next = HADAMARD;  // start streaming after the feature tile is complete
        end
      end
      HADAMARD: begin
        if (r_conv_multiply_count == $bits(r_conv_multiply_count)'(STREAM_CYCLES - 1)) begin
          st_conv_next = WAIT_CONV;
        end
      end
      default: st_conv_next = WAIT_CONV;
    endcase
  end

  // -------------------------------------------------------------------------
  // CONVOLUTION REGISTER BANK AND CONVOLUTION REGISTERS:  w_conv_end  -- r_conv_multiply_count
  // -------------------------------------------------------------------------
// `ifdef SIMULATION
//   time prev_time, curr_time;  // debug
// `endif

  // Latch the one-window completion event for the output FSM, keeping it high
  // until the corresponding output write phase has consumed the result.
  // Status: functionally changed.
  always_ff @(posedge clk or posedge reset) begin: CONV_END_FLAG_BLOCK
    if (reset)
      w_conv_end <= 0;
    else begin
      if (w_hadamard_last)
        w_conv_end <= 1;
      else if (st_output_current == WRITE_OUTPUT)
        w_conv_end <= 0;
        // else if (st_output_current == WRITE_OUTPUT || st_conv_current == WAIT_CONV) w_conv_end <= 0;
    end
  end

  // Count the four Hadamard cycles and provide the terminal predicate used by
  // both the convolution FSM and the input-tile release logic.
  // Status: functionally changed.
  always_ff @(posedge clk or posedge reset) begin: CONV_MULTIPLY_COUNTER_BLOCK
    if (reset)
      r_conv_multiply_count <= 0;
    else begin
      if (w_hadamard_start)
          r_conv_multiply_count <= 0;
      else if (st_conv_current == HADAMARD)
        r_conv_multiply_count <= r_conv_multiply_count + 1;
    end
  end

  // Transform produces the complete combinational matrix, but only one row
  // (or a partial row) is consumed at a time. FIXED_NUM_MULT is one of the
  // supported factors of the 16 Hadamard products.
  // Register only the streamed inverse accumulators and selection indices.
  // The combinational transform/MAC/inverse path computes one row per cycle,
  // reducing storage from a complete transformed matrix to row-sized state.
  // Status: added.
  always_ff @(posedge clk or posedge reset) begin: STREAMING_DATAPATH_BLOCK
    if (reset) begin
      r_out_acc        <= '{default: '0};
      r_stream_row_idx <= '0;
      r_stream_product_idx <= '0;
`ifdef STREAM_DEBUG
      stream_debug_had_count <= 0;
`endif
    end else begin
      if (w_hadamard_start) begin
        r_out_acc            <= '{default: '0};
        r_stream_row_idx     <= '0;
        r_stream_product_idx <= '0;
`ifdef STREAM_DEBUG
        $display("STREAM START");
`endif
      end else if (st_conv_current == HADAMARD) begin
          r_stream_product_idx <= r_stream_product_idx + PRODUCT_INDEX_WIDTH'(FIXED_NUM_MULT);
          r_out_acc        <= w_stream_acc_next;
          r_stream_row_idx <= r_stream_row_idx + 1'b1;
`ifdef STREAM_DEBUG
          $display("STREAM HAD product_base=%0d row=%0d", r_stream_product_idx, r_stream_row_idx);
          $write("  F:"); for (int unsigned d = 0; d < FIXED_NUM_MULT; d++) $write(" %0d", $signed(w_conv_feature[d])); $write("\n");
          $write("  G:"); for (int unsigned d = 0; d < FIXED_NUM_MULT; d++) $write(" %0d", $signed(r_input_weight[d])); $write("\n");
          $write("  P:"); for (int unsigned d = 0; d < FIXED_NUM_MULT; d++) $write(" %0d", $signed(w_conv_product[d][NBITS-1:0])); $write("\n");
          $write("  ACC_NEXT:"); for (int unsigned d = 0; d < CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE; d++) $write(" %0d", $signed(w_stream_acc_next[d])); $write("\n");
          stream_debug_had_count <= stream_debug_had_count + 1;
`endif
      end
    end
  end

  // Compute the complete C * input * C^T transform combinationally. Keeping
  // this operation combinational lets the sequential datapath consume only
  // the four values needed in the current Hadamard cycle.
  // Status: practically unchanged functionally.
  Transform #(
    .NBITS(NBITS),
    .CONV_OUTPUT_SIZE(CONV_OUTPUT_SIZE),
    .CONV_INPUT_SIZE(CONV_INPUT_SIZE),
    .HADAMARD_SIZE(HADAMARD_SIZE)
  ) trf (
      .pin (r_input_feat),
      .pout(w_conv_transform)
  );

  // Select one transformed row for the four parallel MACs. The product base
  // advances only at the Hadamard clock edge, so the
  // transform row selected here remains aligned with the rotated weights for
  // the whole following cycle. This removes the four-word row holding bank.
  // Status: added.
  assign w_conv_feature[0] = w_conv_transform[r_stream_product_idx];
  assign w_conv_feature[1] = w_conv_transform[r_stream_product_idx + 1'b1];
  assign w_conv_feature[2] = w_conv_transform[r_stream_product_idx + 2'd2];
  assign w_conv_feature[3] = w_conv_transform[r_stream_product_idx + 2'd3];
  // Four explicit multipliers implement the fixed four-MAC datapath. Their
  // outputs feed the row inverse immediately in the same cycle.
  // Status: functionally changed.
  Multip #(.QUANT(QUANT), .NBITS(NBITS)) multip0(
    .feature(w_conv_feature[0]), .weight(r_input_weight[0]), .product(w_conv_product[0]));
  Multip #(.QUANT(QUANT), .NBITS(NBITS)) multip1(
    .feature(w_conv_feature[1]), .weight(r_input_weight[1]), .product(w_conv_product[1]));
  Multip #(.QUANT(QUANT), .NBITS(NBITS)) multip2(
    .feature(w_conv_feature[2]), .weight(r_input_weight[2]), .product(w_conv_product[2]));
  Multip #(.QUANT(QUANT), .NBITS(NBITS)) multip3(
    .feature(w_conv_feature[3]), .weight(r_input_weight[3]), .product(w_conv_product[3]));

  // Pack the products into one inverse row and apply the incremental A1/A0
  // inverse. The accumulator carries the partial 2x2 output between rows.
  // Status: added.
  assign w_stream_product_row[0] = w_conv_product[0];
  assign w_stream_product_row[1] = w_conv_product[1];
  assign w_stream_product_row[2] = w_conv_product[2];
  assign w_stream_product_row[3] = w_conv_product[3];
  // These incremental inverse blocks replace the full-matrix Inverse module
  // and keep only the current row plus the accumulated 2x2 output.
  // Status: added.
  InverseRow inverse_row_current(.s_row(w_stream_product_row), .sigma(w_stream_sigma_current));
  InverseRowAccumulate inverse_row_acc(
    .row_idx(r_stream_row_idx), .acc_in(r_out_acc), .sigma(w_stream_sigma_current), .acc_out(w_stream_acc_next));
  // Both names intentionally refer to the same final value: output capture
  // occurs on the last Hadamard edge, with no extra inverse state or register.
  // Status: functionally changed.
  assign w_stream_final_output = w_stream_acc_next;
  assign w_stream_final_capture = w_stream_acc_next;


  // ----------------------------------------------------------------------------------------------------
  // -------  PART 4 - OUTPUT FSM AND READ/WRITE COUNTER -------------------------------------------------
  // ----------------------------------------------------------------------------------------------------



  // Register the output-FSM state, which sequences reset/read/accumulate/write
  // operations for each output tile and channel.
  // Status: practically unchanged functionally.
  always_ff @(posedge clk or posedge reset) begin: OUTPUT_STATE_REG_BLOCK
    if (reset) st_output_current <= WAIT_OUTPUT;
    else st_output_current <= st_output_next;
  end

  // Decode output ownership and handshakes. The FSM waits for w_conv_end,
  // reads prior channel partials when needed, then writes the completed tile.
  // Status: functionally changed.
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

  // Terminal predicates drive transitions at the three nested output levels:
  // input channel, spatial window, and output channel.
  // Status: practically unchanged functionally.
  assign w_output_last_channel_input = (r_output_channel_counter_input == CHANNEL_INPUT_COUNTER_WIDTH'(N_CHANNEL_IN - 1));
  assign w_output_last_channel_output = (r_output_channel_counter_output == CHANNEL_OUTPUT_COUNTER_WIDTH'(N_CHANNEL_OUT - 1));

  assign w_output_last_window_col = (r_output_window_counter_col == WINDOW_COUNTER_WIDTH'(WINDOW_COUNT_PER_COLUMN - 1));
  assign w_output_last_window_row = (r_output_window_counter_row == WINDOW_ROW_COUNTER_WIDTH'(WINDOW_COUNT_PER_LINE - 1));
  assign w_output_last_window_acc = (r_output_window_counter_acc == $bits(r_output_window_counter_acc)'((WINDOW_COUNT_PER_LINE * WINDOW_COUNT_PER_COLUMN) - 1));

  // Advance the input-channel accumulator and output-channel selector only
  // when the output FSM starts a new memory-address phase.
  // Status: practically unchanged functionally.
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

  // Track the current window in row-major order. These counters ensure that a
  // tile is advanced only after all input channels have been accumulated.
  // Status: practically unchanged functionally.
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
  // Count the nine reads/writes of a 2x2 output tile. The counters also gate
  // the transition from READ_OUTPUT to WRITE_OUTPUT.
  // Status: practically unchanged functionally.
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

  // Store prior-channel output values and capture the final inverse result.
  // The external write data is formed by adding these two banks below.
  // Status: functionally changed.
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
        r_output_write <= w_stream_final_capture;
    end
  end

  // Maintain the base output address for the current channel and spatial
  // window. Updates use row-major strides rather than a lookup table.
  // Status: practically unchanged functionally.
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

  // Generate the intra-tile read/write offset. The offset wraps at each 2x2
  // row so adjacent output pixels map to the feature-map stride correctly.
  // Status: practically unchanged functionally.
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

  // Compose the final row-major address from channel base, window column, and
  // window row, then drive the external memory protocol signals.
  // Status: practically unchanged functionally.
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
