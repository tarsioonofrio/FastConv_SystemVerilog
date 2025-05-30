module SerialParallel
  import packConv::*;
  import data::*;
  #(
    parameter int QUANT            = 8,
    parameter int NBITS            = 20,
    parameter int NADDR            = 12,
    parameter int WEIGHT_SIZE      = 1,
    parameter int BUFFER_IN_SIZE   = 512,
    parameter int WINDOW_IN_SIZE   = 64,
    parameter int WINDOW_IN_NUM    = 4,
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
  state_type current_st_parallel, next_st_parallel;
  state_type current_st_serial, next_st_serial;

  int count_parallel;
  int count_serial;

  always_comb begin
    serial_out = parallel_in[count_parallel];
    parallel_out[count_serial] = serial_in;

    unique case (current_st_parallel)
      IDLE:
        if (parallel_valid)
          next_st_parallel = COUNT;
      COUNT:
        if (count_parallel >= A1_SIZE * A1_SIZE)
          next_st_parallel = IDLE;
    endcase
    unique case (current_st_serial)
      IDLE:
        if (serial_valid)
          next_st_serial = COUNT;
      COUNT:
        if (count_serial >= A1_SIZE * A1_SIZE)
          next_st_serial = IDLE;
    endcase
  end

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      count_parallel <= 0;
      count_serial <= 0;
      current_st_parallel <= IDLE;
      current_st_serial <= IDLE;
    end
    else begin
      current_st_parallel <= next_st_parallel;
      current_st_serial <= next_st_serial;
      
      unique case (current_st_parallel)
        IDLE:
          count_parallel <= 0;
        COUNT:
          if (count_parallel < A1_SIZE * A1_SIZE)
          count_parallel <= count_parallel + 1;
      endcase
      unique case (current_st_serial)
        IDLE:
          count_serial <= 0;
        COUNT:
          if (serial_valid && count_serial < WINDOW_IN_SIZE)
          count_serial <= count_serial + 1;
      endcase
    end
  end;endmodule
