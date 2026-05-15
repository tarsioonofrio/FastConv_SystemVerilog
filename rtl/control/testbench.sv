`timescale 1ns/1ps

module tb;
  import pack_data::*;
  import pack_param::*;

  // Parâmetros do DUT
  localparam int unsigned N_CHANNEL_IN   =  3;
  localparam int unsigned N_CHANNEL_OUT   =  3;
  localparam int unsigned KERNEL_SIZE  =  6;
  localparam int unsigned FEAT_INPUT_SIZE   = 16;
  localparam int unsigned FEAT_INPUT_WIDTH = 16;
  localparam int unsigned CONV_MULTIPLY_STEPS = 6;
  localparam int unsigned NBITS = 20;
  localparam int unsigned QUANT = 8;
  localparam int unsigned A1_SIZE = 3;
  localparam int unsigned C1_SIZE = 5;
  localparam int unsigned M1_SIZE = 6;
  localparam int unsigned NMULT = 6;
  localparam int unsigned SMULT = 6;

  localparam int unsigned INPUT_MEMORY_SIZE = N_CHANNEL_IN*FEAT_INPUT_SIZE*FEAT_INPUT_WIDTH + N_CHANNEL_OUT*N_CHANNEL_IN*KERNEL_SIZE*KERNEL_SIZE;

  localparam int unsigned INPUT_MEMORY_INIT_SIZE = 1083;
  localparam int unsigned NADDR     = $clog2(INPUT_MEMORY_SIZE);

  // Sinais de interface
  logic clk;
  logic reset;
  logic p_start, p_end;
  logic [NADDR-1:0] p_input_addr;
  logic [19:0] p_input_data;

  // Reads directly from the dataset package memory image.
  assign p_input_data = (p_input_addr < INPUT_MEMORY_SIZE) ? NBITS'(const_data[p_input_addr]) : '0;

  // Instanciação do Módulo (DUT)
  Control #(
    .N_CHANNEL_IN(N_CHANNEL_IN),
    .N_CHANNEL_OUT(N_CHANNEL_OUT),
    .KERNEL_SIZE(KERNEL_SIZE),
    .FEAT_INPUT_SIZE(FEAT_INPUT_SIZE),
    .FEAT_INPUT_WIDTH(FEAT_INPUT_WIDTH),
    .NADDR(NADDR),
    .CONV_MULTIPLY_STEPS(CONV_MULTIPLY_STEPS),
    .NBITS(NBITS),
    .QUANT(QUANT),
    .A1_SIZE(A1_SIZE),
    .C1_SIZE(C1_SIZE),
    .M1_SIZE(M1_SIZE),
    .NMULT(NMULT),
    .SMULT(SMULT)
  ) dut (
    .clk(clk),
    .reset(reset),
    .p_start(p_start),
    .p_input_addr(p_input_addr),
    .p_input_data(p_input_data),
    .p_end(p_end)
  );

  // Gerador de Clock: 100MHz -> Período de 10ns
  initial clk = 0;
  always #5 clk = ~clk;

  // Estímulos
  initial begin

    // Reset inicial (Ativo alto conforme código fonte)
    reset = 1;
    p_start = 0;

    // Mantém reset por 20 ns
    #20 reset = 0;

    #80 p_start = 1;
    #10 p_start = 0;

    // aguarda p_end subir
    if (p_end !== 1'b1)
          @(posedge p_end);

      // espera mais 200 ns
    #200;

    $display("Simulacao finalizada em %0t", $time);
    $finish;
  end

endmodule
