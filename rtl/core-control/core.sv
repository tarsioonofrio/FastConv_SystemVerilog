module CoreControl
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

    input  logic serial_valid_in,
    input  logic_vector serial_data_in,
    output logic parallel_valid_out,
    output type_weight parallel_data_out,

    input  logic parallel_valid_in,
    input  type_output parallel_data_in,
    output logic serial_valid_out,
    output logic_vector serial_data_out
  );

  timeunit 1ns;
  timeprecision 1ps;

  typedef enum {IDLE, COUNT} state_type;
  state_type current_st_to_serial, next_st_to_serial;
  state_type current_st_to_parallel, next_st_to_parallel;

  // type_output registers_in;
  type_weight registers_out;

  int count_to_serial;
  int count_to_parallel;

  always_comb begin
    // serial_data_out = registers_in[count_to_serial];
    serial_data_out = parallel_data_in[count_to_serial];
    // parallel_data_out = registers_out;
    parallel_data_out[count_to_parallel] = serial_data_in;
    unique case (current_st_to_serial)
      IDLE:
        if (parallel_valid_in)
          next_st_to_serial = COUNT;
      COUNT:
        if (count_to_serial >= PARALLEL_SIZE)
          next_st_to_serial = IDLE;
    endcase
    unique case (current_st_to_parallel)
      IDLE:
        if (serial_valid_in)
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
      // registers_in = '{default: '0};
      // registers_out = '{default: '0};
    end
    else begin
      // registers_in = parallel_data_in;
      // registers_out[count_to_parallel] = serial_data_in;
      current_st_to_serial <= next_st_to_serial;
      current_st_to_parallel <= next_st_to_parallel;
      unique case (current_st_to_serial)
        IDLE: begin
          count_to_serial <= 0;
          serial_valid_out <= 1'b0;
        end
        COUNT:
          if (count_to_serial < PARALLEL_SIZE) begin
            count_to_serial <= count_to_serial + 1;
            serial_valid_out <= 1'b1;
          end
      endcase
      unique case (current_st_to_parallel)
        IDLE: begin
          count_to_parallel <= 0;
          parallel_valid_out <= 1'b0;
        end
        COUNT: begin
          if (count_to_parallel < SERIAL_SIZE) begin
            count_to_parallel <= count_to_parallel + 1;
          end
          else begin
            parallel_valid_out <= 1'b1;
            '          end
        end
      endcase
    end
  end
endmodule
