`timescale 1ns/1ps
module row_tb;
  localparam int NBITS = 20;
  logic [NBITS-1:0] s [35:0];
  logic [NBITS-1:0] inverse_input_row [5:0];
  logic [NBITS-1:0] inverse_partial [3:0];
  logic [NBITS-1:0] full [15:0];
  logic [NBITS-1:0] acc [15:0];
  logic [NBITS-1:0] next_acc [15:0];
  logic [2:0] inverse_row_idx;
  InverseRow row (.inverse_input_row(inverse_input_row), .inverse_partial(inverse_partial));
  InverseRowAccumulate accum (.inverse_row_idx(inverse_row_idx), .accumulator_in(acc), .inverse_partial(inverse_partial), .accumulator_out(next_acc));
  Inverse inverse (.pin(s), .pout(full));
  task automatic check(input int seed);
    for (int i = 0; i < 36; i++) s[i] = $urandom(seed + i);
    acc = '{default: '0};
    #1;
    for (int r = 0; r < 6; r++) begin
      inverse_row_idx = r;
      for (int i = 0; i < 6; i++) inverse_input_row[i] = s[r*6+i];
      #1;
      acc = next_acc;
    end
    #1;
    for (int i = 0; i < 16; i++)
      if (acc[i] !== full[i]) $fatal(1, "row %0d mismatch at %0d: %0d != %0d", seed, i, $signed(acc[i]), $signed(full[i]));
  endtask
  initial begin
    for (int seed = 1; seed <= 100; seed++) check(seed);
    $display("4x4 streaming row inverse passed");
    $finish;
  end
endmodule
