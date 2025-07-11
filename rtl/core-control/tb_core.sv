module tb;
  timeunit 1ns;
  timeprecision 1ps;

  import data::*;
  import packConv::*;

  logic clk, reset;
  logic serial_valid_in, parallel_valid_in, serial_valid_out, parallel_valid_out, feature_in, weight_in, feature_out, weight_out, end_serial_out;

  logic_vector serial_data_in;
  type_output parallel_data_in;
  type_weight parallel_data_out;
  logic_vector serial_data_out;

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
    .serial_data_in(serial_data_in),
    .serial_valid_out(serial_valid_out),
    .parallel_valid_out(parallel_valid_out),

    .parallel_valid_in(parallel_valid_in),
    .parallel_data_in(parallel_data_in),
    .parallel_data_out(parallel_data_out),
    .serial_data_out(serial_data_out),

    .end_serial_out(end_serial_out)
  );

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);

    // Reset
    reset = 1;
    serial_valid_in = 0;
    parallel_valid_in = 0;
    serial_data_in = '0;
    #20;
    reset = 0;
    parallel_valid_in = 1;

    for (int i = 0; i < FOUT2_SIZE; i++)
      parallel_data_in[i] = const_feat_out[0][i];

    @(posedge clk);

    // TEST 1 - paralelismo para serial_data_out
    // $display("== TEST 1: parallel_enable = 1");
    // parallel_valid_out = 1;
    // @(posedge clk);
    // parallel_valid_out = 0;

    // Esperar o módulo serializar todos os dados
    for (int i = 0; i < FOUT2_SIZE; i++) begin
      @(posedge clk);
      $display("Time %0d: | parallel_data_in = %0d | serial_data_out = %0d", $time, parallel_data_in[i], serial_data_out);
    end

    // TEST 2 - serial_data_in para paralelização
    $display("== TEST 2: serial_enable = 1 const_feat_in");
    serial_valid_in = 1;
    weight_in = 1;
    @(posedge clk);
    for (int i = 0; i < W2_SIZE; i++) begin
      serial_data_in = const_weight[0][i];
      @(posedge clk);
      #1;
      $display("Time %0d | serial_data_in = %0d | parallel_data_out[%0d] = %0d", $time, const_weight[0][i], i, parallel_data_out[i]);
    end
    serial_valid_in = 0;
    weight_in = 0;

    // Espera alguns ciclos para estabilizar
    repeat (5) @(posedge clk);

    $display("End simulation");
    $finish;
  end
endmodule
