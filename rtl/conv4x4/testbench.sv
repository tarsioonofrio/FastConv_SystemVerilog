`timescale 1ns/1ps

module tb;
  import pack_data::*;
  import pack_param::*;
  import pack_mux_mult::*;

  localparam int unsigned NBITS = 20;
  // The generated feature-map set contains one 8x8 tile grid per input
  // channel.  A result tile is accumulated over all input channels for one
  // output channel, so each input/output pair is exercised once per tile.
  localparam int unsigned TILES_PER_CHANNEL = FIN1_SIZE / N_CHANNEL_IN;
  localparam int unsigned OUTPUT_TILES_PER_AXIS =
    (FEAT_OUTPUT_SIZE + CONV_OUTPUT_SIZE - 1) / CONV_OUTPUT_SIZE;
  localparam int unsigned EXPECTED_TILES = N_CHANNEL_IN * N_CHANNEL_OUT * TILES_PER_CHANNEL;

  logic clk = 1'b0;
  logic reset = 1'b1;
  logic p_start = 1'b0;
  logic p_end;
  logic p_idle;
  logic [NBITS-1:0] p_input [CONV_INPUT_SIZE*CONV_INPUT_SIZE-1:0];
  logic [NBITS-1:0] p_weight [HADAMARD_SIZE*HADAMARD_SIZE-1:0];
  logic [NBITS-1:0] p_output [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0];
  int mismatch_count;
  int tile_count;
  int cycle_count;

  always #5 clk = ~clk;

  Conv #(
    .QUANT(QUANT_BITS),
    .NBITS(NBITS)
  ) dut (
    .clk(clk),
    .reset(reset),
    .p_start(p_start),
    .p_end(p_end),
    .p_idle(p_idle),
    .p_input(p_input),
    .p_weight(p_weight),
    .p_output(p_output)
  );

  always_ff @(posedge clk or posedge reset) begin
    if (reset)
      cycle_count <= 0;
    else begin
      cycle_count <= cycle_count + 1;
    end
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);

    mismatch_count = 0;
    tile_count = 0;
    p_start = 1'b0;
    reset = 1'b1;
    repeat (2) @(posedge clk);
    reset = 1'b0;
    @(posedge clk);

    // const_feat_in is indexed as input_channel * tile_count + tile, while
    // const_feat_out_batch is indexed as output_channel * tile_count + tile.
    // Accumulate the three input-channel partial tiles before comparing the
    // result with the generated output package.
    for (int output_channel = 0; output_channel < N_CHANNEL_OUT; output_channel++) begin
      for (int tile = 0; tile < TILES_PER_CHANNEL; tile++) begin
        int signed accumulated [CONV_OUTPUT_SIZE * CONV_OUTPUT_SIZE];
        int expected_batch;
        for (int fout = 0; fout < CONV_OUTPUT_SIZE * CONV_OUTPUT_SIZE; fout++)
          accumulated[fout] = 0;

        for (int input_channel = 0; input_channel < N_CHANNEL_IN; input_channel++) begin
          int channel;
          int batch;
          channel = output_channel * N_CHANNEL_IN + input_channel;
          batch = input_channel * TILES_PER_CHANNEL + tile;

          for (int weight = 0; weight < HADAMARD_SIZE * HADAMARD_SIZE; weight++)
            p_weight[weight] = NBITS'($signed(const_weight[channel][weight]));

          for (int fin = 0; fin < CONV_INPUT_SIZE * CONV_INPUT_SIZE; fin++)
            p_input[fin] = NBITS'($signed(const_feat_in[batch][fin]));

          p_start = 1'b1;
          @(posedge clk);
          p_start = 1'b0;
          wait (p_end);
          // p_end is asserted during INVERSE.  Do not launch the next tile
          // until the core has returned to IDLE_CONV.
          wait (p_idle);

          for (int fout = 0; fout < CONV_OUTPUT_SIZE * CONV_OUTPUT_SIZE; fout++)
            accumulated[fout] += int'($signed(p_output[fout]));

          tile_count++;
          @(posedge clk);
        end

        expected_batch = output_channel * TILES_PER_CHANNEL + tile;
        for (int fout = 0; fout < CONV_OUTPUT_SIZE * CONV_OUTPUT_SIZE; fout++) begin
          int tile_row;
          int tile_col;
          int local_row;
          int local_col;
          int global_row;
          int global_col;
          tile_row = tile / OUTPUT_TILES_PER_AXIS;
          tile_col = tile % OUTPUT_TILES_PER_AXIS;
          local_row = fout / CONV_OUTPUT_SIZE;
          local_col = fout % CONV_OUTPUT_SIZE;
          global_row = tile_row * CONV_OUTPUT_SIZE + local_row;
          global_col = tile_col * CONV_OUTPUT_SIZE + local_col;

          // The final tile row/column is padded when FEAT_OUTPUT_SIZE is not
          // a multiple of the 4x4 tile size; those lanes are outside the
          // feature map and are intentionally excluded from the comparison.
          if ((global_row < FEAT_OUTPUT_SIZE) && (global_col < FEAT_OUTPUT_SIZE) &&
              (accumulated[fout] != $signed(const_feat_out_batch[expected_batch][fout]))) begin
            mismatch_count++;
            if (mismatch_count <= 8)
              $display("VALUE_MISMATCH output_channel=%0d tile=%0d elem=%0d got=%0d expected=%0d",
                       output_channel, tile, fout, accumulated[fout],
                       $signed(const_feat_out_batch[expected_batch][fout]));
          end
        end
      end
    end

    if (tile_count != EXPECTED_TILES)
      $fatal(1, "unexpected tile count: got %0d expected %0d", tile_count, EXPECTED_TILES);
    if (mismatch_count != 0)
      $fatal(1, "TCN16 numerical mismatch count: %0d", mismatch_count);

    $display("4x4 TCN16 simulation passed: tiles=%0d cycles=%0d",
             tile_count, cycle_count);
    $finish;
  end
endmodule
