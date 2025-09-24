//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NMULT = 25;
  parameter int SMULT = 1;
endpackage


module MuxMult
  (
    input  logic[$clog2(25-1):0] idx_in, // current state
    output logic[$clog2(25*25-1):0] idx_out[0:25-1]  // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (idx_in)
      default: begin idx_out[0]=0; idx_out[1]=1; idx_out[2]=2; idx_out[3]=3; idx_out[4]=4; idx_out[5]=5; idx_out[6]=6; idx_out[7]=7; idx_out[8]=8; idx_out[9]=9; idx_out[10]=10; idx_out[11]=11; idx_out[12]=12; idx_out[13]=13; idx_out[14]=14; idx_out[15]=15; idx_out[16]=16; idx_out[17]=17; idx_out[18]=18; idx_out[19]=19; idx_out[20]=20; idx_out[21]=21; idx_out[22]=22; idx_out[23]=23; idx_out[24]=24; end
    endcase
  end

endmodule
