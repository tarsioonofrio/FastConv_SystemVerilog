`timescale 1ns/1ps

module tb_fpga_wrapper;
  import pack_data::*;
  import pack_param::*;

  localparam int unsigned OUTPUT_WORDS = FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE * N_CHANNEL_OUT;
  localparam int unsigned EXPECTED_WRITES = N_CHANNEL_IN * OUTPUT_WORDS;
  localparam int unsigned OUTPUT_TILES_PER_AXIS = (FEAT_OUTPUT_SIZE + CONV_OUTPUT_SIZE - 1) / CONV_OUTPUT_SIZE;
  localparam int unsigned EXPECTED_TILES = N_CHANNEL_IN * N_CHANNEL_OUT * OUTPUT_TILES_PER_AXIS * OUTPUT_TILES_PER_AXIS;
  localparam realtime CLK_PERIOD_NS = 3.154574;

  logic clk = 1'b0;
  logic reset = 1'b1;
  logic start = 1'b0;
  logic done;
  integer cycles;
  integer launch_cycle;
  integer latency_cycles;
  integer write_count;
  integer golden_errors;
  integer out_of_range_writes;
  integer tile_count;
  logic tile_end_d;

  always #(CLK_PERIOD_NS / 2.0) clk = ~clk;

  fpga_benchmark_top dut (
    .clk(clk),
    .reset(reset),
    .start(start),
    .done(done)
  );

  always_ff @(posedge clk) begin
    if (reset) begin
      cycles <= 0;
      launch_cycle <= 0;
      latency_cycles <= 0;
      write_count <= 0;
      golden_errors <= 0;
      out_of_range_writes <= 0;
      tile_count <= 0;
      tile_end_d <= 1'b0;
    end else begin
      cycles <= cycles + 1;
      if (start)
        launch_cycle <= cycles;
      if (done)
        latency_cycles <= cycles - launch_cycle;
      tile_end_d <= dut.accelerator_core.w_conv_end;
      if (dut.accelerator_core.w_conv_end && !tile_end_d)
        tile_count <= tile_count + 1;

      if (dut.core_output_en && dut.core_output_wr) begin
        write_count <= write_count + 1;
        if (dut.core_output_addr >= OUTPUT_WORDS)
          out_of_range_writes <= out_of_range_writes + 1;
        if (dut.accelerator_core.r_output_channel_counter_input == (N_CHANNEL_IN - 1) &&
            dut.core_output_addr < OUTPUT_WORDS &&
            $signed(dut.core_output_data_write) != $signed(const_feat_out[dut.core_output_addr])) begin
          golden_errors <= golden_errors + 1;
          if (golden_errors < 8)
            $display("WRAPPER_GOLDEN_MISMATCH addr=%0d got=%0d expected=%0d",
                     dut.core_output_addr, $signed(dut.core_output_data_write),
                     $signed(const_feat_out[dut.core_output_addr]));
        end
      end
    end
  end

  initial begin
    repeat (70) @(negedge clk); // Allow FPGA GSR startup to finish before reset release.
    reset = 1'b0;
    repeat (2) @(negedge clk);
    start = 1'b1;
    @(negedge clk);
    start = 1'b0;

    fork
      begin
        @(posedge done);
        repeat (2) @(negedge clk);
      end
      begin
        repeat (100000) @(posedge clk);
        $fatal(1, "wrapper watchdog expired before done");
      end
    join_any
    disable fork;

    #1ps;
    if (done !== 1'b1 && latency_cycles == 0)
      $fatal(1, "done was not observed");
    if (write_count != EXPECTED_WRITES)
      $fatal(1, "wrong write count: got %0d expected %0d", write_count, EXPECTED_WRITES);
    if (tile_count != EXPECTED_TILES)
      $fatal(1, "wrong tile count: got %0d expected %0d", tile_count, EXPECTED_TILES);
    if (golden_errors != 0)
      $fatal(1, "golden mismatch count: %0d", golden_errors);
    if (out_of_range_writes != 0)
      $fatal(1, "out-of-range write count: %0d", out_of_range_writes);

    $display("FPGA_WRAPPER_RESULT latency_cycles=%0d writes=%0d tiles=%0d golden_errors=%0d out_of_range=%0d",
             latency_cycles, write_count, tile_count, golden_errors, out_of_range_writes);
    $finish;
  end
endmodule
