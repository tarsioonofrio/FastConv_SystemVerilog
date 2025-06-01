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
  state_type current_st_to_serial, next_st_to_serial;
  state_type current_st_to_parallel, next_st_to_parallel;

  type_output registers_in;
  type_weight registers_out;

  int count_to_serial;
  int count_to_parallel;

  always_comb begin
    parallel_out = registers_out;
    serial_out = registers_in[count_to_serial];
    unique case (current_st_to_serial)
      IDLE:
        if (parallel_valid)
          next_st_to_serial = COUNT;
      COUNT:
        if (count_to_serial >= PARALLEL_SIZE)
          next_st_to_serial = IDLE;
    endcase
    unique case (current_st_to_parallel)
      IDLE:
        if (serial_valid)
          next_st_to_parallel = COUNT;
      COUNT:
        if (count_to_parallel >= SERIAL_SIZE)
          next_st_to_parallel = IDLE;
    endcase
  end

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      count_to_serial <= 0;
      count_to_parallel <= 0;
      current_st_to_serial <= IDLE;
      current_st_to_parallel <= IDLE;
      registers_in = '{default: '0};
      registers_out = '{default: '0};
    end
    else begin
      registers_in = parallel_in;
      registers_out[count_to_parallel] = serial_in;

      current_st_to_serial <= next_st_to_serial;
      current_st_to_parallel <= next_st_to_parallel;
      unique case (current_st_to_serial)
        IDLE:
          count_to_serial <= 0;
        COUNT:
          if (count_to_serial < PARALLEL_SIZE)
            count_to_serial <= count_to_serial + 1;
      endcase
      unique case (current_st_to_parallel)
        IDLE:
          count_to_parallel <= 0;
        COUNT:
          if (serial_valid && count_to_parallel < SERIAL_SIZE)
            count_to_parallel <= count_to_parallel + 1;
      endcase
    end
  end;
endmodule
