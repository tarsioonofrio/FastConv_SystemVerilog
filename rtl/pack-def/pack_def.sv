//-------------------------------------------------------------------------
// FERNANDO MORAES                                          24/October/2024
//-------------------------------------------------------------------------
package pack_def;

  timeunit 1ns;
  timeprecision 1ps;

  // Permite override na COMPILAÇÃO: vlog +define+NBITS=23
  `ifndef NBITS
    `define NBITS 20
  `endif

  // Valor único e centralizado para o projeto
  parameter int NBITS = `NBITS;

endpackage
