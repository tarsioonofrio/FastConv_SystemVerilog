// -------------------------------------------------------------------------
// CONVOLUTION  TB
// -------------------------------------------------------------------------
module tb;
  logic DEBUG = 0;

  timeunit 1ns;
  timeprecision 1ps;

  import data::*;
  import pack_def::*;
  import pack_typedef::*;
  import pack_param::*;

 // type_weight weight;
 // type_input inputMAP;
 // type_output outputMAP;

  logic [19:0] inputMAP [0:24];
  logic [19:0] weight  [0:35];
  logic [19:0] outputMAP[0:8];

  logic reset, start, data_valid;
  logic clk = 1'b0;
  int fi;


  // Instantiate conv_rapida entity
//  conv #(
//    .QUANT(QUANT_BITS)
//  ) convolucao (
//    .clk(clk),
//    .reset(reset),
//    .start(start),
//    .inputMAP(inputMAP),
//    .weights(weight),
//    .outputMAP(outputMAP),
//    .data_valid(data_valid)
//  );

 // Instantiate the DUT below
  conv conv (
 .clk(clk),
                   .reset(reset),
                   .start(start),
                   .\inputMAP[24] (inputMAP[24]),
                   .\inputMAP[23] (inputMAP[23]),
                   .\inputMAP[22] (inputMAP[22]),
                   .\inputMAP[21] (inputMAP[21]),
                   .\inputMAP[20] (inputMAP[20]),
                   .\inputMAP[19] (inputMAP[19]),
                   .\inputMAP[18] (inputMAP[18]),
                   .\inputMAP[17] (inputMAP[17]),
                   .\inputMAP[16] (inputMAP[16]),
                   .\inputMAP[15] (inputMAP[15]),
                   .\inputMAP[14] (inputMAP[14]),
                   .\inputMAP[13] (inputMAP[13]),
                   .\inputMAP[12] (inputMAP[12]),
                   .\inputMAP[11] (inputMAP[11]),
                   .\inputMAP[10] (inputMAP[10]),
                   .\inputMAP[9]  (inputMAP[9]),
                   .\inputMAP[8]  (inputMAP[8]),
                   .\inputMAP[7]  (inputMAP[7]),
                   .\inputMAP[6]  (inputMAP[6]),
                   .\inputMAP[5]  (inputMAP[5]),
                   .\inputMAP[4]  (inputMAP[4]),
                   .\inputMAP[3]  (inputMAP[3]),
                   .\inputMAP[2]  (inputMAP[2]),
                   .\inputMAP[1]  (inputMAP[1]),
                   .\inputMAP[0]  (inputMAP[0]),
                   .\weights[35]  (weight[35]),
                   .\weights[34]  (weight[34]),
                   .\weights[33]  (weight[33]),
                   .\weights[32]  (weight[32]),
                   .\weights[31]  (weight[31]),
                   .\weights[30]  (weight[30]),
                   .\weights[29]  (weight[29]),
                   .\weights[28]  (weight[28]),
                   .\weights[27]  (weight[27]),
                   .\weights[26]  (weight[26]),
                   .\weights[25]  (weight[25]),
                   .\weights[24]  (weight[24]),
                   .\weights[23]  (weight[23]),
                   .\weights[22]  (weight[22]),
                   .\weights[21]  (weight[21]),
                   .\weights[20]  (weight[20]),
                   .\weights[19]  (weight[19]),
                   .\weights[18]  (weight[18]),
                   .\weights[17]  (weight[17]),
                   .\weights[16]  (weight[16]),
                   .\weights[15]  (weight[15]),
                   .\weights[14]  (weight[14]),
                   .\weights[13]  (weight[13]),
                   .\weights[12]  (weight[12]),
                   .\weights[11]  (weight[11]),
                   .\weights[10]  (weight[10]),
                   .\weights[9]   (weight[9]),
                   .\weights[8]   (weight[8]),
                   .\weights[7]   (weight[7]),
                   .\weights[6]   (weight[6]),
                   .\weights[5]   (weight[5]),
                   .\weights[4]   (weight[4]),
                   .\weights[3]   (weight[3]),
                   .\weights[2]   (weight[2]),
                   .\weights[1]   (weight[1]),
                   .\weights[0]   (weight[0]),
                   .\outputMAP[8] (outputMAP[8]),
                   .\outputMAP[7] (outputMAP[7]),
                   .\outputMAP[6] (outputMAP[6]),
                   .\outputMAP[5] (outputMAP[5]),
                   .\outputMAP[4] (outputMAP[4]),
                   .\outputMAP[3] (outputMAP[3]),
                   .\outputMAP[2] (outputMAP[2]),
                   .\outputMAP[1] (outputMAP[1]),
                   .\outputMAP[0] (outputMAP[0]),
                   .data_valid(data_valid)
               );


  // Clock generation - 2 ns - 500 MHz
  always #1 clk = ~clk;

  // Test process to iterate over the input maps
  initial begin

    // Configurações iniciais
    // $dumpfile("dump.vcd");  // Arquivo VCD para waveform
    // $dumpvars(0, tb);

     $shm_open("conv.shm");
     $shm_probe(tb.conv, "ASM");


    // Monitor para debug
    // $monitor("** Time: %0t | start: %b | data_valid: %b", $time, start, data_valid);


    //clk = 0;
    start = 0;
    reset = 1;
    #5
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
          #10
          start = 1'b0;
          wait(data_valid);
          #10;  // Wait for 100 ns
      end
    end
    // Finalizar a simulação 200 ns após o loop
    #10 $finish;
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


  final begin
    integer log_f;
    log_f = $fopen("sim_summary.txt", "w");
    $fdisplay(log_f, "time");
    $fdisplay(log_f, "%0t", $time);
    $fclose(log_f);
  end

endmodule
