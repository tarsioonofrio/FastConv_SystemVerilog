
module Core
  import packConv::*;
 #(
    parameter int QUANT = 8,
    parameter int NBITS = 20,
    parameter int N_FILTER       = 16,
    parameter int N_CHANNEL      = 3,
    parameter int X_SIZE         = 32,
    parameter int FILTER_WIDTH   = 3,
    parameter int CONVS_PER_LINE = 15,
    parameter int MEM_SIZE       = 12,
    parameter int INPUT_SIZE     = 8,
    parameter int CARRY_SIZE     = 4,
    parameter int SHIFT          = 8,
    parameter int LAT            = 2
  )
  (
    input  logic clk, reset,

    input  logic p_start,
    output logic p_end,
    output logic p_debug,

    input  logic p_in_ce,
    input  logic p_in_we,
    output logic p_in_valid,

    input  logic p_out_ce,
    input  logic p_out_we,
    output logic p_out_valid,

    input  logic_vector p_addr,
    input  logic_vector p_in_data,
    output logic_vector p_out_data
 );

  timeunit 1ns;
  timeprecision 1ps;

  type_input  inputMAP;
  type_weight weights;
  type_output outputMAP;
  logic       data_valid;

  // start -> weight -> if -> of
  //                 -> if -> of
  typedef enum {IDLE, WRWEIGHT[36-1], WRWEIGHTN, WRINPUT[25-1], WRINPUTN, RD[9-1], RDN} state_type;
  state_type current_st, next_st;

  type_weight   registers;

  logic[5:0] idx;

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
    .QUANT(QUANT_BITS)
  ) convolucao (
    .clk(clk),
    .reset(reset),
    .start(start),
    .inputMAP(conv_data_in),
    .weights(conv_data_in),
    .outputMAP(mem_data_in),
    .data_valid(cont_data_valid)
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

  // 9 states + IDEL - IDLE is blocking!
  always_comb begin
    mem_data_in = (p_in_ce == 1'b1 && p_in_we == 1'b1) ? p_in_data : conv_data_out;
    p_out_data = mem_data_out;
    conv_data_in = mem_data_out;

    unique case (current_st)
      IDLE: begin
        if (p_in_ce == 'b1 && p_in_ce == 'b1)
          next_st = IDLE;
        else if (start == 'b1)
          next_st = WRWEIGHT1;
        else if (p_ofmap_ce == 'b1 && p_ofmap_we == 'b0)
          next_st = RD;
        else
          next_st = IDLE;
      end
      WRWEIGHTN:    next_st = IDLE;
      WRINPUTN:    next_st = IDLE;
      RDN:      next_st = IDLE;
      default:  next_st = state_type'(current_st + 1);
    endcase
  end

  //
  // Data path
  //



  // Internal register bank to store intermediate results
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      registers <= '{default: '0};
    end else begin
      unique case (current_st)
        IDLE:     registers <= registers;
        WR_IFMAP: registers[24:0] <= inputMAP;
        WR_MC:    registers <= prod_c;
        WR_OUT: begin
          registers[8:0] <= prod_a;
        end
        default:  registers[idx] <= product;
      endcase
    end
  end

  // connect 9 first registers to the outputs
  always_comb begin
    outputMAP = registers[8:0];
  end

endmodule
