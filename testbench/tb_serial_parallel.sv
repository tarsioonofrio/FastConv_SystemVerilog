module tb;
  timeunit 1ns;
  timeprecision 1ps;

  import data::*;
  import packConv::*;

  // Parâmetros dos pacotes
  localparam int NBITS = 20;
  localparam int WINDOW_IN_SIZE = 64; // parâmetro do módulo (default)
  localparam int A1_SIZE = 3;          // do pacote data
  localparam int PARALLEL_SIZE = A1_SIZE * A1_SIZE; // 9
  localparam int SERIAL_OUT_SIZE = WINDOW_IN_SIZE;  // 64

  // typedef logic [NBITS-1:0] logic_vector;
  // typedef logic_vector type_output [0:PARALLEL_SIZE-1];   // 9 elems
  // typedef logic_vector type_weight [0:SERIAL_OUT_SIZE-1]; // 64 elems

  logic clk, reset;
  logic serial_valid, parallel_valid;

  logic_vector serial_in;
  type_output parallel_in;
  type_weight parallel_out;
  logic_vector serial_out;

  // Clock generation (10 ns period)
  initial clk = 0;
  always #5 clk = ~clk;

  // DUT instance
  SerialParallel #(
    .NBITS(NBITS),
    .WINDOW_IN_SIZE(WINDOW_IN_SIZE)
  ) dut (
    .clk(clk),
    .reset(reset),
    .serial_valid(serial_valid),
    .parallel_valid(parallel_valid),
    .serial_in(serial_in),
    .parallel_in(parallel_in),
    .parallel_out(parallel_out),
    .serial_out(serial_out)
  );

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);

    // Reset
    reset = 1;
    serial_valid = 0;
    parallel_valid = 0;
    serial_in = '0;

    for (int i = 0; i < PARALLEL_SIZE; i++)
      parallel_in[i] = const_feat_out[0][i];

    #20;
    reset = 0;
    @(posedge clk);

    // Teste 1 - paralelismo para serial_out
    $display("== Teste 1: parallel_valid ativo = 1");
    parallel_valid = 1;
    @(posedge clk);
    parallel_valid = 0;

    // Esperar o módulo serializar todos os dados
    for (int i = 0; i < PARALLEL_SIZE + 2; i++) begin
      @(posedge clk);
      $display("Cycle %0d: serial_out = %0d", i, serial_out);
    end

    // Teste 2 - serial_in para paralelização
    $display("== Teste 2: serial_valid ativo = 1 com const_feat_in");
    serial_valid = 1;
    for (int i = 0; i < WINDOW_IN_SIZE; i++) begin
      serial_in = const_feat_in[0][i];
      @(posedge clk);
      $display("Cycle %0d: parallel_out[%0d] = %0d", i, i, parallel_out[i]);
    end
    serial_valid = 0;

    // Espera alguns ciclos para estabilizar
    repeat (5) @(posedge clk);

    $display("Fim da simulação");
    $finish;
  end
endmodule
