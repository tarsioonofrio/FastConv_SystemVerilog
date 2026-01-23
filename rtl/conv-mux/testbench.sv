// -------------------------------------------------------------------------
// CONVOLUTION  TB
// -------------------------------------------------------------------------
module tb;
  logic DEBUG = 0;

  timeunit 1ns;
  timeprecision 1ps;

  import pack_def::*;
  import pack_data::*;
  import pack_param::*;
  import pack_typedef::*;

  type_weight p_weight;
  type_input p_input;
  type_output p_output;

  logic clk, reset, p_start, p_end, p_idle;
  int fi;


  // Instantiate conv_rapida entity
  Conv #(
    .QUANT(QUANT),
    .NBITS(NBITS)
  ) dut (
    .clk(clk),
    .reset(reset),
    .p_start(p_start),
    .p_idle(p_idle),
    .p_end(p_end),
    .p_input(p_input),
    .p_weight(p_weight),
    .p_output(p_output)
  );

  // Clock generation - 10 ns
  initial clk = 0;
  always #5 clk = ~clk;

  // Test process to iterate over the input maps
  initial begin
    p_start = 0;
    reset = 1;
    @(posedge clk);
    reset = 0;  // Liberar o reset após 5 ns
    @(posedge clk);

    // Convert const_weight
    for (int wi = 0; wi < M1_SIZE; wi++) begin
      for (int wj = 0; wj < M2_SIZE; wj++) begin
        p_weight[wj] = (NBITS)'($signed(const_weight[wi][wj]));
      end
      @(posedge clk);
      // Loop de simulação
      for (fi = 0; fi < FIN1_SIZE; fi++) begin
          for (int fj = 0; fj < FIN2_SIZE; fj++) begin
            p_input[fj] = (NBITS)'($signed(const_feat_in[fi][fj]));
          end

          p_start = 1'b1;
          @(posedge clk);
          p_start = 1'b0;
          wait(p_end);
          @(posedge clk);
      end
    end
    $display("=== No errors - End simulation ===");
    $display("\n*** TIME %f ***\n", $realtime);
    // $finish;
    // Finalizar a simulação 200 ns após o loop
    @(posedge clk);
    $finish;
  end


  // always @(posedge clk) begin
  //   if (p_end) begin
  //     // #1; // espera propagação de sinal
  //     for (int fj = 0; fj < FOUT2_SIZE; fj++) begin
  //       // To avoid error:
  //       // %Warning-WIDTHEXPAND: ../../testbench/tb_conv.sv:79:36: Operator NEQ expects 32 bits on the LHS, but LHS's SIGNED generates 20 bits.
  //       /* verilator lint_off WIDTHEXPAND */
  //       if ($signed(p_output[fj]) != $signed(const_feat_out[fi][fj])) begin
  //         /* verilator lint_off WIDTHEXPAND */
  //         // $display("Time: %0t | Data Valid: %b", $time, p_end);
  //         $display(
  //           "Values Error: Time %0t | Data Valid: %b | const_feat_out[%0d][%0d] = %d != %d",
  //           $time, p_end,
  //           fi, fj, $signed(const_feat_out[fi][fj]), $signed(p_output[fj])
  //         );
  //       end
  //       if (DEBUG == 1) begin
  //         /* verilator lint_off WIDTHEXPAND */
  //         // $display("Time: %0t | Data Valid: %b", $time, p_end);
  //         $display(
  //           "Values: Time %0t | Data Valid: %b | const_feat_out[%0d][%0d]  %d | p_output = %d",
  //           $time, p_end,
  //           fi, fj, $signed(const_feat_out[fi][fj]), $signed(p_output[fj])
  //         );
  //       end
  //     end
  //   end
  // end

endmodule
