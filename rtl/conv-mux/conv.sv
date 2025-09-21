module Conv
  import pack_def::*;
  import pack_param::*;
  import pack_typedef::*;
  import pack_mux_mult::*;
#(
    parameter int QUANT = 8,
    parameter int NBITS = 20
) (
    input logic clk, reset,

    input  logic p_start,
    output logic p_end,
    input  type_input  p_input,
    input  type_weight p_weight,
    output type_output p_output
);

  timeunit 1ns;
  timeprecision 1ps;

  typedef enum {
    IDLE_CONV,
    CONV_C,
    CONV_H,
    CONV_A
  } state_type;

  state_type current_state, next_state;

  type_weight r_conv;

  type_weight w_prod_c;
  type_output w_prod_a;

  logic r_end;

  logic w_end;
  // logic w_end[0];

  logic [$clog2(SMULT-1):0] r_idx_in;
  logic [$clog2(SMULT*SMULT-1):0] r_idx_out[0:NMULT-1];

  logic signed [NBITS-1+QUANT:0] product [0:NMULT-1];  // QUANT more bits for the multipliers


  // const int c_index[5*5] = {
  //   00, 05, 10, 15, 20,
  //   01, 06, 11, 16, 21,
  //   02, 07, 12, 17, 22,
  //   03, 08, 13, 18, 23,
  //   04, 09, 14, 19, 24
  // };

  //
  // BLOCK: Control FSM
  //


  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      current_state   <= IDLE_CONV;
    end else begin
      current_state   <= next_state;
    end
  end

  always_comb begin
    p_end = r_end;
    w_end = 1'b0;
    p_output <= w_prod_a;

    unique case (current_state)
      IDLE_CONV: begin
        w_end = 1'b0;
        if (p_start) next_state = CONV_C;
      end
      CONV_C:
        next_state = CONV_H;
      CONV_H:
        if (r_idx_in == (SMULT - 1))
          next_state = CONV_A;
      CONV_A: begin
        w_end = 1'b1;
        next_state = IDLE_CONV;
      end
    endcase

    // unique case (current_state_output)
    //   IDLE_OUTPUT: begin
    //     w_end[1] = 1'b0;
    //     if (w_end[0]) next_st_output = FEAT_OUTPUT;
    //   end
    //   FEAT_OUTPUT: begin
    //     if (r_count_fout == (A1_SIZE * A2_SIZE)) begin
    //       next_st_output = IDLE_OUTPUT;
    //       w_end[1] = 1'b1;
    //     end
    //   end
    // endcase
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      r_idx_in <= 1'b0;
      r_end = 1'b0;
    end else begin
      unique case (current_state)
        IDLE_CONV: begin
          r_end <= 1'b0;
          r_idx_in <= 1'b0;
          r_conv[C1_SIZE*C1_SIZE-1:0] <= p_input;
        end
        CONV_C: begin
          r_conv <= w_prod_c;
        end
        CONV_H: begin
          r_idx_in <= r_idx_in + 1;
          for (int i = 0; i < NMULT; i++) begin
            r_conv[r_idx_out[i]] <= product[i];
          end
        end
        CONV_A: begin
          // r_feat_out <= w_prod_a;
          r_end <= 1'b1;
        end
      endcase

      // unique case (current_state_output)
      //   IDLE_OUTPUT: begin
      //     r_end[1]     <= 1'b0;
      //     r_fout_en    <= 1'b0;
      //     r_fout_valid <= 1'b0;
      //     r_count_fout <= 0;
      //     // r_feat_out   <= '{default: '0};
      //   end
      //   FEAT_OUTPUT: begin
      //     r_end[1]     <= w_end[1];
      //     r_count_fout <= r_count_fout + 1;
      //     if (w_end[1]) begin
      //       r_fout_en    <= 1'b0;
      //       r_fout_valid <= 1'b0;
      //     end else begin
      //       r_fout_en    <= 1'b1;
      //       r_fout_valid <= 1'b1;
      //     end
      //   end
      // endcase
    end
  end


  // BLOCK: Convolution
  //
  // Data path
  //

  // Instance of matrix multiplier "C"
  Transform trf (
      .pin (r_conv[C1_SIZE*C1_SIZE-1:0]),
      .pout(w_prod_c)
  );

  // Multip multip0 (
  //     .register(r_conv[r_idx_in]),
  //     .weight  (p_weight[r_idx_in]),
  //     .product (product)
  // );

  MuxMult mux_mult(
    .idx_in(r_idx_in),
    .idx_out(r_idx_out)
  );

  generate
    for (genvar i = 0; i < NMULT; i++) begin
      Multip multip(
        .register(r_conv[r_idx_out[i]]),
        .weight(p_weight[r_idx_out[i]]),
        .product(product[i])
      );
    end
  endgenerate


  // Instance of matrix multiplier "A"
  Inverse inv (
      .pin (r_conv),
      .pout(w_prod_a)
  );
endmodule


module Multip
  import pack_typedef::*;
#(
    parameter int QUANT = 8,
    parameter int NBITS = 20
) (
    input logic_vector register,
    input logic_vector weight,
    output logic signed [NBITS-1+QUANT:0] product
);
  timeunit 1ns; timeprecision 1ps;
  logic signed [NBITS-1+QUANT:0] partial_product;

  assign partial_product = (NBITS + QUANT)'($signed(register) * $signed(weight));
  assign product = (NBITS)'(partial_product[NBITS-1+QUANT:QUANT]);
endmodule
