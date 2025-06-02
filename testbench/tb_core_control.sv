module tb;
  timeunit 1ns;
  timeprecision 1ps;

  import data::*;
  import packConv::*;

  logic clk, reset;
  logic serial_valid_in, parallel_valid_in, serial_valid_out, parallel_valid_out, feature_in, weight_in, feature_out, weight_out;

  logic_vector serial_in;
  type_output parallel_in;
  type_weight parallel_out;
  logic_vector serial_out;

  // Clock generation (10 ns period)
  initial clk = 0;
  always #5 clk = ~clk;

  // DUT instance
  CoreControl #(
    // .NBITS(NBITS),
    // .W2_SIZE(W2_SIZE)
  ) dut (
    .clk(clk),
    .reset(reset),
    .serial_valid_in(serial_valid_in),
    .parallel_valid_in(parallel_valid_in),
    .feature_in(feature_in),
    .feature_out(feature_out),
    .weight_in(weight_in),
    .serial_in(serial_in),
    .serial_valid_out(serial_valid_out),
    .parallel_valid_out(parallel_valid_out),
    .weight_out(weight_out),
    .parallel_in(parallel_in),
    .parallel_out(parallel_out),
    .serial_out(serial_out)
  );

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);

    // Reset
    reset = 1;
    serial_valid_in = 0;
    parallel_valid_in = 0;
    serial_in = '0;
    #20;
    reset = 0;

    for (int i = 0; i < FOUT2_SIZE; i++)
      parallel_in[i] = const_feat_out[0][i];

    @(posedge clk);

    // TEST 1 - paralelismo para serial_out
    // $display("== TEST 1: parallel_valid = 1");
    // parallel_valid_out = 1;
    // @(posedge clk);
    // parallel_valid_out = 0;

    // Esperar o módulo serializar todos os dados
    for (int i = 0; i < FOUT2_SIZE; i++) begin
      @(posedge clk);
      $display("Cycle %0d: serial_out = %0d", i, serial_out);
    end

    // TEST 2 - serial_in para paralelização
    $display("== TEST 2: serial_valid = 1 const_feat_in");
    serial_valid_in = 1;
    weight_in = 1;
    @(posedge clk);
    for (int i = 0; i < W2_SIZE; i++) begin
      serial_in = const_weight[0][i];
      @(posedge clk);
      $display("Time %0d | serial_in = %0d | parallel_out[%0d] = %0d", $time, const_weight[0][i], i, parallel_out[i]);
    end
    serial_valid_in = 0;
    weight_in = 0;

    // Espera alguns ciclos para estabilizar
    repeat (5) @(posedge clk);

    $display("End simulation");
    $finish;
  end
endmodule
