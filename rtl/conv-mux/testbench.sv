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
  int cycle_count = 0;
  logic count_cycles = 0;
  integer time_fd = 0;

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

  // Track cycles between p_start and p_end.
  always_ff @(posedge clk) begin
    if (reset) begin
      cycle_count <= 0;
      count_cycles <= 0;
    end else begin
      if (p_start) begin
        cycle_count <= 0;
        count_cycles <= 1;
      end else if (count_cycles) begin
        cycle_count <= cycle_count + 1;
        if (p_end) begin
          count_cycles <= 0;
        end
      end
    end
  end

  // Test process to iterate over the input maps
  initial begin
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
          for (int fout = 0; fout < FOUT2_SIZE; fout++) begin
            // To avoid error:
            // %Warning-WIDTHEXPAND: ../../testbench/tb_conv.sv:79:36: Operator NEQ expects 32 bits on the LHS, but LHS's SIGNED generates 20 bits.
            /* verilator lint_off WIDTHEXPAND */
            if ($signed(p_output[fout]) != $signed(const_feat_out_batch[batch][fout])) begin
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


  always @(posedge clk) begin
    if (p_end) begin
      // #1; // espera propagação de sinal
      // for (int fj = 0; fj < FOUT2_SIZE; fj++) begin
      //   // To avoid error:
      //   // %Warning-WIDTHEXPAND: ../../testbench/tb_conv.sv:79:36: Operator NEQ expects 32 bits on the LHS, but LHS's SIGNED generates 20 bits.
      //   /* verilator lint_off WIDTHEXPAND */
      //   if ($signed(p_output[fj]) != $signed(const_feat_out_batch[batch_out][fj])) begin
      //     /* verilator lint_off WIDTHEXPAND */
      //     // $display("Time: %0t | Data Valid: %b", $time, p_end);
      //     $display(
      //       "Values Error: Time %0t | Data Valid: %b | const_feat_out[%0d][%0d] = %d != %d",
      //       $time, p_end,
      //       batch_out, fj, $signed(const_feat_out_batch[batch_out][fj]), $signed(p_output[fj])
      //     );
      //   end
      //   batch_out++;
      //   if (DEBUG == 1) begin
      //     /* verilator lint_off WIDTHEXPAND */
      //     // $display("Time: %0t | Data Valid: %b", $time, p_end);
      //     $display(
      //       "Values: Time %0t | Data Valid: %b | const_feat_out[%0d][%0d]  %d | p_output = %d",
      //       $time, p_end,
      //       batch_out, fj, $signed(const_feat_out_batch[batch_out][fj]), $signed(p_output[fj])
      //     );
      //   end
      // end
    end
  end

endmodule
