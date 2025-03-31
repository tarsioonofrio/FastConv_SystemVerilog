// -------------------------------------------------------------------------
// FAST CONVOLUTION  TB
// -------------------------------------------------------------------------
module tb;

  timeunit 1ns;
  timeprecision 1ps;

  import packConv::*;
  import data::*;

  logic_vector16 weight, inputMAP;
  logic_vector4 outputMAP;

  logic reset, start, data_valid;
  logic clk = 1'b0;


  // Instantiate conv_rapida entity
  conv_rapida #(
    .QUANT(QUANT_BITS)
  ) convolucao (
    .clk(clk),
    .reset(reset),
    .start(start),
    .inputMAP(inputMAP),
    .weights(weight),
    .outputMAP(outputMAP),
    .data_valid(data_valid)
  );

  // Clock generation - 10 ns
  always #5 clk = ~clk;

  // Test process to iterate over the input maps
  initial begin
    integer i, j, k;

    // Configurações iniciais
    $dumpfile("dump.vcd");  // Arquivo VCD para waveform
    $dumpvars(0, tb);

    // Monitor para debug
    $monitor("Time: %0t | start: %b | data_valid: %b  j:%0d", $time, start, data_valid, j);

    //clk = 0;
    reset = 1;
    #5 reset = 0;  // Liberar o reset após 5 ns

    // Convert const_weight
    for (i = 0; i < 16; i++) begin
      assign weight[i] = (NBITS)'($signed(const_weight[0][i]));
    end

    // Loop de simulação
    for (j = 0; j < const_feature_in.size(); j++) begin
        for (k = 0; k < const_feature_in[j].size(); k++) begin
              inputMAP[k] = (NBITS)'($signed(const_feature_in[j][k]));
        end

        start = 1'b1;
        #10 start = 1'b0;

        wait(data_valid);

        // print the expected output
        $display("Time: %0t | Data Valid: %b", $time, data_valid);
        for (int k = 0; k < 4; k = k + 1) begin
          if ($signed(outputMAP[k]) != $signed(const_feature_out[j][k][19:0])) begin
            $display("OutputMAP Values Error:");
            $display("outputMAP[%0d] = %d", k, $signed(outputMAP[k]), $signed(const_feature_out[j][k]));
          end
        end

        #100;  // Wait for 100 ns
    end

    // Finalizar a simulação 200 ns após o loop
    #200 $finish;
  end


endmodule
