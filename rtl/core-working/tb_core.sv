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
  logic p_end[3:0];
  logic p_debug;
  logic p_reuse;

  logic p_fin_en;
  logic p_fin_valid;

  logic p_wh_en;
  logic p_wh_valid;

  logic p_fout_en;
  logic p_fout_valid;

  logic_vector p_in_data;
  logic_vector p_out_data;

  // Clock generation (10ns period)
  initial clk = 0;
  always #5 clk = ~clk;


  const int c_index[5*5] = {
    00, 05, 10, 15, 20,
    01, 06, 11, 16, 21,
    02, 07, 12, 17, 22,
    03, 08, 13, 18, 23,
    04, 09, 14, 19, 24
  };


  // DUT instantiation
  Core #(
    .QUANT(QUANT),
    .NBITS(NBITS)
  ) dut (
    .clk(clk),
    .reset(reset),

    .p_start(p_start),
    .p_end(p_end),
    .p_reuse(p_reuse),

    .p_fin_en(p_fin_en),
    .p_fin_valid(p_fin_valid),

    .p_wh_en(p_wh_en),
    .p_wh_valid(p_wh_valid),

    .p_fout_en(p_fout_en),
    .p_fout_valid(p_fout_valid),

    .p_in_data(p_in_data),
    .p_out_data(p_out_data)
  );

  // Inicialização dos sinais e reset
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);

    reset = 1;

    // Inicializa sinais de controle e dados
    p_wh_en = 0;
    p_fin_en = 0;
    p_wh_valid = 0;
    p_fin_valid = 0;
    p_start = 0;
    p_in_data = '0;

    // Aguarda 1 ciclos de clock
    @(posedge clk);
    reset = 0;
    @(posedge clk);


    // Carregar pesos
    $display("=== Loading weights ===");
    p_wh_en = 1;
    @(posedge clk);
    p_wh_valid = 1;

    for (int i = 0; i < W2_SIZE; i++) begin
      p_in_data = const_weight[0][i];
      $display("Weight[%0d] = %0d", i, p_in_data);
      @(posedge clk);
    end

    p_wh_en = 0;
    p_wh_valid = 0;
    // wait(p_end[0]);
    @(posedge clk);

    // Carregar dados de entrada
    $display("=== Loading data ===");
    p_fin_en = 1;
    @(posedge clk);
    p_fin_valid = 1;

    for (int i = 0; i < FIN2_SIZE; i++) begin
      p_in_data = const_feat_in[0][c_index[i]];
      $display("Input data[%0d] = %0d", i, p_in_data);
      @(posedge clk);
    end

    p_fin_en = 0;
    p_fin_valid = 0;
    // wait(p_end[1]);
    @(posedge clk);

    // Start processamento
    $display("=== Start processing ===");
    p_start = 1;
    @(posedge clk);
    p_start = 0;

    @(posedge clk);
    wait(p_fout_en);

    $display("=== End processing ===");
    // Monitorar saída (p_fout_valid = 1) e ler dados de saída
    @(posedge clk);
    for (int i = 0; i < FOUT2_SIZE; i++) begin
      if (p_fout_en ) begin
        $display("Time %0t | const_feat_out[%0d] = %0d | Output = %0d", $time, i, const_feat_out[0][i], p_out_data);
      end
      @(posedge clk);
    end
    // wait(p_end[2]);

    # 10ns;
    $display("End simulation");
    $finish;
  end
endmodule
