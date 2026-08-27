`timescale 1ns/1ps

module tb_streaming_row;
  localparam int NBITS = 20;
  logic [NBITS-1:0] s [35:0];
  logic [NBITS-1:0] s_row [5:0];
  logic [NBITS-1:0] sigma [2:0];
  logic [NBITS-1:0] acc [8:0];
  logic [NBITS-1:0] acc_next [8:0];
  logic [NBITS-1:0] inverse_full [8:0];
  logic [2:0] row_idx;

  Inverse #(.NBITS(NBITS)) inverse_ref(.pin(s), .pout(inverse_full));
  InverseRow #(.NBITS(NBITS)) inverse_row(.s_row(s_row), .sigma(sigma));
  InverseRowAccumulate #(.NBITS(NBITS)) accumulator(
    .row_idx(row_idx), .acc_in(acc), .sigma(sigma), .acc_out(acc_next));

  task automatic check_vector(input int seed);
    begin
      for (int i = 0; i < 36; i++)
        s[i] = NBITS'($urandom(seed + i * 7919));
      acc = '{default: '0};
      for (int r = 0; r < 6; r++) begin
        row_idx = r[2:0];
        for (int c = 0; c < 6; c++)
          s_row[c] = s[r*6+c];
        #1;
        acc = acc_next;
      end
      #1;
      for (int i = 0; i < 9; i++)
        if (acc[i] !== inverse_full[i])
          $fatal(1, "IF row mismatch seed=%0d index=%0d got=%0h expected=%0h", seed, i, acc[i], inverse_full[i]);
    end
  endtask

  initial begin
    for (int seed = 1; seed <= 1000; seed++)
      check_vector(seed);
    $display("IF3 streaming row tests passed: random_vectors=1000");
    $finish;
  end
endmodule
