/*
   TCN16 TILE CONVOLUTION CORE - FastConv F(4x4, 3x3)
*/
`timescale 1ns / 1ps

module Conv
  import pack_param::*;
  import pack_mux_mult::*;
#(
    parameter int unsigned QUANT = 8,
    parameter int unsigned NBITS = 20
  ) (
    input  logic clk,
    input  logic reset,
    input  logic p_start,
    output logic p_end,
    output logic p_idle,
    input  logic [NBITS-1:0] p_input [CONV_INPUT_SIZE*CONV_INPUT_SIZE-1:0],
    input  logic [NBITS-1:0] p_weight [HADAMARD_SIZE*HADAMARD_SIZE-1:0],
    output logic [NBITS-1:0] p_output [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0]
  );

  function automatic int f_width_min1(input int x);
    if (x <= 1)
      f_width_min1 = 1;
    else
      f_width_min1 = $clog2(x);
  endfunction

  localparam int WEIGHT_CYCLES = HADAMARD_SIZE * HADAMARD_SIZE;
  localparam int INDEX_WIDTH = f_width_min1(STATE_MULT * NUM_MULT);

  typedef enum logic [1:0] {
    IDLE_CONV,
    TRANSFORM,
    HADAMARD,
    INVERSE
  } state_type;

  state_type current_state;
  state_type next_state;

  logic [NBITS-1:0] r_feat [WEIGHT_CYCLES-1:0];
  logic [NBITS-1:0] w_prod_c [WEIGHT_CYCLES-1:0];
  logic [NBITS-1:0] w_prod_a [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0];
  logic signed [NBITS-1+QUANT:0] product_wide [NUM_MULT-1:0];

  logic [f_width_min1(STATE_MULT)-1:0] r_idx_in;
  // MuxMult declares its output as $clog2(NUM_MULT*STATE_MULT-1):0,
  // which is one bit wider than the minimum index width for this 36-entry bank.
  logic [INDEX_WIDTH:0] r_idx_out [NUM_MULT-1:0];

  always_ff @(posedge clk or posedge reset) begin: STATE_REG_BLOCK
    if (reset)
      current_state <= IDLE_CONV;
    else
      current_state <= next_state;
  end

  always_comb begin: NEXT_STATE_BLOCK
    next_state = current_state;
    unique case (current_state)
      IDLE_CONV:
        if (p_start)
          next_state = TRANSFORM;
      TRANSFORM:
        next_state = HADAMARD;
      HADAMARD:
        if (r_idx_in == f_width_min1(STATE_MULT)'(STATE_MULT - 1))
          next_state = INVERSE;
      INVERSE:
        next_state = IDLE_CONV;
      default:
        next_state = IDLE_CONV;
    endcase
  end

  always_ff @(posedge clk or posedge reset) begin: DATAPATH_REG_BLOCK
    if (reset) begin
      r_idx_in <= '0;
      r_feat <= '{default: '0};
    end else begin
      unique case (current_state)
        IDLE_CONV: begin
          r_idx_in <= '0;
          if (p_start)
            r_feat <= p_input;
        end
        TRANSFORM: begin
          r_feat <= w_prod_c;
        end
        HADAMARD: begin
          r_idx_in <= r_idx_in + 1'b1;
          for (int i = 0; i < NUM_MULT; i++)
            r_feat[r_idx_out[i][INDEX_WIDTH-1:0]] <= product_wide[i][NBITS-1:0];
        end
        default: begin
        end
      endcase
    end
  end

  Transform #(
    .NBITS(NBITS),
    .CONV_OUTPUT_SIZE(CONV_OUTPUT_SIZE),
    .CONV_INPUT_SIZE(CONV_INPUT_SIZE),
    .HADAMARD_SIZE(HADAMARD_SIZE)
  ) trf (
    .pin(r_feat),
    .pout(w_prod_c)
  );

  MuxMult mux_mult (
    .idx_in(r_idx_in),
    .idx_out(r_idx_out)
  );

  for (genvar i = 0; i < NUM_MULT; i++) begin: MULTIP_BLOCK
    Multip #(
      .QUANT(QUANT),
      .NBITS(NBITS)
    ) multip (
      .feature(r_feat[r_idx_out[i][INDEX_WIDTH-1:0]]),
      .weight(p_weight[r_idx_out[i][INDEX_WIDTH-1:0]]),
      .product(product_wide[i])
    );
  end

  Inverse #(
    .NBITS(NBITS),
    .CONV_OUTPUT_SIZE(CONV_OUTPUT_SIZE),
    .CONV_INPUT_SIZE(CONV_INPUT_SIZE),
    .HADAMARD_SIZE(HADAMARD_SIZE)
  ) inv (
    .pin(r_feat),
    .pout(w_prod_a)
  );

  always_comb begin: STATUS_OUTPUT_BLOCK
    p_idle = (current_state == IDLE_CONV);
    p_end = (current_state == INVERSE);
    p_output = w_prod_a;
  end

endmodule
