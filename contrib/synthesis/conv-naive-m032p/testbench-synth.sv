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
  logic clk;
  int fi;
  time t_start = 0;
  time t_end = 0;
  time t_total = 0;
  int cycle_count = 0;
  integer time_fd = 0;


  // Instantiate conv_rapida entity
 Conv dut (
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
  initial clk = 0;
  always #5 clk = ~clk;

  // Track cycles between reset deassert and end of run.
  always_ff @(posedge clk) begin
    if (reset) begin
      cycle_count <= 0;
    end else begin
      cycle_count <= cycle_count + 1;
    end
  end

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
    t_start = $realtime;
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
    t_end = $realtime;
    t_total = t_end - t_start;
    time_fd = $fopen("sim.log", "w");
    if (time_fd) begin
      $fdisplay(time_fd, "Total execution time: %f", t_total);
      $fdisplay(time_fd, "Total cycles: %0d", cycle_count);
      $fclose(time_fd);
    end
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
