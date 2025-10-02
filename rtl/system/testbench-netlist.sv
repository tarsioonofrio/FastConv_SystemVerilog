module tb;
  timeunit 1ns;
  timeprecision 1ps;

  import pack_def::*;
  import pack_data::*;
  import pack_param::*;
  import pack_typedef::*;

  logic clk;
  logic reset;

  logic p_start;
  logic p_end;


  int count_fout = 0;

  // Clock generation (10ns period)
  initial clk = 0;
  always #5 clk = ~clk;

  // DUT instantiation
  System dut (
    .clk(clk),
    .reset(reset),

    .p_start(p_start),
    .p_end(p_end)
  );

  // Inicialização dos sinais e reset
  initial begin
    reset = 1;
    p_start = 0;
    @(posedge clk);
    reset = 0;
    p_start = 1;

    // Start processamento
    $display("=== Start processing ===");

    @(posedge clk);
    p_start = 0;

    for (int i = 0; i < FOUT1_SIZE; i++) begin
      @(posedge clk);
      wait(dut.control.p_conv_end);
      $display("=== OI ====");
      @(posedge clk);
      for (int j = 0; j < FOUT2_SIZE; j++) begin
        @(posedge clk);
        wait(dut.control.p_write_en);
        if ($signed(const_feat_out_batch[i][j]) != $signed(dut.control.p_write_data)) begin
          $display("Time %0t | const_feat_out[%0d][%0d] = %0d | Output = %0d", $time, i, j, const_feat_out_batch[i][j], dut.control.p_write_data);
          $display("=== ERROR - End simulation ====");
        end
      end
    end

    wait(p_end);
    $display("=== No errors - End simulation ===");
    $finish;
  end
endmodule
