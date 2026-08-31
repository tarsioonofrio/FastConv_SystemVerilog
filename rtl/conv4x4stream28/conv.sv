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
    parameter int unsigned CONV_OUTPUT_SIZE    = 4,
    parameter int unsigned CONV_INPUT_SIZE     = 6,
    parameter int unsigned HADAMARD_SIZE       = 6,
    parameter int unsigned NUM_MULT            = 6,
    parameter int unsigned STATE_MULT          = 6
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

  logic [NBITS-1:0] r_input_feat[(CONV_INPUT_SIZE * CONV_INPUT_SIZE) - 1:0];  // input feature register bank
  logic [NBITS-1:0] w_input_feat_next[(CONV_INPUT_SIZE * CONV_INPUT_SIZE) - 1:0];  // next values for feature shift bank
  logic [NADDR-1:0] r_input_addr_feat;
  logic [NADDR-1:0] r_input_addr_kernel;
  logic [NADDR-1:0] r_input_window_next;
  logic [(CONV_INPUT_SIZE * CONV_INPUT_SIZE) - 1:0] w_input_feat_en;  // write-enable per feature register
  logic w_input_feat_write_valid;
  logic r_stream_transfer_pending;
  logic w_input_last_window_col;
  logic w_input_last_window_acc;
  logic w_input_last_channel_output;

  localparam WINDOW_COUNT_PER_LINE = (FEAT_INPUT_SIZE - 2 + CONV_OUTPUT_SIZE - 1) / CONV_OUTPUT_SIZE;
  localparam WINDOW_COUNT_PER_COLUMN = (FEAT_INPUT_SIZE - 2 + CONV_OUTPUT_SIZE - 1) / CONV_OUTPUT_SIZE;

  // Include the terminal value (64) in the accumulator counter so the final
  // tile is detected instead of aliasing to counter zero.
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

  logic [NBITS-1:0] w_conv_transform [HADAMARD_SIZE*HADAMARD_SIZE-1:0];
  logic signed [NBITS-1+QUANT:0] w_conv_product [NUM_MULT-1:0];  // QUANT more bits for the multipliers
  logic w_conv_end;
  logic w_conv_input_release;

  localparam int ROW_INDEX_WIDTH = f_width_min1(HADAMARD_SIZE);
  logic [NBITS-1:0] r_d_row [HADAMARD_SIZE-1:0];
  logic [NBITS-1:0] r_s_row [HADAMARD_SIZE-1:0];
  logic [NBITS-1:0] r_out_acc [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0];
  logic [ROW_INDEX_WIDTH-1:0] r_stream_row_idx;
  logic r_s_valid;
  logic [NBITS-1:0] w_stream_sigma [CONV_OUTPUT_SIZE-1:0];
  logic [NBITS-1:0] w_stream_sigma_current [CONV_OUTPUT_SIZE-1:0];
  logic [NBITS-1:0] w_stream_acc_next [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0];
  logic [NBITS-1:0] w_stream_final_output [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0];
  logic [NBITS-1:0] w_stream_final_capture [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0];
  logic [NBITS-1:0] w_stream_product_row [HADAMARD_SIZE-1:0];
  logic [NBITS-1:0] w_conv_feature [NUM_MULT-1:0];

  localparam OUTPUT_RW_COUNT_MAX = (CONV_OUTPUT_SIZE * CONV_OUTPUT_SIZE) - 1;
  localparam OUTPUT_RW_COUNT_WIDTH = f_width_min1(CONV_OUTPUT_SIZE * CONV_OUTPUT_SIZE);
  logic [OUTPUT_RW_COUNT_WIDTH-1:0] r_output_read_count;
  logic [OUTPUT_RW_COUNT_WIDTH-1:0] r_output_write_count;
  logic [NBITS-1:0] r_output_write [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0];
  logic [NBITS-1:0] r_output_read [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0];
  logic [NADDR-1:0] w_output_addr;

  localparam FEAT_OUTPUT_SIZE = (FEAT_INPUT_SIZE - 2);
  // Output memory uses a tile-aligned physical surface.  The testbench crops
  // this surface back to the logical FEAT_OUTPUT_SIZE x FEAT_OUTPUT_SIZE map.
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
  assign p_input_addr = (st_input_current == READ_WEIGHTS) ? r_input_addr_kernel : r_input_addr_feat + NADDR'(r_input_addr_count);  // p_input_addr mux

  always_ff @(posedge clk or posedge reset) begin: INPUT_ADDR_POINTER_BLOCK
    if (reset) begin
      r_input_addr_feat <= '0;
      r_input_window_next <= CONV_OUTPUT_SIZE;
    end
    else if ((st_input_current == READ_IN_6A && st_input_next == READ_IN_6B) || (st_input_current == READ_IN_6B && st_input_next == READ_IN_6C) || (st_input_current == READ_IN_6C && st_input_next == READ_IN_6D) || (st_input_current == READ_IN_6D && st_input_next == READ_IN_6E) || (st_input_current == READ_IN_6E && st_input_next == READ_IN_6F) || st_input_current == TRANSFER)
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
        if (w_input_weight_done) st_input_next = READ_IN_6A;
        else if (w_input_last_channel_output) st_input_next = WAIT_INPUT;  //end processing
      READ_IN_6A: if (r_input_addr_count == (CONV_INPUT_SIZE - 1)) st_input_next = READ_IN_6B;  // read 5*5 values
      READ_IN_6B: if (r_input_addr_count == (CONV_INPUT_SIZE - 1)) st_input_next = READ_IN_6C;
      READ_IN_6C: if (r_input_addr_count == (CONV_INPUT_SIZE - 1)) st_input_next = READ_IN_6D;
      READ_IN_6D: if (r_input_addr_count == (CONV_INPUT_SIZE - 1)) st_input_next = READ_IN_6E;
      READ_IN_6E: if (r_input_addr_count == (CONV_INPUT_SIZE - 1)) st_input_next = READ_IN_6F;
      READ_IN_6F: if (r_input_addr_count == (CONV_INPUT_SIZE - 1)) st_input_next = CONV_INPUT;
      CONV_INPUT: st_input_next = TRANSFER;
      TRANSFER: st_input_next = HOLD_WRITE;  // p_start the convolution
      HOLD_WRITE:
        if (w_conv_input_release && w_input_last_window_col && w_input_write_done) st_input_next = NEXT_ROW_INPUT;
          else if (w_conv_input_release && w_input_write_done) st_input_next = READ_IN_6C;
        else st_input_next = HOLD_WRITE;
      NEXT_ROW_INPUT:
        if (w_input_last_window_acc) st_input_next = ADDRESS_INPUT;
        else st_input_next = READ_IN_6A;
      default: st_input_next = WAIT_INPUT;
    endcase
  end

  assign w_input_weight_done = (r_input_count_kernel == WEIGHT_WIDTH'(WEIGHT_CYCLES - 1));
  assign w_input_write_done = r_output_write_count == 0 ||
                              r_output_write_count == OUTPUT_RW_COUNT_MAX;

  assign w_input_last_window_col = (r_input_window_counter_col == WINDOW_ROW_COUNTER_WIDTH'(WINDOW_COUNT_PER_LINE));
  assign w_input_last_window_acc = (r_input_window_counter_acc == WINDOW_COUNTER_WIDTH'(WINDOW_COUNT_PER_LINE * WINDOW_COUNT_PER_COLUMN));
  assign w_input_last_channel_output = (r_input_channel_counter_output == CHANNEL_OUTPUT_COUNTER_WIDTH'(N_CHANNEL_OUT));
  assign w_conv_input_release = st_conv_current == INVERSE ||
                                (st_conv_current == HADAMARD &&
                                 r_stream_row_idx == ROW_INDEX_WIDTH'(HADAMARD_SIZE - 1));

  assign p_end = (st_output_current == WRITE_OUTPUT) &&
                 (r_output_write_count == OUTPUT_RW_COUNT_WIDTH'(OUTPUT_RW_COUNT_MAX)) &&
                 w_input_last_channel_output;  // Signal completion only after the final output write.

  // -------------------------------------------------------------------------
  // READING REGISTERS
  // -------------------------------------------------------------------------

  always_ff @(posedge clk or posedge reset) begin: INPUT_READ_COUNTER_BLOCK
    if (reset) begin
      r_input_addr_count <= 0;
    end else if (st_conv_current == HADAMARD) begin         // rotate transformed weights with each streamed feature row
      for (int unsigned i = 0; i < (WEIGHT_CYCLES-NUM_MULT); i++) begin
        r_input_weight[i] <= r_input_weight[i + NUM_MULT];
      end
      for (int unsigned i = (WEIGHT_CYCLES-NUM_MULT); i < WEIGHT_CYCLES; i++) begin
        r_input_weight[i] <= r_input_weight[i - (WEIGHT_CYCLES-NUM_MULT)];
      end
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
      w_input_feat_next[i] = p_input_data;

    w_input_feat_next[0] = (st_input_current == READ_IN_6A) ? p_input_data : r_input_feat[4];
    w_input_feat_next[1] = (st_input_current == READ_IN_6B) ? p_input_data : r_input_feat[5];
    w_input_feat_next[6] = (st_input_current == READ_IN_6A) ? p_input_data : r_input_feat[10];
    w_input_feat_next[7] = (st_input_current == READ_IN_6B) ? p_input_data : r_input_feat[11];

    if (st_input_current == TRANSFER ||
        (r_stream_transfer_pending && w_conv_input_release)) begin
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

  assign w_input_feat_wr_index = INPUT_FEAT_INDEX_WIDTH'(w_input_base_feat) +
                                 (INPUT_FEAT_INDEX_WIDTH'(r_input_addr_count) *
                                  INPUT_FEAT_INDEX_WIDTH'(CONV_INPUT_SIZE));

  always_comb begin: INPUT_SHIFT_WE_BLOCK  // 'w_input_feat_en' to write into the register bank r_input_feat
    w_input_feat_en = '0;
    case (st_input_current)
      READ_IN_6A, READ_IN_6B, READ_IN_6C, READ_IN_6D, READ_IN_6E, READ_IN_6F:
        w_input_feat_en[w_input_feat_wr_index] = 1'b1;
      TRANSFER:
        // Keep the completed tile intact for the transform snapshot.  The
        // window shift is applied once when the inverse releases it.
        w_input_feat_en = '0;
      default:
        if (r_stream_transfer_pending && w_conv_input_release)
          w_input_feat_en = 36'b000011000011000011000011000011000011;
    endcase
  end

  assign w_input_feat_write_valid = (r_stream_transfer_pending && w_conv_input_release) ||
                                    p_input_valid;

  always_ff @(posedge clk or posedge reset) begin: STREAM_TRANSFER_PENDING_BLOCK
    if (reset)
      r_stream_transfer_pending <= 1'b0;
    else if (st_input_current == TRANSFER)
      r_stream_transfer_pending <= 1'b1;
    else if (r_stream_transfer_pending && w_conv_input_release)
      r_stream_transfer_pending <= 1'b0;
  end

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
    if (st_input_current == READ_WEIGHTS) begin
      // The generated transform matrix exposes each output column as a
      // contiguous lane, while the packed weight stream is row-major.
      for (int unsigned i = 0; i < WEIGHT_CYCLES; i++)
        if (r_input_count_kernel == WEIGHT_WIDTH'(i))
          w_input_weight_en[(i % HADAMARD_SIZE) * HADAMARD_SIZE +
                            (i / HADAMARD_SIZE)] = 1'b1;
    end
  end

  always_ff @(posedge clk or posedge reset) begin: WEIGHT_REG_BLOCK
    if (reset) begin
      for (int unsigned i = 0; i < WEIGHT_CYCLES; i++)
        r_input_weight[i] <= '0;
    end else if (st_input_current == READ_WEIGHTS) begin
      // A new weight load has priority over the final HADAMARD rotation.
      for (int unsigned i = 0; i < WEIGHT_CYCLES; i++)
        if (w_input_weight_en[i])
          r_input_weight[i] <= p_input_data;
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

  always_ff @(posedge clk or posedge reset) begin: STREAMING_DATAPATH_BLOCK
        if (reset) begin
          r_d_row          <= '{default: '0};
          r_s_row          <= '{default: '0};
          r_out_acc        <= '{default: '0};
          r_stream_row_idx <= '0;
          r_s_valid        <= 1'b0;
        end else begin
          unique case (st_conv_current)
            TRANSFORM: begin
              for (int unsigned i = 0; i < HADAMARD_SIZE; i++)
                r_d_row[i] <= w_conv_transform[i];
              r_out_acc        <= '{default: '0};
              r_stream_row_idx <= '0;
              r_s_valid        <= 1'b0;
            end
            HADAMARD: begin
              if (r_s_valid)
                r_out_acc <= w_stream_acc_next;
              for (int unsigned i = 0; i < HADAMARD_SIZE; i++)
                r_s_row[i] <= w_conv_product[i][NBITS-1:0];
              r_s_valid <= 1'b1;
              if (r_stream_row_idx < ROW_INDEX_WIDTH'(HADAMARD_SIZE - 1)) begin
                unique case (r_stream_row_idx)
                  0: for (int unsigned i = 0; i < HADAMARD_SIZE; i++) r_d_row[i] <= w_conv_transform[HADAMARD_SIZE + i];
                  1: for (int unsigned i = 0; i < HADAMARD_SIZE; i++) r_d_row[i] <= w_conv_transform[(2 * HADAMARD_SIZE) + i];
                  2: for (int unsigned i = 0; i < HADAMARD_SIZE; i++) r_d_row[i] <= w_conv_transform[(3 * HADAMARD_SIZE) + i];
                  3: for (int unsigned i = 0; i < HADAMARD_SIZE; i++) r_d_row[i] <= w_conv_transform[(4 * HADAMARD_SIZE) + i];
                  4: for (int unsigned i = 0; i < HADAMARD_SIZE; i++) r_d_row[i] <= w_conv_transform[(5 * HADAMARD_SIZE) + i];
                  default: begin end
                endcase
              end
              r_stream_row_idx <= r_stream_row_idx + 1'b1;
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

  generate
    for (genvar i = 0; i < NUM_MULT; i++) begin : MULTIP_BLOCK
      assign w_conv_feature[i] = r_d_row[i];
      Multip #(
        .QUANT(QUANT),
        .NBITS(NBITS)
      )
      multip(
        .feature(w_conv_feature[i]),
        .weight(r_input_weight[i]),
        .product(w_conv_product[i])
      );
    end
  endgenerate

  InverseRow inverse_row(
        .s_row(r_s_row),
        .sigma(w_stream_sigma)
      );
  generate
    for (genvar j = 0; j < HADAMARD_SIZE; j++) begin : STREAM_PRODUCT_ROW_BLOCK
        assign w_stream_product_row[j] = w_conv_product[j][NBITS-1:0];
    end
  endgenerate
  InverseRow inverse_row_current(
        .s_row(w_stream_product_row),
        .sigma(w_stream_sigma_current)
      );
  InverseRowAccumulate inverse_row_acc(
        .row_idx(r_stream_row_idx - 1'b1),
        .acc_in(r_out_acc),
        .sigma(w_stream_sigma),
        .acc_out(w_stream_acc_next)
      );
  InverseRowAccumulate inverse_row_finalize(
        .row_idx(ROW_INDEX_WIDTH'(HADAMARD_SIZE - 1)),
        .acc_in(r_out_acc),
        .sigma(w_stream_sigma),
        .acc_out(w_stream_final_output)
      );
  InverseRowAccumulate inverse_row_capture(
        .row_idx(ROW_INDEX_WIDTH'(HADAMARD_SIZE - 1)),
        .acc_in(w_stream_acc_next),
        .sigma(w_stream_sigma_current),
        .acc_out(w_stream_final_capture)
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
          st_output_next = (r_output_channel_counter_input > 0) ? READ_OUTPUT : WRITE_OUTPUT;
      READ_OUTPUT:
        if (w_conv_end && r_output_read_count == OUTPUT_RW_COUNT_WIDTH'(OUTPUT_RW_COUNT_MAX))
          st_output_next = WRITE_OUTPUT;
      WRITE_OUTPUT:
        if (r_output_write_count == OUTPUT_RW_COUNT_WIDTH'(OUTPUT_RW_COUNT_MAX)) begin
          if (((r_output_channel_counter_input) > 0) && !w_output_last_window_row)
            st_output_next = READ_OUTPUT;
          else if ((r_output_channel_counter_input) == 0 && !w_output_last_window_row)
            st_output_next = RESET_OUTPUT;
          else if (w_input_last_channel_output)
            st_output_next = WAIT_OUTPUT;
          else if (w_output_last_window_row)
            st_output_next = NEXT_ROW_OUTPUT;
        end
      NEXT_ROW_OUTPUT:
        if (w_output_last_window_col)
          st_output_next = ADDRESS_OUTPUT;
        else if ((r_input_channel_counter_input) == 0)
          st_output_next = RESET_OUTPUT;
        else if ((r_input_channel_counter_input) > 0)
          st_output_next = READ_OUTPUT;
      ADDRESS_OUTPUT:
        if ((r_input_channel_counter_input) == 0)
          st_output_next = RESET_OUTPUT;
        else if ((r_input_channel_counter_input) > 0)
          st_output_next = READ_OUTPUT;
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
      if (w_output_last_channel_input) begin
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
      r_output_window_counter_acc <= r_output_window_counter_acc + 1'b1;
      r_output_window_counter_row <= r_output_window_counter_row + 1'b1;
    end else if (st_output_current == NEXT_ROW_OUTPUT) begin
      r_output_window_counter_col <= r_output_window_counter_col + 1'b1;
      r_output_window_counter_row <= 0;
    end else if (st_output_current == ADDRESS_OUTPUT) begin
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
          r_stream_row_idx == ROW_INDEX_WIDTH'(HADAMARD_SIZE - 1))
        r_output_write <= w_stream_final_capture;
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
        if ((r_output_read_count % CONV_OUTPUT_SIZE) == (CONV_OUTPUT_SIZE - 1))
          r_output_addr_offset_read <= r_output_addr_offset_read - OUTPUT_ADDR_OFFSET_WIDTH'(((CONV_OUTPUT_SIZE - 1) * OUTPUT_PHYSICAL_SIZE) - 1);
        else
          r_output_addr_offset_read <= r_output_addr_offset_read + OUTPUT_ADDR_OFFSET_WIDTH'(OUTPUT_PHYSICAL_SIZE);
      end

      if (st_output_current != WRITE_OUTPUT) begin
        r_output_addr_offset_write <= '0;
      end else begin
        // Prepare offset for next WRITE cycle without lookup table.
        if (r_output_write_count == OUTPUT_RW_COUNT_WIDTH'(OUTPUT_RW_COUNT_MAX))
          r_output_addr_offset_write <= r_output_addr_offset_write;
        else
        if ((r_output_write_count % CONV_OUTPUT_SIZE) == (CONV_OUTPUT_SIZE - 1))
          r_output_addr_offset_write <= r_output_addr_offset_write - OUTPUT_ADDR_OFFSET_WIDTH'(((CONV_OUTPUT_SIZE - 1) * OUTPUT_PHYSICAL_SIZE) - 1);
        else
          r_output_addr_offset_write <= r_output_addr_offset_write + OUTPUT_ADDR_OFFSET_WIDTH'(OUTPUT_PHYSICAL_SIZE);
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
