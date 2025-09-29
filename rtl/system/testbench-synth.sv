module tb;
  timeunit 1ns;
  timeprecision 1ps;

  import data::*;
  import pack_def::*;
  import pack_typedef::*;
  import pack_param::*;

  // Parâmetros conforme Core
  localparam int NADDR            = 12;
  localparam int NBITS            = 20;
  localparam int LATENCY          = 1;
  localparam int ROM              = 1;
  localparam int QUANT            = 8;
  localparam int FEAT_INPUT_SIZE  = 32;
  localparam int FEAT_OUTPUT_SIZE = 30;
  localparam int N_WINDOW         = 10;
  localparam int N_CHANNEL_IN     = 1;
  localparam int N_CHANNEL_OUT    = 1;
  localparam int LAST_WINDOW      = 0;

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
    $shm_open("dut.shm");
    $shm_probe(tb.dut, "ASM");


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
