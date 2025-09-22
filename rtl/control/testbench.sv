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

  logic p_conv_start;
  logic p_conv_end;

  type_input p_input;
  type_weight p_weight;
  type_output p_output;

  int count_fout = 0;

  // Clock generation (10ns period)
  initial clk = 0;
  always #5 clk = ~clk;

  // DUT instantiation
  Control #(
    .NADDR(NADDR),
    .NBITS(NBITS),
    .LATENCY(LATENCY),
    .ROM(ROM),
    .QUANT(QUANT),
    .FEAT_INPUT_SIZE(FEAT_INPUT_SIZE),
    .FEAT_OUTPUT_SIZE(FEAT_OUTPUT_SIZE),
    .N_WINDOW(N_WINDOW),
    .N_CHANNEL_IN(N_CHANNEL_IN),
    .N_CHANNEL_OUT(N_CHANNEL_OUT),
    .LAST_WINDOW(LAST_WINDOW)
  ) dut (
    .clk(clk),
    .reset(reset),

    .p_start(p_start),
    .p_end(p_end),
    .p_conv_start(p_conv_start),
    .p_conv_end(p_conv_end),
    .p_input(p_input),
    .p_weight(p_weight),
    .p_output(p_output)
  );

  Conv #(
    .QUANT(QUANT),
    .NBITS(NBITS)
  ) conv (
    .clk(clk),
    .reset(reset),

    .p_start(p_conv_start),
    .p_end(p_conv_end),
    .p_input(p_input),
    .p_weight(p_weight),
    .p_output(p_output)
  );


  // Inicialização dos sinais e reset
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);

    reset = 1;
    p_start = 0;
    @(posedge clk);
    reset = 0;
    p_start = 1;
    @(posedge clk);
    p_start = 0;

    // Start processamento
    $display("=== Start processing ===");

    // Monitorar saída (p_fout_valid = 1) e ler dados de saída
    for (int i = 0; i < FOUT1_SIZE; i++) begin
      @(posedge clk);
      wait(p_conv_end);
      @(posedge clk);
      // $display("*** Time %0t | i = %0d ***", $time, i);
      for (int j = 0; j < FOUT2_SIZE; j++) begin
        if ($signed(const_feat_out_batch[i][j]) != $signed(p_output[j])) begin
          $display("Time %0t | const_feat_out[%0d][%0d] = %0d | Output = %0d", $time, i, j, const_feat_out_batch[i][j], p_output[j]);
          $display("=== ERROR - End simulation ====");
        end
      end
    end

    wait(p_end);

    $display("=== No errors - End simulation ===");
    $finish;
  end


endmodule
