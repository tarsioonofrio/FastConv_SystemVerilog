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

    input logic p_in_ce,
    input logic p_in_valid,

    input logic p_wh_ce,
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

  // Tipos usados
  type_input input_map;
  type_output output_map;

  type_weight register_weight;
  type_output registers_out;

  logic out_ce;
  logic out_we;
  logic r_data_end;
  logic s_debug;

  logic start_conv;

  // ----------- serial signals
  logic serial_in_ce;
  logic_vector serial_data_in;
  logic parallel_valid_out;
  type_weight parallel_data_out;
  logic parallel_valid_in;
  type_output parallel_data_in;
  logic serial_valid_out;
  logic_vector serial_data_out;

  int count_to_parallel;
  int count_to_serial;


  state_type_conv current_st_conv, next_st_conv;

  type_weight                    registers;
  type_weight                    prod_c;
  type_output                    prod_a;
  type_input                     inputMAP;


  logic signed [NBITS-1+QUANT:0] product;  // QUANT more bits for the multipliers
  logic                          r_conv_end;
  logic        [            5:0] r_mult_idx;


  //
  // BLOCK: Control FSM
  //

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
        if (p_wh_ce) next_st = WEIGHT;
        else if (p_in_ce) next_st = DATA_IN;
        else if (p_start) next_st = CONV;
      WEIGHT:   if (r_data_end) next_st = IDLE;
      DATA_IN:  if (r_data_end) next_st = IDLE;
      CONV:     if (r_conv_end) next_st = DATA_OUT;
      DATA_OUT: if (r_data_end) next_st = IDLE;
    endcase
  end

  always_comb begin
    p_end = r_data_end;
  end


  always_ff @(posedge clk) begin
    if (reset) begin
      registers <= '{default: '0};
      registers_out <= '{default: '0};
      register_weight <= '{default: '0};
      count_to_serial <= 0;
      count_to_parallel <= 0;
      serial_valid_out <= 1'b0;
      r_data_end <= 1'b0;
      r_conv_end <= 0;
      r_mult_idx <= 0;
    end else begin
      unique case (current_st)
        IDLE: begin
          r_data_end <= 1'b0;
          r_conv_end <= 0;
          r_mult_idx <= 0;
        end
        WEIGHT: begin
          if (p_wh_ce && (count_to_parallel < M1_SIZE * M2_SIZE)) begin
            register_weight[count_to_parallel] <= serial_data_in;
            count_to_parallel <= count_to_parallel + 1;
            r_data_end <= 1'b0;
          end else begin
            count_to_parallel <= 0;
            r_data_end <= 1'b1;
          end
        end
        DATA_IN: begin
          if (p_in_ce && (count_to_parallel < C1_SIZE * C2_SIZE)) begin
            registers[count_to_parallel] <= serial_data_in;
            count_to_parallel <= count_to_parallel + 1;
            r_data_end <= 1'b0;
          end else begin
            count_to_parallel <= 0;
            r_data_end <= 1'b1;
          end
        end
        CONV: begin
          unique case (current_st_conv)
            WR_MC: registers <= prod_c;
            MU: begin
              registers[r_mult_idx] <= product;
              r_mult_idx <= r_mult_idx + 1;
            end
            WR_OUT: begin
              registers_out <= prod_a;
              r_conv_end <= 1;
            end
          endcase
        end
        DATA_OUT: begin
          if (count_to_serial < (A1_SIZE * A2_SIZE)) begin
            count_to_serial  <= count_to_serial + 1;
            serial_valid_out <= 1'b1;
          end else begin
            count_to_serial  <= 0;
            serial_valid_out <= 1'b0;
            r_data_end <= 1'b1;
          end
        end
      endcase
    end
  end

  // BLOCKS: CONNECT

  always_comb begin
    serial_data_in = p_in_data;
    if (current_st == DATA_IN) input_map = parallel_data_out[C1_SIZE*C2_SIZE-1:0];
    serial_data_out = registers_out[count_to_serial-1];
    parallel_data_out[count_to_parallel] = serial_data_in;
  end



  // BLOCK: Convolution

  logic       start;

  always_comb begin
    start = p_start;
  end

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
      IDLE1: next_st_conv = start ? WR_MC : IDLE1;
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
      .pin (registers[C1_SIZE*C1_SIZE-1:0]),
      .pout(prod_c)
  );

  // assign r_mult_idx = current_st_conv;

  Multip multip0 (
      .register(registers[r_mult_idx]),
      .weight  (register_weight[r_mult_idx]),
      .product (product)
  );

  // Instance of matrix multiplier "A"
  Inverse inv (
      .pin (registers),
      .pout(prod_a)
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
