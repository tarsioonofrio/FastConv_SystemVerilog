`timescale 1ns / 1ps

// OOC capacity wrapper: each core gets an independent logical memory
// interface so synthesis cannot collapse equivalent replicas. Shared control
// and clock model one synchronized multicore IP block.
module WPN16ReplicaTop #(
  parameter int unsigned N_CORES = 1,
  parameter int unsigned NADDR = 12,
  parameter int unsigned NBITS = 20
) (
  input  logic clk,
  input  logic reset,
  input  logic p_start,
  input  logic [N_CORES-1:0][6*NBITS-1:0] p_input_data,
  input  logic [N_CORES-1:0] p_input_valid,
  input  logic [N_CORES-1:0][4*NBITS-1:0] p_output_data_read,
  input  logic [N_CORES-1:0] p_output_valid,
  output logic [N_CORES-1:0] p_end,
  output logic [N_CORES-1:0] p_input_en,
  output logic [N_CORES-1:0][NADDR-1:0] p_input_addr,
  output logic [N_CORES-1:0] p_output_en,
  output logic [N_CORES-1:0] p_output_wr,
  output logic [N_CORES-1:0][NADDR-1:0] p_output_addr,
  output logic [N_CORES-1:0][4*NBITS-1:0] p_output_data_write
);
  for (genvar core = 0; core < N_CORES; core++) begin: CORES
    Conv #(.NADDR(NADDR), .NBITS(NBITS)) core_inst (
      .clk(clk),
      .reset(reset),
      .p_start(p_start),
      .p_end(p_end[core]),
      .p_input_en(p_input_en[core]),
      .p_input_addr(p_input_addr[core]),
      .p_input_data(p_input_data[core]),
      .p_input_valid(p_input_valid[core]),
      .p_output_en(p_output_en[core]),
      .p_output_wr(p_output_wr[core]),
      .p_output_addr(p_output_addr[core]),
      .p_output_data_write(p_output_data_write[core]),
      .p_output_data_read(p_output_data_read[core]),
      .p_output_valid(p_output_valid[core])
    );
  end
endmodule
