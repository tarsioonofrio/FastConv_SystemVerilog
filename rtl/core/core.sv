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
  logic output_valid;

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

  int count_to_parallel;
  int count_to_serial;


  state_type_conv current_st_conv, next_st_conv;

  type_weight   registers;
  type_weight   prod_c;
  type_output   prod_a;

  logic       data_valid;
  type_input  inputMAP;
  type_weight weights;
  logic signed[NBITS-1+QUANT:0] product;   // QUANT more bits for the multipliers

  logic[5:0] idx;



  // conv #(
  //   .QUANT(QUANT)
  // ) convolucao (
  //   .clk(clk),
  //   .reset(reset),
  //   .start(start_conv),
  //   .inputMAP(input_map),
  //   .weights(register_weight),
  //   .outputMAP(output_map),
  //   .data_valid(output_valid)
  // );

  //
  // BLOCK: Control FSM
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
        if (parallel_valid_out)
            next_st = IDLE;
      CONV:
        if (output_valid)
            next_st = DATA_OUT;
      DATA_OUT:
        if (serial_data_out)
          next_st = IDLE;
    endcase
  end

  always_comb begin
    p_end = s_end;
    start_conv = p_start;
  //   p_end = 1'b1 ? current_st ==  IDLE: 1'b0;
  //   start_conv = 1'b1 ? current_st == DATA_IN: 1'b0;
  end


  always_ff @(posedge clk) begin
    if (reset) begin
      registers_out = '{default: '0};
      register_weight = '{default: '0};
      s_end <= 1'b0;
      count_to_serial <= 0;
      count_to_parallel <= 0;
      registers <= '{default: '0};
      data_valid <= 0;
    end else begin
      if (output_valid) begin
        registers_out = output_map;
        s_end <= 1'b1;
      end
      unique case (current_st)
        IDLE: begin
          registers_out = '{default: '0};
          // register_weight <= '{default: '0};
          s_end <= 1'b0;
        end
        WEIGHT: begin
          if (p_wh_ce && (count_to_parallel < 36)) begin
            register_weight[count_to_parallel] = serial_data_in;
            count_to_parallel <= count_to_parallel + 1;
            parallel_valid_out <= 1'b0;
          end else begin
            count_to_parallel <= 0;
            parallel_valid_out <= 1'b1;
          end
          if (parallel_valid_out)
            s_end <= 1'b1;
        end
        DATA_IN: begin
          if (p_in_ce && (count_to_parallel < 25)) begin
            count_to_parallel <= count_to_parallel + 1;
            parallel_valid_out <= 1'b0;
          end else begin
            count_to_parallel <= 0;
            parallel_valid_out <= 1'b1;
          end
          if (parallel_valid_out)
              s_end <= 1'b1;
        end
        CONV: begin
          data_valid <= 0;
          unique case (current_st_conv)
            // IDLE:     registers <= registers;
            IDLE: registers[24:0] <= inputMAP;
            WR_MC:    registers <= prod_c;
            WR_OUT: begin
              data_valid <= 1;
              registers[8:0] <= prod_a;
            end
          endcase
        end
        default:  registers[idx] <= product;
      endcase
    end
  end

  // BLOCKS: CONNECT

  always_comb begin
    serial_data_in = p_in_data;
    if (current_st == DATA_IN)
      input_map <= parallel_data_out[24:0];
  end


  // always_ff @(posedge clk or posedge reset) begin
  //   if (reset) begin
  //     register_weight = '{default: '0};
  //   end else begin
  //     if (current_st == WEIGHT)
  //       register_weight[count_to_parallel] = serial_data_in;
  //   end
  // end


  // ---------------------------------------------------------
  // BLOCK: serialize

  always_comb begin
    serial_data_out = parallel_data_in[count_to_serial];
    parallel_data_out[count_to_parallel] = serial_data_in;
  end

  // always_ff @(posedge clk or posedge reset) begin
  //   if (reset) begin
  //     count_to_serial <= 0;
  //     count_to_parallel <= 0;
  //   end
  //   else begin
  //     if (p_in_ce || p_wh_ce) begin
  //       if (p_wh_ce && (count_to_parallel < 36)) begin
  //         count_to_parallel <= count_to_parallel + 1;
  //         parallel_valid_out <= 1'b0;
  //       end else if (p_in_ce && (count_to_parallel < 25)) begin
  //         count_to_parallel <= count_to_parallel + 1;
  //         parallel_valid_out <= 1'b0;
  //       end else begin
  //         count_to_parallel <= 0;
  //         parallel_valid_out <= 1'b1;
  //       end
  //     end
  //     if (parallel_valid_in) begin
  //       if (count_to_serial < 36) begin
  //         count_to_serial <= count_to_serial + 1;
  //         serial_valid_out <= 1'b1;
  //       end else begin
  //         count_to_serial <= 0;
  //         serial_valid_out <= 1'b0;
  //       end
  //     end
  //   end
  // end

  // BLOCK: Convolution

  // parameter int QUANT = 8,
  // parameter int NBITS = 20,
  // parameter int NMULT = 1,
  // parameter int SMULT = 36
  type_output outputMAP;
  logic       start;

  always_comb begin
    start = start_conv;
    inputMAP = input_map;
    weights = register_weight;
    output_map = outputMAP;
    output_valid = data_valid;
  end

  //
  // Control FSM
  //

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      current_st_conv <= IDLE1;
    end else begin
      current_st_conv <= next_st_conv;
    end
  end

  // 9 states + IDEL - IDLE is blocking!
  always_comb begin
    unique case (current_st_conv)
      IDLE1:     next_st_conv = start ? WR_MC : IDLE1;
      // WR_IFMAP: next_st_conv = WR_MC;
      WR_MC:    next_st_conv = MU0;
      WR_OUT:   next_st_conv = IDLE1;
      default: next_st_conv = state_type_conv'(current_st_conv + 1);
    endcase
  end

  //
  // Data path
  //

  // Instance of matrix multiplier "C"
  Transform trf(
    .pin(registers[24:0]),
    .pout(prod_c)
  );

  assign idx = current_st_conv;

  Multip multip0(.register(registers[idx]), .weight(weights[idx]), .product(product));

  // Instance of matrix multiplier "A"
  Inverse inv(
    .pin(registers),
    .pout(prod_a)
  );

  // Internal register bank to store intermediate results
  // always_ff @(posedge clk or posedge reset) begin
  //   if (reset) begin
  //     registers <= '{default: '0};
  //     data_valid <= 0;
  //   end else begin
  //     data_valid <= 0;
  //     unique case (current_st_conv)
  //       // IDLE:     registers <= registers;
  //       IDLE: registers[24:0] <= inputMAP;
  //       WR_MC:    registers <= prod_c;
  //       WR_OUT: begin
  //         data_valid <= 1;
  //         registers[8:0] <= prod_a;
  //       end
  //       default:  registers[idx] <= product;
  //     endcase
  //   end
  // end

  // connect 9 first registers to the outputs
  always_comb begin
    outputMAP = registers[8:0];
  end


endmodule


module Multip
  import packConv::*;
 #(
  parameter int QUANT = 8,
  parameter int NBITS = 20
  )
  (
    input  logic_vector register,
    input  logic_vector weight,
    output logic signed [NBITS-1+QUANT:0] product
 );
  timeunit 1ns;
  timeprecision 1ps;
  logic signed [NBITS-1+QUANT:0] partial_product;

  assign partial_product = (NBITS+QUANT)'($signed(register) * $signed(weight));
  assign product = (NBITS)'(partial_product[NBITS-1+QUANT:QUANT]);
endmodule
