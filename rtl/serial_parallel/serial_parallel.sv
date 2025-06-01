module SerialParallel
  import packConv::*;
  import data::*;
  #(
    parameter int SERIAL_SIZE      = 36,
    parameter int PARALLEL_SIZE    = 9,
    parameter int LATENCY          = 0,
    parameter int ROM              = 0
  )
  (
    input  logic clk, reset,

    input  logic serial_valid,
    input  logic parallel_valid,
    input  logic_vector serial_in,
    input  type_output parallel_in,
    output type_weight parallel_out,
    output logic_vector serial_out
  );

  timeunit 1ns;
  timeprecision 1ps;

  typedef enum {IDLE, COUNT} state_type;
  state_type current_st_p2s, next_st_p2s;
  state_type current_st_s2p, next_st_s2p;

  int count_p2s;
  int count_s2p;

  always_comb begin
    serial_out = parallel_in[count_p2s];
    parallel_out[count_s2p] = serial_in;

    unique case (current_st_p2s)
      IDLE:
        if (parallel_valid)
          next_st_p2s = COUNT;
      COUNT:
        if (count_p2s >= PARALLEL_SIZE)
        next_st_p2s = IDLE;
    endcase
    unique case (current_st_s2p)
      IDLE:
        if (serial_valid)
          next_st_s2p = COUNT;
      COUNT:
        if (count_s2p >= SERIAL_SIZE)
        next_st_s2p = IDLE;
    endcase
  end

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      count_p2s <= 0;
      count_s2p <= 0;
      current_st_p2s <= IDLE;
      current_st_s2p <= IDLE;
    end
    else begin
      current_st_p2s <= next_st_p2s;
      current_st_s2p <= next_st_s2p;
      
      unique case (current_st_p2s)
        IDLE:
          count_p2s <= 0;
        COUNT:
          if (count_p2s < PARALLEL_SIZE)
          count_p2s <= count_p2s + 1;
      endcase
      unique case (current_st_s2p)
        IDLE:
          count_s2p <= 0;
        COUNT:
          if (serial_valid && count_s2p < SERIAL_SIZE)
          count_s2p <= count_s2p + 1;
      endcase
    end
  end;
endmodule
