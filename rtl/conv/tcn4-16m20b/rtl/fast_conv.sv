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


module conv
  import packConv::*;
 #(
   parameter int QUANT = 8,
   parameter int NBITS = 20,
   parameter int NMULT = 16
   )
  (
    input  logic       clk, reset, start,
    input  type_input  inputMAP,
    input  type_input  weights,
    output type_output outputMAP,
    output logic       data_valid
 );

  timeunit 1ns;
  timeprecision 1ps;

  type_input    registers;
  type_matrix_c prod_c;
  type_output   prod_a;

  logic signed [NBITS-1+QUANT:0] product[0:NMULT];   // QUANT more bits for the multipliers

  state_type current_st, next_st;

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
      IDLE:     next_st = start ? WR_IFMAP : IDLE;
      WR_IFMAP: next_st = WR_MC;
      WR_MC:    next_st = MU;
      MU:       next_st = WR_OUT;
      default:  next_st = IDLE;
    endcase
  end

  //
  // Data path
  //

  // Instance of matrix multiplier "C"
  Transform trf(
    .pin(registers),
    .pout(prod_c)
  );

  // assign idx = addr[current_st];

  generate
    for (genvar i = 0; i < NMULT; i++) begin
      Multip multip(.register(registers[i]), .weight(weights[i]), .product(product[i]));
    end
  endgenerate

  // Instance of matrix multiplier "A"
  Inverse inv(
    .pin(registers),
    .pout(prod_a)
  );

  // Internal register bank to store intermediate results
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      registers <= '{default: '0};
      data_valid <= 0;
    end else begin
      data_valid <= 0;  // default
      unique case (current_st)
        IDLE:     registers <= registers;
        WR_IFMAP: registers <= inputMAP;
        WR_MC:    registers <= prod_c;
        WR_OUT: begin
          data_valid <= 1;
          registers[3:0] <= prod_a;
        end
        default:  begin
          for (int i = 0; i < NMULT; i++) begin
            registers[i] <= product[i];
          end
        end
      endcase
    end
  end

  always_comb begin
    outputMAP = registers[3:0];
  end

endmodule
