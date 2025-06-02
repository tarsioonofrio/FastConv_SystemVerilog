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

    input  logic p_in_ce,
    input  logic p_in_we,
    output logic p_in_valid,

    input  logic p_wh_ce,
    input  logic p_wh_we,
    output logic p_wh_valid,

    output logic p_out_ce,
    output logic p_out_we,
    input  logic p_out_valid,

    input  logic_vector      p_in_data,
    output logic_vector      p_out_data
  );

  timeunit 1ns;
  timeprecision 1ps;

  // Tipos usados
  type_output input_map;    // do serial_parallel para convolucao (entrada paralela)
  type_weight output_map;   // do convolucao para serial_parallel (saída paralela)
  logic       data_valid;

  type_output registers_in;
  type_weight registers_out;
  type_weight register_weight;

  logic out_ce;
  logic out_we;
  logic out_valid;

  logic serial_valid_in, parallel_valid_in, serial_valid_out, parallel_valid_out;

  // Sinais intermediários para conexão paralela

  SerialParallel #(
    .SERIAL_SIZE(SERIAL_SIZE),
    .PARALLEL_SIZE(PARALLEL_SIZE),
    .LATENCY(LATENCY),
    .ROM(ROM)
  ) serial_parallel_inst (
    .clk(clk),
    .reset(reset),

    .serial_valid_in(serial_valid_in),
    .serial_valid_out(serial_valid_out),
    .serial_in(serial_in),
    .serial_out(serial_out),

    .parallel_valid_in(parallel_valid_in),
    .parallel_valid_out(parallel_valid_out),
    .parallel_in(parallel_in),
    .parallel_out(parallel_out)
  );

  // Instanciação do módulo de convolução usando os sinais paralelos do serial_parallel
  conv #(
    .QUANT(QUANT)
  ) convolucao (
    .clk(clk),
    .reset(reset),
    .start(p_start),
    .inputMAP(input_map),
    .weights(register_weight),
    .outputMAP(output_map),
    .data_valid(data_valid)
  );

  always_ff @(posedge clk) begin
    if (reset) begin
      registers_in = '{default: '0};
      registers_out = '{default: '0};
      register_weight <= '{default: '0};
    end
    else
      registers_in = parallel_in;
      registers_out[count_to_parallel] = serial_in;
      if (p_wh_ce == 1'b1 && p_wh_we == 1'b1 && parallel_valid_out)
        register_weight <= input_map;
  end

  always_comb begin
    serial_out = parallel_in[count_to_serial];

  end

endmodule
