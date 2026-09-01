`timescale 1ns/1ps

module tb_streaming_row;
  localparam int NBITS = 20;
  logic [NBITS-1:0] s [15:0];
  logic [NBITS-1:0] s_row [3:0];
  logic [NBITS-1:0] sigma [1:0];
  logic [NBITS-1:0] acc [3:0];
  logic [NBITS-1:0] acc_next [3:0];
  logic [NBITS-1:0] inverse_full [3:0];
  logic [1:0] row_idx;

  Inverse #(.NBITS(NBITS)) inverse_ref(.pin(s), .pout(inverse_full));
  InverseRow #(.NBITS(NBITS)) inverse_row(.s_row(s_row), .sigma(sigma));
  InverseRowAccumulate #(.NBITS(NBITS)) accumulator(
    .row_idx(row_idx), .acc_in(acc), .sigma(sigma), .acc_out(acc_next));

  task automatic check_vector(input int seed);
    begin
      for (int i = 0; i < 16; i++)
        s[i] = NBITS'($urandom(seed + i * 7919));
      acc = '{default: '0};
      for (int r = 0; r < 4; r++) begin
        row_idx = r[1:0];
        for (int c = 0; c < 4; c++)
          s_row[c] = s[r*4+c];
        #1;
        acc = acc_next;
      end
      #1;
      for (int i = 0; i < 4; i++)
        if (acc[i] !== inverse_full[i])
          $fatal(1, "TC2 row mismatch seed=%0d index=%0d got=%0h expected=%0h", seed, i, acc[i], inverse_full[i]);
    end
  endtask

  initial begin
    // Golden example from the streaming implementation plan.
    s = '{default: '0};
    s[0] = 0; s[1] = -24; s[2] = 0; s[3] = 0;
    s[4] = -18; s[5] = 270; s[6] = 6; s[7] = 30;
    s[8] = 0; s[9] = 24; s[10] = 0; s[11] = 0;
    s[12] = 0; s[13] = 168; s[14] = 0; s[15] = 0;
    acc = '{default: '0};
    for (int r = 0; r < 4; r++) begin
      row_idx = r[1:0];
      for (int c = 0; c < 4; c++) s_row[c] = s[r*4+c];
      #1;
      acc = acc_next;
    end
    #1;
    if (acc[0] !== 20'd258 || acc[1] !== 20'd294 ||
        acc[2] !== 20'd402 || acc[3] !== 20'd438)
      $fatal(1, "TC2 directed mismatch: %0d %0d %0d %0d", acc[0], acc[1], acc[2], acc[3]);

    for (int seed = 1; seed <= 1000; seed++)
      check_vector(seed);
    $display("TC2 streaming row tests passed: random_vectors=1000");
    $finish;
  end
endmodule
