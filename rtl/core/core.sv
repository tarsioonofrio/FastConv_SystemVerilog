module Core
  import packConv::*;
  import data::*;
 #(
    parameter int QUANT            = 8,
    parameter int NBITS            = 20,
    parameter int NADDR            = 12,
    parameter int WEIGHT_SIZE      = 1,
    parameter int BUFFER_IN_SIZE   = 512,
    parameter int WINDOW_IN_SIZE   = 64,
    parameter int WINDOW_IN_NUM    = 4,
    parameter int LATENCY          = 0,
    parameter int ROM              = 0,
    // Parâmetros adicionais necessários para SerialParallel
    parameter int SERIAL_SIZE      = 36,
    parameter int PARALLEL_SIZE    = 9
  )
  (
    input  logic clk, reset,

    input  logic p_start,
    output logic p_end,
    output logic p_debug,

    input  logic p_in_en,
    output logic p_in_valid,

    input  logic p_wh_en,
    output logic p_wh_valid,

    output logic p_out_en,
    input  logic p_out_valid,

    input  logic_vector p_in_data,
    output logic_vector p_out_data
  );

  timeunit 1ns;
  timeprecision 1ps;

  typedef enum {IDLE, WEIGHT, DATA_IN, DATA_OUT} state_type;
  state_type current_st, next_st;

  // Tipos usados
  type_input  input_map;    // do serial_parallel para convolucao (entrada paralela)
  type_output output_map;   // do convolucao para serial_parallel (saída paralela)
  type_weight parallel_out;
  logic       output_valid;

  type_weight register_weight;
  type_weight registers_in;
  type_output registers_out;

  logic out_ce;
  logic out_we;
  logic out_valid;

  logic serial_valid_in, parallel_valid_in, serial_valid_out, parallel_valid_out;
  logic end_serial_out;

  int count_to_serial, count_to_parallel;

  // Sinais intermediários para conexão paralela

  CoreControl #(
    .SERIAL_SIZE(SERIAL_SIZE),
    .PARALLEL_SIZE(PARALLEL_SIZE)
  ) core_control (
    .clk(clk),
    .reset(reset),

    .feature_in(p_in_en),
    .weight_in(p_wh_en),
    .serial_valid_in(serial_valid_in),
    .serial_in(p_in_data),
    .feature_out(feature_out),
    .weight_out(weight_out),
    .parallel_valid_out(parallel_valid_out),
    .parallel_out(parallel_out),

    .parallel_valid_in(output_valid),
    .parallel_in(output_map),
    .serial_valid_out(p_out_valid),
    .serial_out(p_out_data),
    .end_serial_out(end_serial_out)
  );

  // Instanciação do módulo de convolução usando os sinais paralelos do serial_parallel
  conv #(
    .QUANT(QUANT)
  ) convolucao (
    .clk(clk),
    .reset(reset),
    .start(p_start),
    .inputMAP(registers_in[24:0]),
    .weights(register_weight),
    .outputMAP(output_map),
    .data_valid(output_valid)
  );


  always_comb begin
    unique case (current_st)
      IDLE:
        if (p_start && p_wh_en)
          next_st = WEIGHT;
        else if (p_start && p_in_en)
          next_st = DATA_IN;
      WEIGHT:
        if (parallel_valid_out)
          next_st = IDLE;
      DATA_IN:
        if (parallel_valid_out)
            next_st = DATA_OUT;
      DATA_OUT:
        if (end_serial_out)
          next_st = IDLE;
    endcase
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      registers_in = '{default: '0};
      registers_out = '{default: '0};
      register_weight <= '{default: '0};
    end
    else
      if (output_valid == 1'b1)
        registers_out = output_map;
      if (parallel_valid_out == 1'b1) begin
        if (weight_out == 1'b1)
          register_weight <= parallel_out;
        if (feature_out == 1'b1)
          registers_in <= parallel_out;
      end
  end

endmodule
