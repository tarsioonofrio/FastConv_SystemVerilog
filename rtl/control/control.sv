/*
   CONVOLUTION CONTROLLER  - (V0 - FERNANDO MORAES)  - 24/ABRIL
*/
`timescale 1ns / 1ps

module Control
  #(
    parameter int unsigned N_CHANNEL_IN        = 3,
    parameter int unsigned N_CHANNEL_OUT       = 3,
    // parameter int unsigned KERNEL_SIZE         = 6,
    parameter int unsigned FEAT_INPUT_SIZE     = 17,
    parameter int unsigned FEAT_INPUT_WIDTH    = 8,
    parameter int unsigned NADDR               = 18,  // bits to p_input_addr the memory
    parameter int unsigned NBITS               = 20,
    parameter int unsigned QUANT               = 8,
    parameter int unsigned CONV_OUTPUT_SIZE    = 3,
    parameter int unsigned CONV_INPUT_SIZE     = 5,
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

  logic [NBITS-1:0] r_input_feat[(CONV_INPUT_SIZE * CONV_INPUT_SIZE) - 1:0];  // input feature register bank
  logic [NBITS-1:0] w_input_feat_next[(CONV_INPUT_SIZE * CONV_INPUT_SIZE) - 1:0];  // next values for feature shift bank
  logic [NADDR-1:0] r_input_addr_feat, r_input_addr_kernel;
  logic [NADDR-1:0] r_input_window_next;
  logic [(CONV_INPUT_SIZE * CONV_INPUT_SIZE) - 1:0] w_input_feat_en;  // write-enable per feature register
  logic w_input_last_window_col, w_input_last_input_acc, w_input_last_output_channel;

  localparam WINDOW_COUNT_PER_LINE = FEAT_INPUT_SIZE / 3;  // assuming output 3x3
  localparam WINDOW_COUNT_PER_COLUMN = FEAT_INPUT_WIDTH / 3;
  localparam WINDOW_COUNT_PER_CHANNEL = WINDOW_COUNT_PER_LINE * WINDOW_COUNT_PER_COLUMN;

  localparam WINDOW_COUNTER_WIDTH = $clog2(WINDOW_COUNT_PER_LINE * WINDOW_COUNT_PER_COLUMN);
  logic [WINDOW_COUNTER_WIDTH-1:0] r_input_window_counter_acc;

  localparam WINDOW_ROW_COUNTER_WIDTH = $clog2(WINDOW_COUNT_PER_LINE) + 1;
  logic [WINDOW_ROW_COUNTER_WIDTH-1:0] r_input_window_counter_col;

  localparam ADDR_INPUT_COUNTER_WIDTH = $clog2(WINDOW_COUNT_PER_COLUMN) + 1;
  logic [ADDR_INPUT_COUNTER_WIDTH-1:0] w_input_base_feat, r_input_addr_count;

  localparam CHANNEL_INPUT_COUNTER_WIDTH = $clog2(N_CHANNEL_IN) + 1;
  logic [CHANNEL_INPUT_COUNTER_WIDTH-1:0] r_input_channel_counter_input;

  localparam CHANNEL_OUTPUT_COUNTER_WIDTH = $clog2(N_CHANNEL_OUT) + 1;
  logic [CHANNEL_OUTPUT_COUNTER_WIDTH-1:0] r_input_channel_counter_output;

  // REGISTER BANK FOR THE WEIGHTS ////////////////////////////////////////////
  localparam int WEIGHT_CYCLES = HADAMARD_SIZE * HADAMARD_SIZE;
  localparam int WEIGHT_WIDTH = $clog2(WEIGHT_CYCLES)+1;
  logic [NBITS-1:0] r_input_weight[WEIGHT_CYCLES-1:0];
  logic [WEIGHT_CYCLES-1:0] w_input_weight_en;
  logic [WEIGHT_WIDTH-1:0] r_input_count_kernel;
  logic w_input_weight_done, w_input_write_done;

  logic [NBITS-1:0] r_conv_temp [HADAMARD_SIZE*HADAMARD_SIZE-1:0];
  logic [NBITS-1:0] w_conv_transform [HADAMARD_SIZE*HADAMARD_SIZE-1:0];
  logic [NBITS-1:0] w_conv_inverse [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0];
  logic [NBITS-1:0] r_conv_input[(CONV_INPUT_SIZE * CONV_INPUT_SIZE) - 1:0];  // convolution input register bank
  logic signed [NBITS-1+QUANT:0] w_conv_product [NUM_MULT-1:0];  // QUANT more bits for the multipliers
  logic [$clog2(STATE_MULT-1):0] r_conv_idx_in;
  logic [$clog2(STATE_MULT*NUM_MULT-1):0] r_conv_idx_out[NUM_MULT-1:0];
  logic w_conv_end;

  logic [3:0] r_output_read_count, r_output_write_count;
  logic [NBITS-1:0] r_output_write [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0];
  logic [NBITS-1:0] r_output_read [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0];
  logic [NADDR-1:0] w_output_addr;

  logic [WINDOW_COUNTER_WIDTH-1:0] r_output_window_counter_col;
  logic [WINDOW_ROW_COUNTER_WIDTH-1:0] r_output_window_counter_row;
  logic [WINDOW_COUNTER_WIDTH-1:0] r_output_window_counter_acc;
  logic [CHANNEL_INPUT_COUNTER_WIDTH-1:0] r_output_channel_counter_input;
  logic [CHANNEL_OUTPUT_COUNTER_WIDTH-1:0] r_output_channel_counter_output;
  logic w_output_last_window_row, w_output_last_window_col, w_output_last_input_channel, w_output_last_output_channel;
  logic [NADDR-1:0] r_output_addr_offset_read;
  logic [NADDR-1:0] r_output_addr_offset_write;
  logic [NADDR-1:0] w_output_addr_offset_read;
  logic [NADDR-1:0] w_output_addr_offset_write;
  logic [NADDR-1:0] r_output_addr_channel_base;
  logic [NADDR-1:0] r_output_addr_col_base;
  logic [NADDR-1:0] r_output_addr_row_base;


  // -------------------------------------------------------------------------
  // FSM STATES DECLARION
  // -------------------------------------------------------------------------
  typedef enum logic [3:0] {
    WAIT_INPUT,
    ADDRESS_INPUT,
    READ_WEIGHTS,
    READ_IN_10A,
    READ_IN_10B,
    READ_IN_15A,
    READ_IN_15B,
    READ_IN_15C,
    HOLD_WRITE,
    TRANSFER,
    NEXT_ROW_INPUT
  } type_st_input;
  type_st_input st_input_current, st_input_next;

  typedef enum logic [1:0] {
    WAIT_CONV,
    TRANSFORM,
    HADAMARD,
    INVERSE
  } type_st_conv;
  type_st_conv st_conv_current, st_conv_next;

  typedef enum logic [2:0] {
    WAIT_OUTPUT,
    ADDRESS_OUTPUT,
    RESET_OUTPUT,
    WRITE_OUTPUT,
    READ_OUTPUT,
    NEXT_ROW_OUTPUT
  } type_st_output;
  type_st_output st_output_current, st_output_next;

  // ----------------------------------------------------------------------------------------------------
  // -------  PART 1 - ADDRESS TO ACCESS THE IFMAP AND WEIGHT MEMORY ------------------------------------
  // ----------------------------------------------------------------------------------------------------
  assign p_input_addr = (st_input_current == READ_WEIGHTS) ? r_input_addr_kernel : r_input_addr_feat + NADDR'(r_input_addr_count);  // p_input_addr mux

  always_ff @(posedge clk or posedge reset) begin: INPUT_ADDR_POINTER_BLOCK
    if (reset) begin
      r_input_addr_feat <= '0;
      r_input_window_next <= 3;
    end
    else if ((st_input_current == READ_IN_10A && st_input_next == READ_IN_10B) || (st_input_current == READ_IN_10B && st_input_next == READ_IN_15A) || (st_input_current == READ_IN_15A && st_input_next == READ_IN_15B) || (st_input_current == READ_IN_15B && st_input_next == READ_IN_15C) || st_input_current == TRANSFER)
      r_input_addr_feat <= r_input_addr_feat + NADDR'(FEAT_INPUT_WIDTH);    // change internal p_input_addr in the state transition or in the TRANSFER state (CAUTION: PE)
    else if (st_input_current == NEXT_ROW_INPUT && !w_input_last_input_acc) begin  // when change the line, the read pointer moves 'r_input_window_next'
      r_input_addr_feat <= r_input_window_next + NADDR'(r_input_channel_counter_input * FEAT_INPUT_SIZE * FEAT_INPUT_WIDTH);  // restart for the first line
      r_input_window_next <= r_input_window_next + 3;
    end else if (st_input_current == ADDRESS_INPUT && w_input_last_input_acc) begin
      r_input_addr_feat <= r_input_addr_feat - NADDR'(FEAT_INPUT_WIDTH) + NADDR'(HADAMARD_SIZE) - 1;   // adjust the pointer to the next IFMAP
      r_input_window_next <= 3;

      if (r_input_channel_counter_input == CHANNEL_INPUT_COUNTER_WIDTH'(N_CHANNEL_IN-1) ) begin               // change the IFMAP
        r_input_addr_feat <= 0;
        `ifdef SIMULATION
            $display(
                "RESETANDO PARA O CANAL 0 - DEU A VOLTA NOS IFMAPS time=%0t %d (%0d) st_input_current = %s",
                $time, r_input_channel_counter_input, N_CHANNEL_IN, st_input_current.name()
            );
        `endif
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
        else if (w_input_last_output_channel) st_input_next = WAIT_INPUT;  //end processing
      READ_IN_10A: if (r_input_addr_count == 4) st_input_next = READ_IN_10B;  // read 5*5 values
      READ_IN_10B: if (r_input_addr_count == 4) st_input_next = READ_IN_15A;
      READ_IN_15A: if (r_input_addr_count == 4) st_input_next = READ_IN_15B;
      READ_IN_15B: if (r_input_addr_count == 4) st_input_next = READ_IN_15C;
      READ_IN_15C: if (r_input_addr_count == 4) st_input_next = TRANSFER;
      TRANSFER: st_input_next = HOLD_WRITE;  // p_start the convolution
      HOLD_WRITE:
        if (w_input_last_window_col && w_input_write_done) st_input_next = NEXT_ROW_INPUT;
          else if (w_input_write_done) st_input_next = READ_IN_15A;
        else st_input_next = HOLD_WRITE;
      NEXT_ROW_INPUT:
        if (w_input_last_input_acc) st_input_next = ADDRESS_INPUT;
        else st_input_next = READ_IN_10A;
      default: st_input_next = WAIT_INPUT;
    endcase
  end

  assign w_input_weight_done = (r_input_count_kernel == WEIGHT_WIDTH'(WEIGHT_CYCLES - 1));
  assign w_input_write_done = r_output_write_count == 0 || r_output_write_count == 8;  // compare to zero for the first write test or the last value (8) in the next convolutions

  assign w_input_last_window_col = (r_input_window_counter_col == WINDOW_ROW_COUNTER_WIDTH'(WINDOW_COUNT_PER_LINE));
  assign w_input_last_input_acc = (r_input_window_counter_acc == WINDOW_COUNTER_WIDTH'(WINDOW_COUNT_PER_CHANNEL));
  assign w_input_last_output_channel = (r_input_channel_counter_output == CHANNEL_OUTPUT_COUNTER_WIDTH'(N_CHANNEL_OUT));

  // TODO change to st_output_next == WAIT_OUTPUT
  assign p_end = ((st_input_next == WAIT_INPUT && w_input_last_output_channel));  // output to signalize the end of the convolution process

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
      else if (st_input_current inside {READ_IN_10A, READ_IN_10B, READ_IN_15A, READ_IN_15B, READ_IN_15C}) begin
        if (r_input_addr_count == 4)
          r_input_addr_count <= 0;
        else
          r_input_addr_count <= r_input_addr_count + 1;
      end
    end
  end

  assign w_input_base_feat = (st_input_current == READ_IN_10A) ? 0 :
                             (st_input_current == READ_IN_10B) ? 1 :
                             (st_input_current == READ_IN_15A) ? 2 :
                             (st_input_current == READ_IN_15B) ? 3 :
                             (st_input_current == READ_IN_15C) ? 4 :  0;


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
    for (int unsigned i = 0; i < 25; i++)  // connection between register outputs to register inputs
    w_input_feat_next[i] = p_input_data;

    w_input_feat_next[0]  = (st_input_current == READ_IN_10A) ? p_input_data : r_input_feat[3];     // makes the shifts - minimize muxes
    w_input_feat_next[1]  = (st_input_current == READ_IN_10B) ? p_input_data : r_input_feat[4];
    w_input_feat_next[5]  = (st_input_current == READ_IN_10A) ? p_input_data : r_input_feat[8];
    w_input_feat_next[6]  = (st_input_current == READ_IN_10B) ? p_input_data : r_input_feat[9];
    w_input_feat_next[10] = (st_input_current == READ_IN_10A) ? p_input_data : r_input_feat[13];
    w_input_feat_next[11] = (st_input_current == READ_IN_10B) ? p_input_data : r_input_feat[14];
    w_input_feat_next[15] = (st_input_current == READ_IN_10A) ? p_input_data : r_input_feat[18];
    w_input_feat_next[16] = (st_input_current == READ_IN_10B) ? p_input_data : r_input_feat[19];
    w_input_feat_next[20] = (st_input_current == READ_IN_10A) ? p_input_data : r_input_feat[23];
    w_input_feat_next[21] = (st_input_current == READ_IN_10B) ? p_input_data : r_input_feat[24];
  end

  always_comb begin: INPUT_SHIFT_WE_BLOCK  // 'w_input_feat_en' to write into the register bank r_input_feat
    w_input_feat_en = '0;
    case (st_input_current)
      READ_IN_10A, READ_IN_10B, READ_IN_15A, READ_IN_15B, READ_IN_15C:
        w_input_feat_en[w_input_base_feat + r_input_addr_count * 5] = 1'b1;
      TRANSFER:
        w_input_feat_en = 25'b0001100011000110001100011;  // make the shift
      default:
        w_input_feat_en = '0;
    endcase
  end

  always_ff @(posedge clk or posedge reset) begin: INPUT_FEATURE_REG_BLOCK  // initializes and write into the register bank and convolution register bank
    if (reset)
      for (int unsigned i = 0; i < 25; i++)
        r_input_feat[i] <= '0;
    else
      for (int unsigned i = 0; i < 25; i++)
        if (w_input_feat_en[i])
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
    end else begin
      for (int unsigned i = 0; i < WEIGHT_CYCLES; i++)
        if (w_input_weight_en[i])
          r_input_weight[i] <= p_input_data;
    end
  end

  // ----------------------------------------------------------------------------------------------------
  // -------  PART 3 - CONVOLUTION CONTROL AND CONVOLUTION MODULES --------------------------------------
  // ----------------------------------------------------------------------------------------------------
  localparam CONV_MULTIPLY_COUNTER_WIDTH = $clog2(STATE_MULT) + 1;
  logic [CONV_MULTIPLY_COUNTER_WIDTH-1:0] r_conv_multiply_count;

  always_ff @(posedge clk or posedge reset) begin: CONV_STATE_REG_BLOCK
    if (reset)
      st_conv_current <= WAIT_CONV;
    else
      st_conv_current <= st_conv_next;
  end

  always_comb begin: CONV_NEXT_STATE_BLOCK
    // st_conv_next = st_conv_current;  // default
    priority case (st_conv_current)
      WAIT_CONV: begin
        if (st_input_current == TRANSFER) begin
          st_conv_next = TRANSFORM;  // starts the convolution after moving data to the convolution register bank
        end
      end
      TRANSFORM:
        st_conv_next = HADAMARD;
      HADAMARD: begin
        if (r_conv_multiply_count == CONV_MULTIPLY_COUNTER_WIDTH'(STATE_MULT - 1)) begin
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
`ifdef SIMULATION
  time prev_time, curr_time;  // debug
`endif

  always_ff @(posedge clk or posedge reset) begin: CONV_INPUT_REG_BLOCK  // register bank for the convolution
    if (reset)
      for (int unsigned i = 0; i < 25; i++)
        r_conv_input[i] <= '0;
    else begin
      if (st_input_current == TRANSFER) begin  // fill the convolution register bank
        for (int unsigned i = 0; i < 25; i++)
          r_conv_input[i] <= r_input_feat[i];
          `ifdef SIMULATION
            curr_time = $time;  // debug
            $display("current time = %0t | previous time = %0t | diff = %0t", curr_time, prev_time, (curr_time - prev_time));
            prev_time <= curr_time;
          `endif
      end
    end
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
      r_conv_idx_in <= 1'b0;
      r_conv_temp <= '{default: '0};
    end else begin
      unique case (st_conv_current)
        WAIT_CONV: begin
          r_conv_idx_in <= 1'b0;
          // if (p_start) begin
          //   r_conv_temp[C1_SIZE*C1_SIZE-1:0] <= r_conv_input;
          // end
        end
        TRANSFORM: begin
          r_conv_temp <= w_conv_transform;
        end
        HADAMARD: begin
          r_conv_idx_in <= r_conv_idx_in + 1;
          for (int i = 0; i < NUM_MULT; i++) begin
            r_conv_temp[r_conv_idx_out[i]] <= w_conv_product[i];
          end
        end
        INVERSE: begin
        end
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
    for (genvar i = 0; i < NUM_MULT; i++) begin : MULTIP_BLOCK
      Multip #(
        .QUANT(QUANT),
        .NBITS(NBITS)
      )
      multip(
        .feature(r_conv_temp[r_conv_idx_out[i]]),
        .weight(r_input_weight[r_conv_idx_out[i]]),
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

  logic w_output_last_window_acc;


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
        if (w_conv_end && r_output_read_count == 8)
          st_output_next = WRITE_OUTPUT;
      WRITE_OUTPUT:
        if (r_output_write_count == 8) begin
          if (((r_output_channel_counter_input) > 0) && !w_output_last_window_row)
            st_output_next = READ_OUTPUT;      // accumulate next input channel
          else
          if ((r_output_channel_counter_input) == 0 && !w_output_last_window_row)
            st_output_next = RESET_OUTPUT;     // next window, same output channel
          else
          if (w_input_last_output_channel)
            st_output_next = WAIT_OUTPUT;      // global termination from input traversal
          else
          if (w_output_last_window_row)
            st_output_next = NEXT_ROW_OUTPUT;   // change output channel only
          // else if (w_output_last_window_acc)
          //   st_output_next = WAIT_OUTPUT;      // end processing
            // end else begin
            //   st_output_next = WRITE_OUTPUT;
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

  assign w_output_last_input_channel = (r_output_channel_counter_input == CHANNEL_INPUT_COUNTER_WIDTH'(N_CHANNEL_IN - 1));
  assign w_output_last_output_channel = (r_output_channel_counter_output == CHANNEL_OUTPUT_COUNTER_WIDTH'(N_CHANNEL_OUT - 1));

  assign w_output_last_window_col = (r_output_window_counter_col == WINDOW_COUNTER_WIDTH'(WINDOW_COUNT_PER_COLUMN - 1));
  assign w_output_last_window_row = (r_output_window_counter_row == WINDOW_ROW_COUNTER_WIDTH'(WINDOW_COUNT_PER_LINE - 1));
  assign w_output_last_window_acc = (r_output_window_counter_acc == WINDOW_COUNT_PER_CHANNEL'(WINDOW_COUNT_PER_CHANNEL - 1));

  always_ff @(posedge clk or posedge reset) begin: OUTPUT_CONTROL_COUNTERS_BLOCK
    if (reset) begin
      r_output_channel_counter_input  <= '0;
      r_output_channel_counter_output <= '0;
    end else if (st_output_current == ADDRESS_OUTPUT) begin
      if (w_output_last_input_channel)  begin
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
    end else if (st_output_current == WRITE_OUTPUT && r_output_write_count == 8) begin
      // Advance window only after accumulating all input channels for this output window.
      r_output_window_counter_acc <= r_output_window_counter_acc + 1'b1;
      r_output_window_counter_row <= r_output_window_counter_row + 1'b1;
    end else if (st_output_current == NEXT_ROW_OUTPUT) begin
      r_output_window_counter_col <= r_output_window_counter_col + 1'b1;
      r_output_window_counter_row <= 0;
    end else if (st_output_current == ADDRESS_OUTPUT) begin
      // New output channel starts from first windowessa linha serve pra que? [@control.sv (582:583)](file:///home/tarsio/gaph/FastConv_SystemVerilog/rtl/control/control.sv#L582:583)
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
        if (r_output_write_count < 8)
          r_output_write_count <= r_output_write_count + 1;
        else
          r_output_write_count <= 8;
      end else if (st_output_current == RESET_OUTPUT || st_output_current == READ_OUTPUT) begin
        r_output_write_count <= 0;
        if (p_output_valid) begin
          if (r_output_read_count < 8)
            r_output_read_count <= r_output_read_count + 1;
          else
            r_output_read_count <= 8;
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

  localparam int FEAT_OUTPUT_SIZE = (FEAT_INPUT_SIZE - 2);
  localparam int OUTPUT_RETURN_COLUMN = 2 * FEAT_OUTPUT_SIZE - 1;

  always_ff @(posedge clk or posedge reset) begin: OUTPUT_ADDR_POINTER_BLOCK
    if (reset) begin
      r_output_addr_channel_base <= '0;
      r_output_addr_col_base <= '0;
      r_output_addr_row_base <= '0;
    end else begin
      // Address generation for output map:
      // - slide window every completed WRITE_OUTPUT window
      // - when one input-channel pass finishes, restart window scan at channel base
      // - when last input channel finishes, advance to next output channel base
      if (st_output_current == WRITE_OUTPUT && r_output_write_count == 8) begin
        if (w_output_last_window_acc) begin
          r_output_addr_col_base <= '0;
          r_output_addr_row_base <= '0;
          if (w_output_last_input_channel && !w_output_last_output_channel)
            r_output_addr_channel_base <= r_output_addr_channel_base + NADDR'(FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE);
        end else if (w_output_last_window_row) begin
          r_output_addr_row_base <= '0;
          if (w_output_last_window_col)
            r_output_addr_col_base <= '0;
          else
            r_output_addr_col_base <= r_output_addr_col_base + NADDR'(CONV_OUTPUT_SIZE);
        end else begin
          r_output_addr_row_base <= r_output_addr_row_base + NADDR'(FEAT_OUTPUT_SIZE * CONV_OUTPUT_SIZE);
        end
      end
      if (st_output_current == ADDRESS_OUTPUT) begin
        // New channel starts at first window position.
        r_output_addr_col_base <= '0;
        r_output_addr_row_base <= '0;
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
        if (r_output_read_count == 8)
          r_output_addr_offset_read <= r_output_addr_offset_read;
        else
        if ((r_output_read_count == 2) || (r_output_read_count == 5))
          r_output_addr_offset_read <= r_output_addr_offset_read - NADDR'(OUTPUT_RETURN_COLUMN);
        else
          r_output_addr_offset_read <= r_output_addr_offset_read + NADDR'(FEAT_OUTPUT_SIZE);
      end

      if (st_output_current != WRITE_OUTPUT) begin
        r_output_addr_offset_write <= '0;
      end else begin
        // Prepare offset for next WRITE cycle without lookup table.
        if (r_output_write_count == 8)
          r_output_addr_offset_write <= r_output_addr_offset_write;
        else
        if ((r_output_write_count == 2) || (r_output_write_count == 5))
          r_output_addr_offset_write <= r_output_addr_offset_write - NADDR'(OUTPUT_RETURN_COLUMN);
        else
          r_output_addr_offset_write <= r_output_addr_offset_write + NADDR'(FEAT_OUTPUT_SIZE);
      end
    end
  end

  assign w_output_addr = r_output_addr_channel_base + r_output_addr_col_base + r_output_addr_row_base;
  assign p_output_data_write = r_output_write[r_output_write_count] + r_output_read[r_output_write_count];
  assign p_output_addr = (st_output_current == READ_OUTPUT) ? w_output_addr + r_output_addr_offset_read : w_output_addr + r_output_addr_offset_write;  // p_input_addr mux
  assign p_output_en = (((st_output_current == READ_OUTPUT) && r_output_read_count < 8) || (st_output_current == WRITE_OUTPUT)) ? '1 : '0;
  assign p_output_wr = (st_output_current == WRITE_OUTPUT && !w_input_last_output_channel) ? '1 : '0;

endmodule
