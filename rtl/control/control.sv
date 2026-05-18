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
    parameter int unsigned TRANSFORM_SIZE      = 3,
    parameter int unsigned INVERSE_SIZE        = 5,
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
    output logic[NADDR-1:0] p_output_addr,         // Address issued to the output RAM
    output [NBITS-1:0] p_output_data_write,        // Data driven into the output RAM on writes
    input  [NBITS-1:0] p_output_data_read,         // Data captured from the output RAM on reads
    input  logic p_output_valid                    // Read-valid flag from the output RAM
  );

  logic [NBITS-1:0] r_feat_input[(INVERSE_SIZE * INVERSE_SIZE) - 1:0];  // input feature register bank
  logic [NBITS-1:0] r_conv_input[(INVERSE_SIZE * INVERSE_SIZE) - 1:0];  // convolution input register bank
  logic [NBITS-1:0] w_next_feat_input[(INVERSE_SIZE * INVERSE_SIZE) - 1:0];  // next values for feature shift bank
  logic [(INVERSE_SIZE * INVERSE_SIZE) - 1:0] w_feat_input_write_en;  // write-enable per feature register
  logic w_conv_end, last_line, last_input, last_output;
  logic [3:0] r_output_read_count, r_output_write_count;
  logic [NADDR-1:0] r_addr_pointer_input, r_window_row_step, r_addr_pointer_kernel;

  localparam CHANNEL_INPUT_COUNTER_WIDTH = $clog2(N_CHANNEL_IN) + 1;
  logic [CHANNEL_INPUT_COUNTER_WIDTH-1:0] r_channel_counter_input;

  localparam CHANNEL_OUTPUT_COUNTER_WIDTH = $clog2(N_CHANNEL_OUT) + 1;
  logic [CHANNEL_OUTPUT_COUNTER_WIDTH-1:0] r_channel_counter_output;

  localparam WINDOW_COUNT_PER_LINE = FEAT_INPUT_SIZE / 3;  // assuming output 3x3
  localparam WINDOW_COUNT_PER_COLUMN = FEAT_INPUT_WIDTH / 3;
  localparam WINDOW_COUNT_PER_CHANNEL = WINDOW_COUNT_PER_LINE * WINDOW_COUNT_PER_COLUMN;

  localparam WINDOW_COUNTER_WIDTH = $clog2(WINDOW_COUNT_PER_LINE * WINDOW_COUNT_PER_COLUMN);
  logic [WINDOW_COUNTER_WIDTH-1:0] r_window_counter_input;

  localparam WINDOW_ROW_COUNTER_WIDTH = $clog2(WINDOW_COUNT_PER_LINE) + 1;
  logic [WINDOW_ROW_COUNTER_WIDTH-1:0] r_window_counter_row;

  localparam ADDR_INPUT_COUNTER_WIDTH = $clog2(WINDOW_COUNT_PER_COLUMN) + 1;
  logic [ADDR_INPUT_COUNTER_WIDTH-1:0] w_base_feat_input, r_addr_count_input;

  // REGISTER BANK FOR THE WEIGHTS ////////////////////////////////////////////
  localparam int WEIGHT_CYCLES = HADAMARD_SIZE * HADAMARD_SIZE;
  localparam int WEIGHT_WIDTH = $clog2(WEIGHT_CYCLES)+1;
  logic [NBITS-1:0] weight_reg[WEIGHT_CYCLES-1:0];
  logic [WEIGHT_CYCLES-1:0] w_weight_write_en;
  logic [WEIGHT_WIDTH-1:0] r_addr_count_kernel;
  logic w_weight_done, w_write_done;

  logic [NBITS-1:0] r_conv_temp [HADAMARD_SIZE*HADAMARD_SIZE-1:0];
  logic [NBITS-1:0] w_conv_transform [HADAMARD_SIZE*HADAMARD_SIZE-1:0];
  logic [NBITS-1:0] w_conv_inverse [TRANSFORM_SIZE*TRANSFORM_SIZE-1:0];
  logic [NBITS-1:0] r_output_write [TRANSFORM_SIZE*TRANSFORM_SIZE-1:0];
  logic [NBITS-1:0] r_output_read [TRANSFORM_SIZE*TRANSFORM_SIZE-1:0];
  logic [$clog2(STATE_MULT-1):0] r_idx_in;
  logic [$clog2(STATE_MULT*NUM_MULT-1):0] r_idx_out[NUM_MULT-1:0];
  logic signed [NBITS-1+QUANT:0] product [NUM_MULT-1:0];  // QUANT more bits for the multipliers
  // logic r_end;


  // -------------------------------------------------------------------------
  // FSM STATES DECLARION
  // -------------------------------------------------------------------------
  typedef enum logic [3:0] {
    WAIT_INPUT,
    UPDATE_ADDRESS,
    READ_WEIGHTS,
    READ_IN_10A,
    READ_IN_10B,
    READ_IN_15A,
    READ_IN_15B,
    READ_IN_15C,
    HOLD_WRITE,
    TRANSFER,
    NEXT_ROW
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
    RESET9,
    READ_OUTPUT,
    WRITE_OUTPUT
  } type_st_output;
  type_st_output st_output_current, st_output_next;

  // ----------------------------------------------------------------------------------------------------
  // -------  PART 1 - ADDRESS TO ACCESS THE IFMAP AND WEIGHT MEMORY ------------------------------------
  // ----------------------------------------------------------------------------------------------------
  assign p_input_addr = (st_input_current == READ_WEIGHTS) ? r_addr_pointer_kernel : r_addr_pointer_input + NADDR'(r_addr_count_input);  // p_input_addr mux

  always_ff @(posedge clk or posedge reset) begin: INPUT_ADDR_POINTER_BLOCK
    if (reset) begin
      r_addr_pointer_input <= '0;
      r_window_row_step <= 3;
    end
    else if ((st_input_current == READ_IN_10A && st_input_next == READ_IN_10B) || (st_input_current == READ_IN_10B && st_input_next == READ_IN_15A) || (st_input_current == READ_IN_15A && st_input_next == READ_IN_15B) || (st_input_current == READ_IN_15B && st_input_next == READ_IN_15C) || st_input_current == TRANSFER)
      r_addr_pointer_input <= r_addr_pointer_input + NADDR'(FEAT_INPUT_WIDTH);    // change internal p_input_addr in the state transition or in the TRANSFER state (CAUTION: PE)

    else if (st_input_current == NEXT_ROW && !last_input) begin  // when change the line, the read pointer moves 'r_window_row_step'
      r_addr_pointer_input <= r_window_row_step + NADDR'(r_channel_counter_input * FEAT_INPUT_SIZE * FEAT_INPUT_WIDTH);  // restart for the first line
      r_window_row_step <= r_window_row_step + 3;
    end else if (st_input_current == UPDATE_ADDRESS && last_input) begin
      r_addr_pointer_input <= r_addr_pointer_input - NADDR'(FEAT_INPUT_WIDTH) + NADDR'(HADAMARD_SIZE) - 1;   // adjust the pointer to the next IFMAP
      r_window_row_step <= 3;

      if (r_channel_counter_input == CHANNEL_INPUT_COUNTER_WIDTH'(N_CHANNEL_IN-1) ) begin               // change the IFMAP
        r_addr_pointer_input <= 0;
        `ifdef SIMULATION
            $display(
                "RESETANDO PARA O CANAL 0 - DEU A VOLTA NOS IFMAPS time=%0t %d (%0d) st_input_current = %s",
                $time, r_channel_counter_input, N_CHANNEL_IN, st_input_current.name()
            );
        `endif
      end
    end
  end

  always_ff @(posedge clk or posedge reset) begin: WEIGHT_ADDR_POINTER_BLOCK
    if (reset)
      r_addr_pointer_kernel <= 0;
    else if (st_input_current == WAIT_INPUT && st_input_next == UPDATE_ADDRESS)    // initializes only ONCE the weight p_input_addr (after the IFMAPs in the memory) (CAUTION: PE)
      r_addr_pointer_kernel <= NADDR'(N_CHANNEL_IN * FEAT_INPUT_SIZE * FEAT_INPUT_WIDTH);
    else if (st_input_current == READ_WEIGHTS)
      r_addr_pointer_kernel <= r_addr_pointer_kernel + 1;  // next weight
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
      WAIT_INPUT: if (p_start) st_input_next = UPDATE_ADDRESS;
      UPDATE_ADDRESS: st_input_next = READ_WEIGHTS;
      READ_WEIGHTS:
        if (w_weight_done) st_input_next = READ_IN_10A;
        else if (last_output) st_input_next = WAIT_INPUT;  //end processing
      READ_IN_10A: if (r_addr_count_input == 4) st_input_next = READ_IN_10B;  // read 5*5 values
      READ_IN_10B: if (r_addr_count_input == 4) st_input_next = READ_IN_15A;
      READ_IN_15A: if (r_addr_count_input == 4) st_input_next = READ_IN_15B;
      READ_IN_15B: if (r_addr_count_input == 4) st_input_next = READ_IN_15C;
      READ_IN_15C: if (r_addr_count_input == 4) st_input_next = TRANSFER;
      TRANSFER: st_input_next = HOLD_WRITE;  // p_start the convolution
      HOLD_WRITE:
        if (last_line && w_write_done) st_input_next = NEXT_ROW;
        else if (w_write_done) st_input_next = READ_IN_15A;
        else st_input_next = HOLD_WRITE;
      NEXT_ROW:
        if (last_input) st_input_next = UPDATE_ADDRESS;
        else st_input_next = READ_IN_10A;
      default: st_input_next = WAIT_INPUT;
    endcase
  end

  assign w_weight_done = (r_addr_count_kernel == WEIGHT_WIDTH'(WEIGHT_CYCLES - 1));
  assign w_write_done = r_output_write_count == 0 || r_output_write_count == 8;  // compare to zero for the first write test or the last value (8) in the next convolutions
  assign last_line = (r_window_counter_row == WINDOW_ROW_COUNTER_WIDTH'(WINDOW_COUNT_PER_LINE));
  assign last_input = (r_window_counter_input == WINDOW_COUNTER_WIDTH'(WINDOW_COUNT_PER_CHANNEL));
  assign last_output = (r_channel_counter_output == CHANNEL_OUTPUT_COUNTER_WIDTH'(N_CHANNEL_OUT));

  assign p_end = ((st_output_next == WAIT_OUTPUT && last_output));  // output to signalize the end of the convolution process

  // -------------------------------------------------------------------------
  // READING REGISTERS
  // -------------------------------------------------------------------------

  always_ff @(posedge clk or posedge reset) begin: INPUT_READ_COUNTER_BLOCK
    if (reset) begin
      r_addr_count_input <= 0;
    end else begin
      if (st_input_current == READ_WEIGHTS) begin
        r_addr_count_input <= 0;
      end
      else if (st_input_current inside {READ_IN_10A, READ_IN_10B, READ_IN_15A, READ_IN_15B, READ_IN_15C}) begin
        if (r_addr_count_input == 4)
          r_addr_count_input <= 0;
        else
          r_addr_count_input <= r_addr_count_input + 1;
      end
    end
  end

  assign w_base_feat_input = (st_input_current == READ_IN_10A) ? 0 :
                             (st_input_current == READ_IN_10B) ? 1 :
                             (st_input_current == READ_IN_15A) ? 2 :
                             (st_input_current == READ_IN_15B) ? 3 :
                             (st_input_current == READ_IN_15C) ? 4 :  0;


  // SET OF FIVE CONTROL REGISTERS:
  // r_channel_counter_input: number of the current IFMAP channel being read
  // r_channel_counter_output: number of the current OFMAP channel being processed
  // r_window_counter_input:  number of convolutions in a given IFMAP channel
  // r_window_counter_row :  number of horizontal convolutions in a given IFMAP channel - detect the last line
  // r_addr_count_kernel:        number of weights read from memory
  always_ff @(posedge clk or posedge reset) begin: INPUT_CONTROL_COUNTERS_BLOCK
    if (reset) begin
      r_channel_counter_input  <= '1;  // p_start with all bits in '1' - IFchannel must be {0,1,2}
      r_channel_counter_output <= 0;
      r_window_counter_input   <= 0;
      r_window_counter_row     <= 0;
      r_addr_count_kernel      <= 0;
    end else begin
      if (st_input_current == UPDATE_ADDRESS) begin
        if (r_channel_counter_input == CHANNEL_INPUT_COUNTER_WIDTH'(N_CHANNEL_IN - 1)) begin
          r_channel_counter_input  <= '0;
          r_channel_counter_output <= r_channel_counter_output + 1;
        end else begin
          r_channel_counter_input <= r_channel_counter_input + 1;
        end
        r_window_counter_input <= 0;  // reset counters
        r_window_counter_row   <= 0;
        r_addr_count_kernel    <= 0;
      end

      if (st_input_current == NEXT_ROW) begin
        r_window_counter_row <= 0;
      end

      if (st_input_current == TRANSFER) begin
        r_window_counter_input <= r_window_counter_input + 1;
        r_window_counter_row   <= r_window_counter_row + 1;
      end

      if (st_input_current == READ_WEIGHTS) begin
        r_addr_count_kernel <= r_addr_count_kernel + 1;
      end
    end
  end

  // -------------------------------------------------------------------------
  // READING REGISTER BANK
  // -------------------------------------------------------------------------
  always_comb begin: INPUT_SHIFT_DATA_BLOCK
    for (int unsigned i = 0; i < 25; i++)  // connection between register outputs to register inputs
    w_next_feat_input[i] = p_input_data;

    w_next_feat_input[0]  = (st_input_current == READ_IN_10A) ? p_input_data : r_feat_input[3];     // makes the shifts - minimize muxes
    w_next_feat_input[1]  = (st_input_current == READ_IN_10B) ? p_input_data : r_feat_input[4];
    w_next_feat_input[5]  = (st_input_current == READ_IN_10A) ? p_input_data : r_feat_input[8];
    w_next_feat_input[6]  = (st_input_current == READ_IN_10B) ? p_input_data : r_feat_input[9];
    w_next_feat_input[10] = (st_input_current == READ_IN_10A) ? p_input_data : r_feat_input[13];
    w_next_feat_input[11] = (st_input_current == READ_IN_10B) ? p_input_data : r_feat_input[14];
    w_next_feat_input[15] = (st_input_current == READ_IN_10A) ? p_input_data : r_feat_input[18];
    w_next_feat_input[16] = (st_input_current == READ_IN_10B) ? p_input_data : r_feat_input[19];
    w_next_feat_input[20] = (st_input_current == READ_IN_10A) ? p_input_data : r_feat_input[23];
    w_next_feat_input[21] = (st_input_current == READ_IN_10B) ? p_input_data : r_feat_input[24];
  end

  always_comb begin: INPUT_SHIFT_WE_BLOCK  // 'w_feat_input_write_en' to write into the register bank r_feat_input
    w_feat_input_write_en = '0;
    case (st_input_current)
      READ_IN_10A, READ_IN_10B, READ_IN_15A, READ_IN_15B, READ_IN_15C:
        w_feat_input_write_en[w_base_feat_input + r_addr_count_input * 5] = 1'b1;
      TRANSFER:
        w_feat_input_write_en = 25'b0001100011000110001100011;  // make the shift
      default:
        w_feat_input_write_en = '0;
    endcase
  end

  always_ff @(posedge clk or posedge reset) begin: INPUT_FEATURE_REG_BLOCK  // initializes and write into the register bank and convolution register bank
    if (reset)
      for (int unsigned i = 0; i < 25; i++)
        r_feat_input[i] <= '0;
    else
      for (int unsigned i = 0; i < 25; i++)
        if (w_feat_input_write_en[i])
          r_feat_input[i] <= w_next_feat_input[i];
  end

  // Weight register bank with per-entry write-enable.
  always_comb begin: WEIGHT_WE_BLOCK
    w_weight_write_en = '0;
    if (st_input_current == READ_WEIGHTS)
      w_weight_write_en[r_addr_count_kernel] = 1'b1;
  end

  always_ff @(posedge clk or posedge reset) begin: WEIGHT_REG_BLOCK
    if (reset) begin
      for (int unsigned i = 0; i < WEIGHT_CYCLES; i++)
        weight_reg[i] <= '0;
    end else begin
      for (int unsigned i = 0; i < WEIGHT_CYCLES; i++)
        if (w_weight_write_en[i])
          weight_reg[i] <= p_input_data;
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
          r_conv_input[i] <= r_feat_input[i];
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
      r_idx_in <= 1'b0;
      r_conv_temp <= '{default: '0};
    end else begin
      unique case (st_conv_current)
        WAIT_CONV: begin
          r_idx_in <= 1'b0;
          // if (p_start) begin
          //   r_conv_temp[C1_SIZE*C1_SIZE-1:0] <= r_conv_input;
          // end
        end
        TRANSFORM: begin
          r_conv_temp <= w_conv_transform;
        end
        HADAMARD: begin
          r_idx_in <= r_idx_in + 1;
          for (int i = 0; i < NUM_MULT; i++) begin
            r_conv_temp[r_idx_out[i]] <= product[i];
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
    .TRANSFORM_SIZE(TRANSFORM_SIZE),
    .INVERSE_SIZE(INVERSE_SIZE),
    .HADAMARD_SIZE(HADAMARD_SIZE)
  ) trf (
      // .pin (r_conv_input[C1_SIZE*C1_SIZE-1:0]),
      .pin (r_conv_input),
      .pout(w_conv_transform)
  );

  MuxMult mux_mult(
    .idx_in(r_idx_in),
    .idx_out(r_idx_out)
  );

  generate
    for (genvar i = 0; i < NUM_MULT; i++) begin : MULTIP_BLOCK
      Multip #(
        .QUANT(QUANT),
        .NBITS(NBITS)
      )
      multip(
        .register_input(r_conv_temp[r_idx_out[i]]),
        .weight_input(weight_reg[r_idx_out[i]]),
        .product(product[i])
      );
    end
  endgenerate

  // Instance of matrix multiplier "A"
  Inverse #(
    .NBITS(NBITS),
    .TRANSFORM_SIZE(TRANSFORM_SIZE),
    .INVERSE_SIZE(INVERSE_SIZE),
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
        if (st_input_current == UPDATE_ADDRESS)
          st_output_next = RESET9;     // wait p_start reading the IFMAPs to p_start writing the results
        else
          st_output_next = WAIT_OUTPUT;
      RESET9:
        if (w_conv_end && r_output_read_count == 8)
          st_output_next = WRITE_OUTPUT;
      READ_OUTPUT:
        if (w_conv_end && r_output_read_count == 8)
          st_output_next = WRITE_OUTPUT;
      WRITE_OUTPUT:
        if (r_channel_counter_input == 0 && r_output_write_count == 8)
          st_output_next = RESET9;
        else if (r_channel_counter_input > 0 && r_output_write_count == 8)
          st_output_next = READ_OUTPUT;
        else if (last_output)
          st_output_next = WAIT_OUTPUT;  //end processing
        else
          st_output_next = WRITE_OUTPUT;
      default:
        st_output_next = WAIT_OUTPUT;
    endcase
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
      end else if (st_output_current == RESET9 || st_output_current == READ_OUTPUT) begin
        r_output_write_count <= 0;
        if (r_output_read_count < 8)
          r_output_read_count <= r_output_read_count + 1;
        else
          r_output_read_count <= 8;
      end
    end
  end

  always_ff @(posedge clk) begin: OUTPUT_DATA_BLOCK
    if (reset) begin
      r_output_write <= '{default: '0};
      r_output_read <= '{default: '0};
    end else begin
      if (w_conv_end)
        r_output_write <= w_conv_inverse;
    end
  end

  always_comb begin: P_OUTPUT_DATA_WRITE_BLOCK
    p_output_data_write = r_output_write[r_output_write_count] + r_output_read[r_output_write_count];
  end


endmodule
