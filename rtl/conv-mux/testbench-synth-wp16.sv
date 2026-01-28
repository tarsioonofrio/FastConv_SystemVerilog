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
  import pack_mux_mult::*;

  type_weight p_weight;
  type_input p_input;
  type_output p_output;

  logic clk, reset, p_start, p_end, p_idle;
  int batch_out = 0;
  time t_start = 0;
  time t_end = 0;
  time t_total = 0;
  integer time_fd = 0;
  int cycle_count;

  // Instantiate conv_rapida entity
  Conv dut (
    .clk(clk),
    .reset(reset),
    .p_start(p_start),
    .p_idle(p_idle),
    .p_end(p_end),
// `ifdef GATE_LEVEL
    .\p_input[35] (p_input[35]),
    .\p_input[34] (p_input[34]),
    .\p_input[33] (p_input[33]),
    .\p_input[32] (p_input[32]),
    .\p_input[31] (p_input[31]),
    .\p_input[30] (p_input[30]),
    .\p_input[29] (p_input[29]),
    .\p_input[28] (p_input[28]),
    .\p_input[27] (p_input[27]),
    .\p_input[26] (p_input[26]),
    .\p_input[25] (p_input[25]),
    .\p_input[24] (p_input[24]),
    .\p_input[23] (p_input[23]),
    .\p_input[22] (p_input[22]),
    .\p_input[21] (p_input[21]),
    .\p_input[20] (p_input[20]),
    .\p_input[19] (p_input[19]),
    .\p_input[18] (p_input[18]),
    .\p_input[17] (p_input[17]),
    .\p_input[16] (p_input[16]),
    .\p_input[15] (p_input[15]),
    .\p_input[14] (p_input[14]),
    .\p_input[13] (p_input[13]),
    .\p_input[12] (p_input[12]),
    .\p_input[11] (p_input[11]),
    .\p_input[10] (p_input[10]),
    .\p_input[9]  (p_input[9]),
    .\p_input[8]  (p_input[8]),
    .\p_input[7]  (p_input[7]),
    .\p_input[6]  (p_input[6]),
    .\p_input[5]  (p_input[5]),
    .\p_input[4]  (p_input[4]),
    .\p_input[3]  (p_input[3]),
    .\p_input[2]  (p_input[2]),
    .\p_input[1]  (p_input[1]),
    .\p_input[0]  (p_input[0]),
    .\p_weight[63] (p_weight[63]),
    .\p_weight[62] (p_weight[62]),
    .\p_weight[61] (p_weight[61]),
    .\p_weight[60] (p_weight[60]),
    .\p_weight[59] (p_weight[59]),
    .\p_weight[58] (p_weight[58]),
    .\p_weight[57] (p_weight[57]),
    .\p_weight[56] (p_weight[56]),
    .\p_weight[55] (p_weight[55]),
    .\p_weight[54] (p_weight[54]),
    .\p_weight[53] (p_weight[53]),
    .\p_weight[52] (p_weight[52]),
    .\p_weight[51] (p_weight[51]),
    .\p_weight[50] (p_weight[50])
    .\p_weight[49] (p_weight[49]),
    .\p_weight[48] (p_weight[48]),
    .\p_weight[47] (p_weight[47]),
    .\p_weight[46] (p_weight[46]),
    .\p_weight[45] (p_weight[45]),
    .\p_weight[44] (p_weight[44]),
    .\p_weight[43] (p_weight[43]),
    .\p_weight[42] (p_weight[42]),
    .\p_weight[41] (p_weight[41]),
    .\p_weight[40] (p_weight[40]),
    .\p_weight[39] (p_weight[39]),
    .\p_weight[38] (p_weight[38]),
    .\p_weight[37] (p_weight[37]),
    .\p_weight[36] (p_weight[36]),
    .\p_weight[35] (p_weight[35]),
    .\p_weight[34] (p_weight[34]),
    .\p_weight[33] (p_weight[33]),
    .\p_weight[32] (p_weight[32]),
    .\p_weight[31] (p_weight[31]),
    .\p_weight[30] (p_weight[30]),
    .\p_weight[29] (p_weight[29]),
    .\p_weight[28] (p_weight[28]),
    .\p_weight[27] (p_weight[27]),
    .\p_weight[26] (p_weight[26]),
    .\p_weight[25] (p_weight[25]),
    .\p_weight[24] (p_weight[24]),
    .\p_weight[23] (p_weight[23]),
    .\p_weight[22] (p_weight[22]),
    .\p_weight[21] (p_weight[21]),
    .\p_weight[20] (p_weight[20]),
    .\p_weight[19] (p_weight[19]),
    .\p_weight[18] (p_weight[18]),
    .\p_weight[17] (p_weight[17]),
    .\p_weight[16] (p_weight[16]),
    .\p_weight[15] (p_weight[15]),
    .\p_weight[14] (p_weight[14]),
    .\p_weight[13] (p_weight[13]),
    .\p_weight[12] (p_weight[12]),
    .\p_weight[11] (p_weight[11]),
    .\p_weight[10] (p_weight[10]),
    .\p_weight[9]  (p_weight[9]),
    .\p_weight[8]  (p_weight[8]),
    .\p_weight[7]  (p_weight[7]),
    .\p_weight[6]  (p_weight[6]),
    .\p_weight[5]  (p_weight[5]),
    .\p_weight[4]  (p_weight[4]),
    .\p_weight[3]  (p_weight[3]),
    .\p_weight[2]  (p_weight[2]),
    .\p_weight[1]  (p_weight[1]),
    .\p_weight[0]  (p_weight[0]),
    .\p_output[15] (p_output[15]),
    .\p_output[14] (p_output[14]),
    .\p_output[13] (p_output[13]),
    .\p_output[12] (p_output[12]),
    .\p_output[11] (p_output[11]),
    .\p_output[10] (p_output[10]),
    .\p_output[9]  (p_output[9]),
    .\p_output[8] (p_output[8]),
    .\p_output[7] (p_output[7]),
    .\p_output[6] (p_output[6]),
    .\p_output[5] (p_output[5]),
    .\p_output[4] (p_output[4]),
    .\p_output[3] (p_output[3]),
    .\p_output[2] (p_output[2]),
    .\p_output[1] (p_output[1]),
    .\p_output[0] (p_output[0])
// `else
    // .p_input(p_input),
    // .p_weight(p_weight),
    // .p_output(p_output)
// `endif
  );

  // Clock generation - 10 ns
  initial clk = 0;
  always #5 clk = ~clk;

  // Track cycles between p_start and p_end.
  always_ff @(posedge clk) begin
    if (reset) begin
      cycle_count <= 0;
    end else begin
      cycle_count <= cycle_count + 1;
    end
  end

  // Test process to iterate over the input maps
  initial begin
    $shm_open("dut.shm");
    $shm_probe(tb.dut, "ASM");

    p_start = 0;
    reset = 1;
    @(posedge clk);
    reset = 0;  // Liberar o reset após 5 ns
    @(posedge clk);
    t_start = $realtime;

    // Convert const_weight
    for (int channel = 0; channel < N_CHANNEL_IN * N_CHANNEL_OUT; channel++) begin
      for (int weight = 0; weight < NMULT * SMULT; weight++) begin
        p_weight[weight] = (NBITS)'($signed(const_weight[channel][weight]));
      end
      @(posedge clk);
      // Loop de simulação
      for (int batch = 0; batch < FIN1_SIZE; batch++) begin
          for (int fin = 0; fin < FIN2_SIZE; fin++) begin
            p_input[fin] = (NBITS)'($signed(const_feat_in[batch][fin]));
          end
          p_start = 1'b1;
          @(posedge clk);
          p_start = 1'b0;
          wait(p_end);
          // Wait for the core to return idle so outputs are stable with SDF delays.
          wait(p_idle);
          @(posedge clk);
          for (int fout = 0; fout < FOUT2_SIZE; fout++) begin
            // To avoid error:
            // %Warning-WIDTHEXPAND: ../../testbench/tb_conv.sv:79:36: Operator NEQ expects 32 bits on the LHS, but LHS's SIGNED generates 20 bits.
            /* verilator lint_off WIDTHEXPAND */
            logic signed [NBITS-1:0] expected_output;
            expected_output = logic_vector'(const_feat_out_batch[batch][fout]);
            if ($signed(p_output[fout]) != expected_output) begin
              /* verilator lint_off WIDTHEXPAND */
              // $display("Time: %0t | Data Valid: %b", $time, p_end);
              $display(
                "Values Error: Time %0t | Data Valid: %b | const_feat_out[%0d][%0d] | p_output | %d != %d",
                $time, p_end,
                batch, fout, $signed(const_feat_out_batch[batch][fout]), $signed(p_output[fout])
              );
            end
            batch_out++;
            if (DEBUG == 1) begin
              /* verilator lint_off WIDTHEXPAND */
              // $display("Time: %0t | Data Valid: %b", $time, p_end);
              $display(
                "Values Error: Time %0t | Data Valid: %b | const_feat_out[%0d][%0d] | p_output | %d != %d",
                $time, p_end,
                batch, fout, $signed(const_feat_out_batch[batch][fout]), $signed(p_output[fout])
              );
            end
          end
          @(posedge clk);
      end
    end

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
    // $finish;
    // Finalizar a simulação 200 ns após o loop
    $finish;
  end

endmodule
