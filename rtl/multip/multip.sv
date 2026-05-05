module Multip
  import pack_typedef::*;
#(
    parameter int QUANT = 8,
    parameter int NBITS = 20
) (
    input logic_vector register_input,
    input logic_vector weight_input,
    output logic signed [NBITS-1+QUANT:0] product
);
  timeunit 1ns;
  timeprecision 1ps;

  logic signed [NBITS-1+QUANT:0] partial_product;

  assign partial_product = (NBITS + QUANT)'($signed(register_input) * $signed(weight_input));
  assign product = (NBITS)'(partial_product[NBITS-1+QUANT:QUANT]);
endmodule
