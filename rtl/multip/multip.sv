module Multip #(
    parameter int QUANT = 8,
    parameter int NBITS = 20
) (
    input logic [NBITS-1:0] feature,
    input logic [NBITS-1:0] weight,
    output logic signed [NBITS-1:0] product
);
  timeunit 1ns;
  timeprecision 1ps;

  logic signed [NBITS-1+QUANT:0] partial_product;

  assign partial_product = (NBITS + QUANT)'($signed(feature) * $signed(weight));
  assign product = (NBITS)'(partial_product[NBITS-1+QUANT:QUANT]);
endmodule

// Two-stage registered multiply for FPGA timing experiments. The first
// register follows the multiplier and can map to DSP48 MREG; the second can
// map to PREG. The consumer must delay its valid/index sideband by two cycles.
module MultipDspPipe #(
    parameter int QUANT = 8,
    parameter int NBITS = 20
) (
    input logic clk,
    input logic enable,
    input logic [NBITS-1:0] feature,
    input logic [NBITS-1:0] weight,
    output logic signed [NBITS-1:0] product
);
  timeunit 1ns;
  timeprecision 1ps;

  logic signed [NBITS+QUANT-1:0] product_comb;
  logic signed [NBITS+QUANT-1:0] product_mreg;
  logic signed [NBITS+QUANT-1:0] product_preg;

  assign product_comb = (NBITS + QUANT)'($signed(feature) * $signed(weight));

  always_ff @(posedge clk) begin: DSP_MULTIPLIER_PIPELINE_BLOCK
    if (enable) begin
      product_mreg <= product_comb;
      product_preg <= product_mreg;
    end
  end

  assign product = (NBITS)'(product_preg[NBITS-1+QUANT:QUANT]);
endmodule
