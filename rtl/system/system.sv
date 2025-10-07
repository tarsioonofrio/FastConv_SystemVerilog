module System
  import pack_def::*;
  import pack_typedef::*;
  import pack_param::*;
#(
  parameter int NADDR            = 16,
  parameter int NBITS            = 20,
  parameter int LATENCY          = 1,
  parameter int ROM              = 0,
  parameter int QUANT            = 8,
  parameter int N_WINDOW         = 10,
  parameter int N_CHANNEL_IN     = 1,
  parameter int N_CHANNEL_OUT    = 1,
  parameter int FEAT_INPUT_SIZE  = 32,
  parameter int FEAT_OUTPUT_SIZE = 30,
  parameter int LAST_WINDOW      = 0
) (
  input  logic clk,
  input  logic reset,
  input  logic p_start,
  output logic p_end,

  output logic p_read_en,
  output logic[NADDR-1:0] p_read_addr,
  input  logic_vector p_read_data,
  input  logic p_read_valid,

  output logic p_write_en,
  output logic[NADDR-1:0] p_write_addr,
  output logic_vector p_write_data
);

  timeunit 1ns;
  timeprecision 1ps;

  logic w_conv_start;
  logic w_conv_end;

  type_input w_input;
  type_weight w_weight;
  type_output w_output;

  // logic w_read_en;
  // logic w_read_wr;
  // output logic w_read_valid;
  // logic[NADDR-1:0] w_read_addr;
  // logic_vector w_read_in;
  // output logic_vector w_read_data;

  // logic w_write_chip;
  // logic w_write_en;
  // output logic w_write_valid;
  // logic[NADDR-1:0] w_write_addr;
  // logic_vector w_write_data;
  // logic_vector w_write_out;

  Control #(
    .NADDR(NADDR),
    .NBITS(NBITS),
    .LATENCY(LATENCY),
    .ROM(ROM),
    .QUANT(QUANT),
    .FEAT_INPUT_SIZE(FEAT_INPUT_SIZE),
    .FEAT_OUTPUT_SIZE(FEAT_OUTPUT_SIZE),
    .N_WINDOW(N_WINDOW),
    .N_CHANNEL_IN(N_CHANNEL_IN),
    .N_CHANNEL_OUT(N_CHANNEL_OUT),
    .LAST_WINDOW(LAST_WINDOW)
  ) control (
    .clk(clk),
    .reset(reset),

    .p_start(p_start),
    .p_end(p_end),
    .p_conv_start(w_conv_start),
    .p_conv_end(w_conv_end),
    .p_input(w_input),
    .p_weight(w_weight),
    .p_output(w_output),

    .p_read_en(p_read_en),
    .p_read_addr(p_read_addr),
    .p_read_valid(p_read_valid),
    .p_read_data(p_read_data),

    .p_write_en(p_write_en),
    .p_write_addr(p_write_addr),
    .p_write_data(p_write_data)
  );

  Conv #(
    .QUANT(QUANT),
    .NBITS(NBITS)
  ) conv (
    .clk(clk),
    .reset(reset),

    .p_start(w_conv_start),
    .p_end(w_conv_end),
    .p_input(w_input),
    .p_weight(w_weight),
    .p_output(w_output)
  );

endmodule
