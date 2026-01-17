module System
  import pack_def::*;
  import pack_data::*;
  import pack_param::*;
  import pack_typedef::*;
#(
  parameter int NADDR            = 16,
  parameter int NBITS            = 20,
  parameter int LATENCY          = 1,
  parameter int ROM              = 0,
  parameter int QUANT            = 8 //,
  // parameter int N_WINDOW         = 10,
  // parameter int N_CHANNEL_IN     = 1,
  // parameter int N_CHANNEL_OUT    = 1,
  // parameter int FEAT_INPUT_SIZE  = 62,
  // parameter int FEAT_OUTPUT_SIZE = 60,
  // parameter int LAST_WINDOW      = 0
) (
  // Global clock/reset domain
  input  logic clk,                              // System clock driving all sequential logic
  input  logic reset,                            // Asynchronous-active-high reset

  // Top-level sequencing interface
  input  logic p_start,                          // Top-level start pulse for the entire control flow
  output logic p_end,                            // Asserted once every pipeline completes all work

  // Input RAM interface
  output logic p_input_en,                       // Enables a read operation on the input RAM
  output logic[NADDR-1:0] p_input_addr,          // Address issued to the input RAM
  input  logic_vector p_input_data,              // Data returned from the input RAM
  input  logic p_input_valid,                    // Read-valid flag from the input RAM

  // Output RAM interface
  output logic p_output_en,                      // Enables access to the output RAM port
  output logic p_output_wr,                      // Write strobe for the output RAM port
  output logic[NADDR-1:0] p_output_addr,         // Address issued to the output RAM
  output logic_vector p_output_data_write,       // Data driven into the output RAM on writes
  input  logic_vector p_output_data_read,        // Data captured from the output RAM on reads
  input  logic p_output_valid                    // Read-valid flag from the output RAM
);

  timeunit 1ns;
  timeprecision 1ps;

  logic w_conv_start;
  logic w_conv_end;

  type_input w_conv_input;
  type_weight w_conv_weight;
  type_output w_conv_output;

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
    .p_conv_idle(w_conv_idle),
    .p_conv_end(w_conv_end),

    .p_input(w_conv_input),
    .p_weight(w_conv_weight),
    .p_output(w_conv_output),

    .p_input_en(p_input_en),
    .p_input_addr(p_input_addr),
    .p_input_valid(p_input_valid),
    .p_input_data(p_input_data),

    .p_output_en(p_output_en),
    .p_output_wr(p_output_wr),
    .p_output_addr(p_output_addr),
    .p_output_data_read(p_output_data_read),
    .p_output_data_write(p_output_data_write),
    .p_output_valid(p_output_valid)
  );

  Conv #(
    .QUANT(QUANT),
    .NBITS(NBITS)
  ) conv (
    .clk(clk),
    .reset(reset),

    .p_start(w_conv_start),
    .p_idle(w_conv_idle),
    .p_end(w_conv_end),
    .p_input(w_conv_input),
    .p_weight(w_conv_weight),
    .p_output(w_conv_output)
  );

endmodule
