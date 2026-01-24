// -------------------------------------------------------------------------
// CONVOLUTION  TB
// -------------------------------------------------------------------------
module tb;
  logic DEBUG = 0;

  timeunit 1ns;
  timeprecision 1ps;

  import packConv::*;
  import data::*;

  type_weight weight;
  type_input inputMAP;
  type_output outputMAP;

  // logic [19:0] inputMAP [0:24];
  // logic [19:0] weight  [0:35];
  // logic [19:0] outputMAP[0:8];

  logic reset, start, data_valid;
  logic clk = 1'b0;
  int fi;


  // Instantiate conv_rapida entity
 conv #(
   .QUANT(QUANT_BITS)
 ) dut (
   .clk(clk),
   .reset(reset),
   .start(start),
   .inputMAP(inputMAP),
   .weights(weight),
   .outputMAP(outputMAP),
   .data_valid(data_valid)
 );


  // Clock generation - 2 ns - 500 MHz
  initial clk = 0;
  always #5 clk = ~clk;

  // Test process to iterate over the input maps
  initial begin

    // Configurações iniciais
    // $dumpfile("dump.vcd");  // Arquivo VCD para waveform
    // $dumpvars(0, tb);

     $shm_open("dut.shm");
     $shm_probe(tb.dut, "ASM");


    // Monitor para debug
    // $monitor("** Time: %0t | start: %b | data_valid: %b", $time, start, data_valid);


    //clk = 0;
    start = 0;
    reset = 1;
    @(posedge clk);
    reset = 0;  // Liberar o reset após 5 ns

    // Convert const_weight
    for (int wi = 0; wi < W1_SIZE; wi++) begin
      for (int wj = 0; wj < W2_SIZE; wj++) begin
        weight[wj] = (NBITS)'($signed(const_weight[wi][wj]));
      end

      // Loop de simulação
      for (fi = 0; fi < FIN1_SIZE; fi++) begin
          for (int fj = 0; fj < FIN2_SIZE; fj++) begin
            inputMAP[fj] = (NBITS)'($signed(const_feat_in[fi][fj]));
          end

          start = 1'b1;
          @(posedge clk);
          start = 1'b0;
          wait(data_valid);
          @(posedge clk);
          @(posedge clk);
      end
    end
    // Finalizar a simulação 200 ns após o loop
    @(posedge clk);
    $display("=== No errors - End simulation ===");
    $display("\n*** TIME %f ***\n", $realtime);

    $finish;
  end


  always @(posedge clk) begin
    if (data_valid) begin
      // #1; // espera propagação de sinal
      for (int fj = 0; fj < FOUT2_SIZE; fj++) begin
        // To avoid error:
        // %Warning-WIDTHEXPAND: ../../testbench/tb_conv.sv:79:36: Operator NEQ expects 32 bits on the LHS, but LHS's SIGNED generates 20 bits.
        /* verilator lint_off WIDTHEXPAND */
        if ($signed(outputMAP[fj]) != $signed(const_feat_out[fi][fj])) begin
          /* verilator lint_off WIDTHEXPAND */
          // $display("Time: %0t | Data Valid: %b", $time, data_valid);
          $display(
            "Values Error: Time %0t | Data Valid: %b | const_feat_out[%0d][%0d] = %d != %d",
            $time, data_valid,
            fi, fj, $signed(const_feat_out[fi][fj]), $signed(outputMAP[fj])
          );
        end
        if (DEBUG == 1) begin
          /* verilator lint_off WIDTHEXPAND */
          // $display("Time: %0t | Data Valid: %b", $time, data_valid);
          $display(
            "Values: Time %0t | Data Valid: %b | const_feat_out[%0d][%0d]  %d | outputMAP = %d",
            $time, data_valid,
            fi, fj, $signed(const_feat_out[fi][fj]), $signed(outputMAP[fj])
          );
        end

      end
    end
  end

endmodule
