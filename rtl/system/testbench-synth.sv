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

    wait(p_end);
    $display("=== End simulation ===");
    $finish;
  end
endmodule
