module Core
  import packConv::*;
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

    input  logic p_start,
    output logic p_end,
    output logic p_debug,

    input  logic p_in_ce,
    input  logic p_in_we,
    output logic p_in_valid,

    output logic p_out_ce,
    output logic p_out_we,
    input  logic p_out_valid,

    input  logic [NADDR-1:0] p_address,
    input  logic_vector      p_in_data,
    output logic_vector      p_out_data
 );

  timeunit 1ns;
  timeprecision 1ps;

  type_input  conv_in;
  type_weight conv_weights;
  type_output conv_out;
  logic       data_valid;

  // start -> weight -> if -> of
  //                 -> if -> of
  typedef enum {IDLE, WEIGHT, EXTERNALIF, INTERNALIF} state_type;
  state_type current_st, next_st;

  type_weight   register_in, register_out;

  logic [NADDR-1:0] address;

  logic out_ce;
  logic out_we;
  logic out_valid;

  logic_vector mem_data_in, conv_data_in;

  int reg_count;
  int reg_count_weight;
  int reg_count_window;

  int count;
  int count_weight;
  int count_window;

  // Instantiate conv_rapida entity
  Memory #(
    .NADDR(NADDR),
    .NBITS(NBITS),
    .LATENCY(0),
    .ROM(ROM)
  ) memory (
    .clk(clk),
    .reset(reset),
    .chip_en(p_in_ce),
    .wr_en(p_in_we),
    .address(p_addr),
    .data_in(mem_data_in),
    .data_out(mem_data_out),
    .data_valid(mem_data_valid)
  );
  
  conv #(
    .QUANT(QUANT)
  ) convolucao (
    .clk(clk),
    .reset(reset),
    .start(start),
    .inputMAP(conv_in),
    .weights(conv_weights),
    .outputMAP(conv_out),
    .data_valid(cont_data_valid)
  );

  always_comb begin
    next_st = current_st; // default hold
    mem_data_in = (current_st == WEIGHT || current_st == EXTERNALIF) ? p_in_data : conv_out;
    // Drive p_out_ce signal based on current state
    p_out_ce = (current_st == WEIGHT || current_st == EXTERNALIF || current_st == INTERNALIF) ? 1'b1 : 1'b0;
    p_out_data = mem_data_out;
    conv_data_in = mem_data_out;

    unique case (current_st)
      IDLE:
        if (start == 1'b1)
          next_st = WEIGHT;
      WEIGHT:
        if (p_in_valid && count >= WEIGHT_SIZE)
          next_st = EXTERNALIF;
      EXTERNALIF:
        if (p_in_valid && count >= BUFFER_IN_SIZE)
          next_st = INTERNALIF;
      INTERNALIF:
        if (p_in_valid && count >= WINDOW_IN_SIZE) begin
          if (count_window + 1 < WINDOW_IN_NUM)
            next_st = INTERNALIF;
          else
            next_st = IDLE;
          end
      default:
        next_st = IDLE;
    endcase
  end


  //
  // Control FSM
  //

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      current_st <= IDLE;
      count <= 0;
      count_weight <= 0;
      count_window <= 0;
      address <= 0;
    end else begin
      current_st <= next_st;

      // Update counters only based on state/conditions
      case (current_st)
        WEIGHT:
          if (p_in_valid) begin
            if (count < WEIGHT_SIZE)
              count <= count + 1;
            else begin
              count <= 0;
              count_weight <= count_weight + 1;
            end
          end
        EXTERNALIF:
        if (p_in_valid) begin
          if (count < BUFFER_IN_SIZE) begin
            count <= count + 1;
            address <= address + 1;
          end else begin
            count <= 0;
          end
        end
        INTERNALIF:
          if (p_in_valid) begin
            if (count < WINDOW_IN_SIZE)
              count <= count + 1;
            else begin
              count <= 0;
              count_window <= count_window + 1;
            end
          end
          default: begin
            count <= 0;
            count_weight <= 0;
            count_window <= 0;
          end
      endcase

    end
  end

endmodule
