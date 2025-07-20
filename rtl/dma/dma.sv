module Core
  import packConv::*;
  import data::*;
#(
    parameter int NADDR           = 12,
    parameter int NBITS           = 20,
    parameter int LATENCY         = 1,
    parameter int ROM             = 0,
    parameter int QUANT           = 8,
    parameter int NBITS           = 20,
    parameter int NADDR           = 12,
    parameter int WEIGHT_SIZE     = 16,
    parameter int FEAT_SIZE       = 16,
    parameter int LINE_WINDOW     = 15,
    parameter int LAST_HORIZONTAL = 0,
    parameter int LAST_VERTICAL   = 0
) (
    input  logic clk,
    input  logic reset,

    // input  logic p_start,
    // output logic p_end,
    // output logic p_debug,

    input logic p_in_en,
    input logic p_in_valid,
    input  logic_vector p_in_data,

    output logic p_out_en,
    output logic p_out_valid,
    output logic_vector p_out_data
);

  timeunit 1ns; timeprecision 1ps;

  typedef enum {
    IDLE,
    BIAS,
    WEIGHT,
    FEAT_IN,
    CONV,
    FEAT_OUT
  } state_type;

  state_type current_st, next_st;

  logic r_data_end;
  logic r_out_en;
  logic r_conv_end;

  int r_count_wh;
  int r_count_in;
  int r_count_out;

  logic_vector  data_in;
  logic_vector  data_out;


  logic chip_en;
  logic wr_en;
  logic data_valid_out;
  logic[NADDR-1:0] address;

  Memory #(
    .NADDR(NADDR),
    .NBITS(NBITS),
    .LATENCY(LATENCY),
    .ROM(ROM)
  ) memory (
    .clk(clk),
    .reset(reset),
    .chip_en(chip_en),
    .wr_en(wr_en),
    .address(address),
    .data_in(data_in),
    .data_out(data_out),
    .data_valid(data_valid_out)
  );


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
      IDLE:     if (p_start) next_st = BIAS;
      BIAS:     if (p_out_valid) next_st = WEIGHT;
      WEIGHT:   if (r_count_wh == M1_SIZE * M2_SIZE) next_st = FEAT_IN;
      FEAT_IN:  if (r_count_in == C1_SIZE * C2_SIZE) next_st = CONV;
      FEAT_OUT: if (r_count_out == A1_SIZE * A2_SIZE) next_st = IDLE;
    endcase
  end


  always_comb begin
    // Feature input and weights
    p_out_data <= data_out;
    p_out_en <= chip_en;
    p_out_valid <= data_valid_out;

    // Feature output
    data_in <= p_in_data;
    chip_en <= p_in_en;
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      r_count_out <= 0;
      r_count_in <= 0;
    end else begin
      unique case (current_st)
        IDLE: begin
          r_count_out <= 0;
          r_count_in <= 0;
        end
        WEIGHT: begin
          if (data_valid_out && (r_count_in < M1_SIZE * M2_SIZE))
            r_count_in <= r_count_in + 1;
          else
            r_count_in <= 1'b0;
        end
        FEAT_IN: begin
          if (data_valid_out && (r_count_in < C1_SIZE * C2_SIZE))
            r_count_in <= r_count_in + 1;
          else
            r_count_in <= 1'b0;
        end
        FEAT_OUT: begin
          if (p_in_valid && (r_count_out < (A1_SIZE * A2_SIZE)))
            r_count_out  <= r_count_out + 1;
          else
            r_count_out  <= 1'b0;
        end
      endcase
    end
  end
endmodule
