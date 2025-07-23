module tb;
  timeunit 1ns;
  timeprecision 1ps;

  import data::*;
  import packConv::*;

  // Parâmetros conforme Core
  localparam int QUANT            = 8;
  localparam int NBITS            = 20;
  localparam int NADDR            = 12;
  localparam int WEIGHT_SIZE      = 1;
  localparam int BUFFER_IN_SIZE   = 512;
  localparam int WINDOW_IN_SIZE   = 64;
  localparam int WINDOW_IN_NUM    = 4;
  localparam int LATENCY          = 0;
  localparam int ROM              = 0;
  localparam int SERIAL_SIZE      = 36;
  localparam int PARALLEL_SIZE    = 9;

  logic clk, reset;

  logic p_start;
  logic p_end;
  logic p_debug;

  logic p_fin_en;
  logic p_fin_valid;

  logic p_wh_en;
  logic p_wh_valid;

  logic p_fout_en;
  logic p_fout_valid;

  logic_vector p_fin_data;
  logic_vector p_fout_data;

  // Clock generation (10ns period)
  initial clk = 0;
  always #5 clk = ~clk;

  // DUT instantiation
  Core #(
    .QUANT(QUANT),
    .NBITS(NBITS)
  ) dut (
    .clk(clk),
    .reset(reset),

    .p_start(p_start),
    .p_end(p_end),
    .p_debug(p_debug),

    .p_fin_en(p_fin_en),
    .p_fin_valid(p_fin_valid),

    .p_wh_en(p_wh_en),
    .p_wh_valid(p_wh_valid),

    .p_fout_en(p_fout_en),
    .p_fout_valid(p_fout_valid),

    .p_fin_data(p_fin_data),
    .p_fout_data(p_fout_data)
  );

  // Inicialização dos sinais e reset
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);

    reset = 1;

    // Inicializa sinais de controle e dados
    p_fin_en = 0;
    p_wh_en = 0;
    p_start = 0;
    p_fin_data = '0;

    // Aguarda 1 ciclos de clock
    @(posedge clk);
    reset = 0;


    // Carregar pesos
    $display("=== Loading weights ===");
    p_wh_en = 1;
    @(posedge clk);

    for (int i = 0; i < W2_SIZE; i++) begin
      p_fin_data = const_weight[0][i];
      $display("Weight[%0d] = %0d", i, p_fin_data);
      @(posedge clk);
    end

    p_wh_en = 0;
    wait(p_end);
    @(posedge clk);

    // Carregar dados de entrada
    $display("=== Loading data ===");
    p_fin_en = 1;
    @(posedge clk);

    for (int i = 0; i < FIN2_SIZE; i++) begin
      p_fin_data = const_feat_in[0][i];
      $display("Input data[%0d] = %0d", i, p_fin_data);
      @(posedge clk);
    end

    p_fin_en = 0;
    wait(p_end);
    @(posedge clk);

    // Start processamento
    $display("=== Start processing ===");
    p_start = 1;
    @(posedge clk);
    p_start = 0;

    @(posedge clk);
    wait(p_end);

    // Monitorar saída (p_fout_valid = 1) e ler dados de saída
    @(posedge clk);
    if (p_fout_valid) begin
      $display("Time %0t: Output = %0d", $time, p_fout_data);
    end

    $display("End simulation");
    $finish;
  end
endmodule
