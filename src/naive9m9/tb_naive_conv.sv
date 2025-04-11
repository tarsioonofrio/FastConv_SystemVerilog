// -------------------------------------------------------------------------
// FAST CONVOLUTION  TB
// -------------------------------------------------------------------------
module tb;

  timeunit 1ns;
  timeprecision 1ps;

  import packConv::*;
  import data::*;

  // logic_vector[C1_SIZE*C2_SIZE:0] weight, inputMAP;
  // logic_vector[A1_SIZE*A2_SIZE:0] outputMAP;
  type_input inputMAP;
  type_weight weight;
  type_output outputMAP;

  logic reset, start, data_valid;
  logic clk = 1'b0;


  // Instantiate conv_rapida entity
  conv_standard conv_naive (
    .clk(clk),
    .reset(reset),
    .start(start),
    .inputMAP(inputMAP),
    .weights(weight),
    .outputMAP(outputMAP),
    .data_valid(data_valid)
  );

  // Clock generation - 10 ns
  always #1 clk = ~clk;

  // Test process to iterate over the input maps
  initial begin

    // Configurações iniciais
    $dumpfile("dump.vcd");  // Arquivo VCD para waveform
    $dumpvars(0, tb);

    // Monitor para debug
    // $monitor("** Time: %0t | start: %b | data_valid: %b", $time, start, data_valid);

    //clk = 0;
    reset = 1;
    #5 reset = 0;  // Liberar o reset após 5 ns

    // Convert const_weight
    for (int wi = 0; wi < W1_SIZE; wi++) begin
      for (int wj = 0; wj < W2_SIZE; wj++) begin
        weight[wj] = (NBITS)'($signed(const_weight[wi][wj]));
      end

      // Loop de simulação
      for (int fi = 0; fi < FIN1_SIZE; fi++) begin
          for (int fj = 0; fj < FIN2_SIZE; fj++) begin
            inputMAP[fj] = (NBITS)'($signed(const_feat_in[fi][fj]));
          end

          start = 1'b1;
          #10 start = 1'b0;

          wait(data_valid);

          // $display("Time: %0t | Data Valid: %b", $time, data_valid);
          for (int fj = 0; fj < FOUT2_SIZE; fj = fj + 1) begin
            if ($signed(outputMAP[fj]) != $signed(const_feat_out[fi][fj][19:0])) begin
              $display("Time: %0t | Data Valid: %b", $time, data_valid);
              $display(
                "Values Error: outputMAP[%0d] = %d", fj, $signed(outputMAP[fj]),
                $signed(const_feat_out[fi][fj])
                );
            end
          end

          #100;  // Wait for 100 ns
      end
    end

    // Finalizar a simulação 200 ns após o loop
    #200 $finish;
  end


  final begin
    integer log_f;
    log_f = $fopen("sim_summary.txt", "w");
    $fdisplay(log_f, "time");
    $fdisplay(log_f, "%0t", $time);
    $fclose(log_f);
  end

endmodule
