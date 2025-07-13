module Core
  import packConv::*;
  import data::*;
 #(
    parameter int QUANT          = 8,
    parameter int NBITS          = 20,
    parameter int NADDR          = 12,
    parameter int WEIGHT_SIZE    = 1,
    parameter int BUFFER_IN_SIZE = 512,
    parameter int WINDOW_IN_SIZE = 64,
    parameter int WINDOW_IN_NUM  = 4,
    parameter int LATENCY        = 0,
    parameter int ROM            = 0,
    parameter int SERIAL_SIZE    = 36,
    parameter int PARALLEL_SIZE  = 9
  )
  (
    input  logic clk, reset,

    input  logic p_start,
    output logic p_end,
    output logic p_debug,

    input  logic p_in_ce,
    input  logic p_in_valid,

    input  logic p_wh_ce,
    input  logic p_wh_valid,

    output logic p_out_en,
    output logic p_out_valid,

    input  logic_vector p_in_data,
    output logic_vector p_out_data
  );

  timeunit 1ns;
  timeprecision 1ps;

  typedef enum {IDLE, WEIGHT, DATA_IN, CONV, DATA_OUT} state_type;
  state_type current_st, next_st;

  // Tipos usados
  type_input  input_map;
  type_output output_map;

  type_weight register_weight;
  type_output registers_out;

  logic out_ce;
  logic out_we;
  logic s_end;

  logic start_conv;

  // ----------- serial signals
  logic serial_in_ce;
  logic_vector serial_data_in;
  logic parallel_valid_out;
  type_weight parallel_data_out;
  logic parallel_valid_in;
  type_output parallel_data_in;
  logic serial_valid_out;
  logic_vector serial_data_out;


  conv #(
    .QUANT(QUANT)
  ) convolucao (
    .clk(clk),
    .reset(reset),
    .start(start_conv),
    .inputMAP(input_map),
    .weights(register_weight),
    .outputMAP(output_map),
    .data_valid(output_valid)
  );

  //
  // Control FSM
  //

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      current_st <= IDLE;
    end else begin
      current_st <= next_st;
    end
  end

  always_comb begin
    unique case (current_st)
      IDLE:
        if (p_wh_ce)
          next_st = WEIGHT;
        else if (p_in_ce)
          next_st = DATA_IN;
        else if (p_start)
          next_st = CONV;
      WEIGHT:
        if (parallel_valid_out)
          next_st = IDLE;
      DATA_IN:
        if (parallel_valid_out == 1'b1) begin
            next_st = IDLE;
            input_map <= parallel_data_out[24:0];
        end
      CONV:
        if (output_valid)
            next_st = DATA_OUT;
      DATA_OUT:
        if (serial_data_out)
          next_st = IDLE;
    endcase
  end

  always_comb begin
    serial_in_ce = 1'b1 ? p_in_ce || p_wh_ce: 1'b0;
    p_end = s_end;
  //   p_end = 1'b1 ? current_st ==  IDLE: 1'b0;
  //   start_conv = 1'b1 ? current_st == DATA_IN: 1'b0;
  end


  always_ff @(posedge clk) begin
    if (reset) begin
      registers_out = '{default: '0};
      // register_weight <= '{default: '0};
      start_conv = 1'b0;
      s_end <= 1'b0;
    end
    unique case (current_st)
      IDLE: begin
        registers_out = '{default: '0};
        // register_weight <= '{default: '0};
        start_conv = 1'b0;
        s_end <= 1'b0;
      end
      WEIGHT: begin
        // register_weight <= parallel_data_out;
        if (parallel_valid_out == 1'b1) begin
          s_end <= 1'b1;
        end
      end
      DATA_IN:
        if (parallel_valid_out == 1'b1) begin
            s_end <= 1'b1;
        end
      CONV:
          start_conv = 1'b1;
      DATA_OUT:
        if (output_valid == 1'b1) begin
          registers_out = output_map;
        end
    endcase
  end

  // CONNECT BLOCKS
  always_comb begin
    serial_data_in = p_in_data;
  end

  int count_to_parallel;

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      register_weight = '{default: '0};
    end else begin
      if (current_st == WEIGHT)
        register_weight[count_to_parallel] = serial_data_in;
    end
  end


  // ---------------------------------------------------------
  // BLOCK serialize

  typedef enum {IDLE0, COUNT} state_type_sp;
  state_type_sp current_st_to_serial, next_st_to_serial;
  state_type_sp current_st_to_parallel, next_st_to_parallel;

  // type_weight registers_out;

  int count_to_serial;

  always_comb begin
    // serial_data_out = input_map[count_to_serial];
    serial_data_out = parallel_data_in[count_to_serial];
    // parallel_data_out = registers_out;
    parallel_data_out[count_to_parallel] = serial_data_in;
  end

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      count_to_serial <= 0;
      count_to_parallel <= 0;
      current_st_to_serial <= IDLE0;
      current_st_to_parallel <= IDLE0;
      // input_map = '{default: '0};
      // registers_out = '{default: '0};
    end
    else begin
      // input_map = parallel_data_in;
      // registers_out[count_to_parallel] = serial_data_in;
      current_st_to_serial <= next_st_to_serial;
      current_st_to_parallel <= next_st_to_parallel;

      if (serial_in_ce) begin
        if (count_to_parallel < SERIAL_SIZE) begin
          count_to_parallel <= count_to_parallel + 1;
        end
        else
          parallel_valid_out <= 1'b1;
      end
      if (parallel_valid_in) begin
        if (count_to_serial < PARALLEL_SIZE) begin
          count_to_serial <= count_to_serial + 1;
          serial_valid_out <= 1'b1;
        end else begin
          count_to_serial <= 0;
          serial_valid_out <= 1'b0;
        end
      end
    end
  end

endmodule
