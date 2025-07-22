module tb;
  timeunit 1ns;
  timeprecision 1ps;

  import data::*;
  import packConv::*;

  // Parâmetros conforme Core
  localparam int NADDR           = 12;
  localparam int NBITS           = 20;
  localparam int LATENCY         = 1;
  localparam int ROM             = 0;
  localparam int QUANT           = 8;
  localparam int NADDR           = 12;
  localparam int FEAT_IN_SIZE    = 32;
  localparam int N_WINDOW        = 15;
  localparam int N_CHANNEL_IN    = 1;
  localparam int N_CHANNEL_OUT   = 1;
  localparam int LAST_WINDOW     = 0;

  logic clk;
  logic reset;

  logic p_start;
  logic p_end;

  logic p_in_en;
  logic p_in_valid;
  logic_vector p_in_data;

  logic p_out_en;
  logic p_out_valid;
  logic_vector p_out_data;

  // Clock generation (10ns period)
  initial clk = 0;
  always #5 clk = ~clk;

  // DUT instantiation
  Core #(
    .NADDR(NADDR),
    .NBITS(NBITS),
    .LATENCY(LATENCY),
    .ROM(ROM),
    .QUANT(QUANT),
    .NADDR(NADDR),
    .FEAT_IN_SIZE(FEAT_IN_SIZE),
    .N_WINDOW(N_WINDOW),
    .N_CHANNEL_IN(N_CHANNEL_IN),
    .N_CHANNEL_OUT(N_CHANNEL_OUT),
    .LAST_WINDOW(LAST_WINDOW)
  ) dut (
    .clk(clk),
    .reset(reset),

    .p_start(p_start),
    .p_end(p_end),

    .p_in_en(p_in_en),
    .p_in_valid(p_in_valid),
    .p_in_data(p_in_data),

    .p_out_en(p_out_en),
    .p_out_valid(p_out_valid),
    .p_out_data(p_out_data)
  );

  // Inicialização dos sinais e reset
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);

    reset = 1;

    // Inicializa sinais de controle e dados
    p_in_en = 0;
    p_start = 0;
    p_in_data = '0;

    // Aguarda 1 ciclos de clock
    @(posedge clk);
    reset = 0;


    // Carregar pesos
    $display("=== Loading weights ===");
    p_in_en = 1;
    @(posedge clk);

    for (int i = 0; i < W2_SIZE; i++) begin
      p_in_data = const_weight[0][i];
      $display("Weight[%0d] = %0d", i, p_in_data);
      @(posedge clk);
    end

    p_in_en = 0;
    wait(p_end);
    @(posedge clk);

    // Carregar dados de entrada
    $display("=== Loading data ===");
    p_in_en = 1;
    @(posedge clk);

    for (int i = 0; i < FIN2_SIZE; i++) begin
      p_in_data = const_feat_in[0][i];
      $display("Input data[%0d] = %0d", i, p_in_data);
      @(posedge clk);
    end

    p_in_en = 0;
    wait(p_end);
    @(posedge clk);

    // Start processamento
    $display("=== Start processing ===");
    p_start = 1;
    @(posedge clk);
    p_start = 0;

    @(posedge clk);
    wait(p_end);

    // Monitorar saída (p_out_valid = 1) e ler dados de saída
    @(posedge clk);
    if (p_out_valid) begin
      $display("Time %0t: Output = %0d", $time, p_out_data);
    end

    $display("End simulation");
    $finish;
  end
endmodule
