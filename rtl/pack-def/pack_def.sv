//-------------------------------------------------------------------------
// FERNANDO MORAES                                          24/October/2024
//-------------------------------------------------------------------------
package pack_def;

  timeunit 1ns;
  timeprecision 1ps;

  // Permite override na COMPILAÇÃO: vlog +define+NBITS=23
  `ifndef NADDR
    `define NADDR 16
  `endif
  `ifndef NBITS
    `define NBITS 20
  `endif
  `ifndef LATENCY
    `define LATENCY 2
  `endif
  `ifndef ROM
    `define ROM 1
  `endif
  `ifndef QUANT
    `define QUANT 8
  `endif
  // `ifndef N_CHANNEL_IN
  //   `define N_CHANNEL_IN 1
  // `endif
  // `ifndef N_CHANNEL_OUT
  //   `define N_CHANNEL_OUT 1
  // `endif
  `ifndef LAST_WINDOW
    `define LAST_WINDOW 0
  `endif

  // Valor único e centralizado para o projeto
  parameter int NADDR = `NADDR;
  parameter int NBITS = `NBITS;
  parameter int LATENCY = `LATENCY;
  parameter int ROM = `ROM;
  parameter int QUANT = `QUANT;
  // parameter int N_CHANNEL_IN = `N_CHANNEL_IN;
  // parameter int N_CHANNEL_OUT = `N_CHANNEL_OUT;
  parameter int LAST_WINDOW = `LAST_WINDOW;


endpackage
