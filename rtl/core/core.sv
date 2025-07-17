module Core
  import packConv::*;
  import data::*;
#(
    parameter int QUANT          = 8,
    parameter int NBITS          = 20,
    parameter int NADDR          = 12,
    parameter int WEIGHT_SIZE    = 1,
    parameter int BUFFER_IN_SIZE = 512,
    parameter int WINDOW_IN_SIZE = 64,
    parameter int WINDOW_IN_NUM  = 4,
    parameter int LATENCY        = 0,
    parameter int ROM            = 0,
    parameter int SERIAL_SIZE    = 36,
    parameter int PARALLEL_SIZE  = 9
) (
    input logic clk,
    reset,

    input  logic p_start,
    output logic p_end,
    output logic p_debug,

    input logic p_in_en,
    input logic p_in_valid,

    input logic p_wh_en,
    input logic p_wh_valid,

    output logic p_out_en,
    output logic p_out_valid,

    input  logic_vector p_in_data,
    output logic_vector p_out_data
);

  timeunit 1ns; timeprecision 1ps;

  typedef enum {
    IDLE,
    WEIGHT,
    DATA_IN,
    CONV,
    DATA_OUT
  } state_type;

  state_type current_st, next_st;

  type_weight r_weight;
  type_output r_out_data;

  logic r_data_end;
  logic r_out_en;

  int r_count_in;
  int r_count_out;


  state_type_conv current_st_conv, next_st_conv;

  type_weight                    r_data_in;
  type_weight                    w_prod_c;
  type_output                    w_prod_a;


  logic signed [NBITS-1+QUANT:0] product;  // QUANT more bits for the multipliers
  logic                          r_conv_end;
  logic        [            5:0] r_mult_idx;


  //
  // BLOCK: Control FSM
  //


  always_comb begin
    p_end = r_data_end;
    p_out_en = r_out_en;
    // saving one register[NBITS] for data output
    p_out_data = r_out_data[r_count_out-1];
  end

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      current_st <= IDLE;
    end else begin
      current_st <= next_st;
    end
  end

  always_comb begin
    unique case (current_st)
      IDLE:
        if (p_wh_en) next_st = WEIGHT;
        else if (p_in_en) next_st = DATA_IN;
        else if (p_start) next_st = CONV;
      WEIGHT:   if (r_data_end) next_st = IDLE;
      DATA_IN:  if (r_data_end) next_st = IDLE;
      CONV:     if (r_conv_end) next_st = DATA_OUT;
      DATA_OUT: if (r_data_end) next_st = IDLE;
    endcase
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      r_weight <= '{default: '0};
      r_data_in <= '{default: '0};
      r_out_data <= '{default: '0};
      r_count_out <= 1'b0;
      r_count_in <= 1'b0;
      r_out_en <= 1'b0;
      r_data_end <= 1'b0;
      r_conv_end <= 1'b0;
      r_mult_idx <= 1'b0;
    end else begin
      unique case (current_st)
        IDLE: begin
          r_data_end <= 1'b0;
          r_conv_end <= 1'b0;
          r_mult_idx <= 1'b0;
        end
        WEIGHT: begin
          if (p_wh_en && (r_count_in < M1_SIZE * M2_SIZE)) begin
            r_weight[r_count_in] <= p_in_data;
            r_count_in <= r_count_in + 1;
            r_data_end <= 1'b0;
          end else begin
            r_count_in <= 1'b0;
            r_data_end <= 1'b1;
          end
        end
        DATA_IN: begin
          if (p_in_en && (r_count_in < C1_SIZE * C2_SIZE)) begin
            r_data_in[r_count_in] <= p_in_data;
            r_count_in <= r_count_in + 1;
            r_data_end <= 1'b0;
          end else begin
            r_count_in <= 1'b0;
            r_data_end <= 1'b1;
          end
        end
        CONV: begin
          unique case (current_st_conv)
            WR_MC: r_data_in <= w_prod_c;
            MU: begin
              r_data_in[r_mult_idx] <= product;
              r_mult_idx <= r_mult_idx + 1;
            end
            WR_OUT: begin
              r_out_data <= w_prod_a;
              r_conv_end <= 1'b1;
            end
          endcase
        end
        DATA_OUT: begin
          if (r_count_out < (A1_SIZE * A2_SIZE)) begin
            r_count_out  <= r_count_out + 1;
            r_out_en <= 1'b1;
          end else begin
            r_count_out  <= 1'b0;
            r_out_en <= 1'b0;
            r_data_end <= 1'b1;
          end
        end
      endcase
    end
  end


  // BLOCK: Convolution


  //
  // Control FSM
  //

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      current_st_conv <= IDLE1;
    end else begin
      current_st_conv <= next_st_conv;
    end
  end

  always_comb begin
    unique case (current_st_conv)
      IDLE1: next_st_conv = p_start ? WR_MC : IDLE1;
      WR_MC: next_st_conv = MU;
      MU:
        if (r_mult_idx < (M1_SIZE * M2_SIZE - 1))
          next_st_conv = MU;
        else
          next_st_conv = WR_OUT;
      WR_OUT: next_st_conv = IDLE1;
    endcase
  end

  //
  // Data path
  //

  // Instance of matrix multiplier "C"
  Transform trf (
      .pin (r_data_in[C1_SIZE*C1_SIZE-1:0]),
      .pout(w_prod_c)
  );

  // assign r_mult_idx = current_st_conv;

  Multip multip0 (
      .register(r_data_in[r_mult_idx]),
      .weight  (r_weight[r_mult_idx]),
      .product (product)
  );

  // Instance of matrix multiplier "A"
  Inverse inv (
      .pin (r_data_in),
      .pout(w_prod_a)
  );
endmodule


module Multip
  import packConv::*;
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
