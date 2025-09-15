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
  logic p_reuse;

  logic p_start_conv;
  logic p_end_conv[3:0];

  logic p_fin_en;
  logic p_fin_valid;

  logic p_wh_en;
  logic p_wh_valid;

  logic p_fout_en;
  logic p_fout_valid;

  logic_vector data_control2core;
  logic_vector data_core2control;

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
    .p_start_conv(p_start_conv),
    .p_end_conv(p_end_conv),
    .p_reuse(p_reuse),

    .p_wh_en(p_wh_en),
    .p_wh_valid(p_wh_valid),

    .p_fin_en(p_fin_en),
    .p_fin_valid(p_fin_valid),

    .p_fout_en(p_fout_en),
    .p_fout_valid(p_fout_valid),

    .p_out_data(data_control2core),
    .p_in_data(data_core2control)
  );

  Core #(
    .QUANT(QUANT),
    .NBITS(NBITS)
  ) core (
    .clk(clk),
    .reset(reset),

    .p_start(p_start_conv),
    .p_end(p_end_conv),
    .p_reuse(p_reuse),

    .p_wh_en(p_wh_en),
    .p_wh_valid(p_wh_valid),

    .p_fin_en(p_fin_en),
    .p_fin_valid(p_fin_valid),

    .p_fout_en(p_fout_en),
    .p_fout_valid(p_fout_valid),

    .p_in_data(data_control2core),
    .p_out_data(data_core2control)
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


    // Carregar pesos
    // $display("=== Loading weights ===");
    // wait(p_wh_en);
    // for (int i = 0; i < W2_SIZE; i++) begin
    //   wait(p_wh_valid);
    //   // data_control2core = const_weight[0][i];
    //   $display("Weight[%0d] = %0d", i, data_control2core);
    //   @(posedge clk);
    // end

    // Start processamento
    $display("=== Start processing ===");


    // Monitorar saída (p_fout_valid = 1) e ler dados de saída
    for (int i = 0; i < FOUT2_SIZE; i++) begin
      @(posedge clk);
      wait(p_fout_en);
      for (int j = 0; j < FOUT2_SIZE; j++) begin
        @(posedge clk);
        wait(p_fout_valid);
        if ($signed(const_feat_out_batch[i][j]) != $signed(data_core2control)) begin
          $display("Time %0t | const_feat_out[%0d][%0d] = %0d | Output = %0d", $time, i, j, const_feat_out_batch[i][j], data_core2control);
        end
      end
    end

    wait(p_end);

    $display("End simulation");
    $finish;
  end


endmodule
