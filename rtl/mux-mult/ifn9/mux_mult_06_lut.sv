//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NMULT = 6;
  parameter int SMULT = 6;
endpackage

module MuxMult
  #(
    parameter int NMULT = 6,
    parameter int SMULT = 6
  )
  (
    input  logic[$clog2(SMULT-1):0] idx_in, // current state
    output logic[$clog2(SMULT*NMULT-1):0] idx_out[0:NMULT-1]  // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  localparam logic [5:0] addr [0:SMULT-1][0:NMULT-1] = '{
    '{  0,  1,  2,  3,  4,  5 },
    '{  6,  7,  8,  9, 10, 11 },
    '{ 12, 13, 14, 15, 16, 17 },
    '{ 18, 19, 20, 21, 22, 23 },
    '{ 24, 25, 26, 27, 28, 29 },
    '{ 30, 31, 32, 33, 34, 35 }
  };

  assign idx_out = addr[idx_in];
endmodule
