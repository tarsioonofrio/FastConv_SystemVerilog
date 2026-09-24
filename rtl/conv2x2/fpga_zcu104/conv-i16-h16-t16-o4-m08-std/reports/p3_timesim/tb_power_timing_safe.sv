`timescale 1ns/1ps

// Diagnostic testbench: sample asynchronous memory models on the falling edge
// and hold their outputs stable across the DUT's rising-edge capture.
module tb_power #(
  parameter int unsigned JOBS = 1
);
  import pack_data::*;
  import pack_param::*;

  localparam int unsigned NBITS = 20;
  localparam int unsigned NADDR = 16;
  localparam int unsigned FEAT_INPUT_WIDTH = FEAT_INPUT_SIZE;
  localparam int unsigned LATENCY = 1;
  localparam int unsigned ROM = 1;
  localparam int unsigned OUTPUT_MEMORY_SIZE = FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE * N_CHANNEL_OUT;
  localparam int unsigned EXPECTED_WRITES = N_CHANNEL_IN * OUTPUT_MEMORY_SIZE;
  localparam realtime CLK_PERIOD_NS = 3.154574;

  logic clk = 1'b0;
  logic reset = 1'b1;
  logic p_start = 1'b0;
  logic p_end;
  logic p_input_en;
  logic [NADDR-1:0] p_input_addr;
  logic [NBITS-1:0] p_input_data;
  logic [NBITS-1:0] p_input_data_raw;
  logic p_input_valid;
  logic p_input_valid_raw;
  logic p_output_en;
  logic p_output_wr;
  logic [NADDR-1:0] p_output_addr;
  logic [NBITS-1:0] p_output_data_write;
  logic [NBITS-1:0] p_output_data_read;
  logic [NBITS-1:0] p_output_data_read_raw;
  logic p_output_valid;
  logic p_output_valid_raw;
  logic [1:0] input_base_feat;
  logic input_sample_in_bounds;
  integer valid_write_count = 0;
  integer golden_error_count = 0;
  integer cycle_count = 0;
  integer tile_end_count = 0;
  logic tile_end_d = 1'b0;

  always #(CLK_PERIOD_NS / 2.0) clk = ~clk;

`ifdef GATE_LEVEL
  always_comb begin
    case (dut.st_input_current)
      4'd3: input_base_feat = 2'd0;
      4'd4: input_base_feat = 2'd1;
      4'd5: input_base_feat = 2'd2;
      4'd6: input_base_feat = 2'd3;
      default: input_base_feat = 2'd0;
    endcase
  end
`else
  assign input_base_feat = dut.w_input_base_feat;
`endif

  assign input_sample_in_bounds = (CONV_OUTPUT_SIZE == 4) ?
      (((dut.r_input_addr_feat % FEAT_INPUT_WIDTH) + dut.r_input_addr_count < FEAT_INPUT_WIDTH) &&
       ((dut.r_input_addr_feat / FEAT_INPUT_WIDTH) + input_base_feat < FEAT_INPUT_SIZE)) : 1'b1;

  // Hold all external memory response signals from negedge through posedge.
  always @(negedge clk) begin
    p_input_data = input_sample_in_bounds ? p_input_data_raw : '0;
    p_input_valid = p_input_valid_raw;
    p_output_data_read = p_output_data_read_raw;
    p_output_valid = p_output_valid_raw;
  end

`ifdef GATE_LEVEL
  Conv dut (
`else
  Conv #(
    .N_CHANNEL_IN(N_CHANNEL_IN),
    .N_CHANNEL_OUT(N_CHANNEL_OUT),
    .FEAT_INPUT_SIZE(FEAT_INPUT_SIZE),
    .FEAT_INPUT_WIDTH(FEAT_INPUT_SIZE),
    .NADDR(NADDR),
    .NBITS(NBITS),
    .QUANT(QUANT_BITS),
    .CONV_OUTPUT_SIZE(CONV_OUTPUT_SIZE),
    .CONV_INPUT_SIZE(CONV_INPUT_SIZE),
    .HADAMARD_SIZE(HADAMARD_SIZE),
    .NUM_MULT(8)
  ) dut (
`endif
    .clk(clk), .reset(reset), .p_start(p_start), .p_end(p_end),
    .p_input_en(p_input_en), .p_input_addr(p_input_addr),
    .p_input_data(p_input_data), .p_input_valid(p_input_valid),
    .p_output_en(p_output_en), .p_output_wr(p_output_wr),
    .p_output_addr(p_output_addr), .p_output_data_write(p_output_data_write),
    .p_output_data_read(p_output_data_read), .p_output_valid(p_output_valid)
  );

  Memory #(.NADDR(NADDR), .NBITS(NBITS), .LATENCY(LATENCY), .ROM(ROM)) memory_input (
    .clk(clk), .reset(reset), .chip_en(p_input_en), .wr_en(1'b0),
    .address(p_input_addr), .data_in('0), .data_out(p_input_data_raw),
    .data_valid(p_input_valid_raw)
  );

  Memory #(.NADDR(NADDR), .NBITS(NBITS), .LATENCY(LATENCY), .ROM(0)) memory_output (
    .clk(clk), .reset(reset), .chip_en(p_output_en), .wr_en(p_output_wr),
    .address(p_output_addr), .data_in(p_output_data_write),
    .data_out(p_output_data_read_raw), .data_valid(p_output_valid_raw)
  );

  always @(posedge clk) begin
    if (reset) begin
      valid_write_count <= 0;
      golden_error_count <= 0;
      cycle_count <= 0;
      tile_end_count <= 0;
      tile_end_d <= 1'b0;
    end else begin
      cycle_count <= cycle_count + 1;
      tile_end_d <= dut.w_conv_end;
      if (dut.w_conv_end && !tile_end_d)
        tile_end_count <= tile_end_count + 1;
      if (p_output_en && p_output_wr) begin
        valid_write_count <= valid_write_count + 1;
        if (p_output_addr < OUTPUT_MEMORY_SIZE &&
            dut.r_output_channel_counter_input == (N_CHANNEL_IN - 1) &&
            $signed(p_output_data_write) != $signed(const_feat_out[p_output_addr])) begin
          golden_error_count <= golden_error_count + 1;
          if (golden_error_count < 8)
            $display("P3_TIMING_SAFE_MISMATCH addr=%0d got=%0d expected=%0d", p_output_addr,
                     $signed(p_output_data_write), $signed(const_feat_out[p_output_addr]));
        end
      end
    end
  end

  task automatic launch_job;
    begin
      repeat (8) @(negedge clk);
      p_start = 1'b1;
      @(negedge clk);
      p_start = 1'b0;
      @(posedge p_end);
      @(negedge clk);
    end
  endtask

  initial begin
`ifdef GATE_LEVEL
    // Wait beyond the FPGA's 100 ns global startup reset, then release reset
    // synchronously at a falling edge to avoid another interface race.
    repeat (70) @(negedge clk);
`else
    repeat (4) @(negedge clk);
`endif
    reset = 1'b0;
    for (int job = 0; job < JOBS; job++) begin
      launch_job();
      repeat (2) @(negedge clk);
    end
    $display("P3_TIMING_SAFE_RESULT cycles=%0d writes=%0d expected_writes=%0d tiles=%0d golden_errors=%0d",
             cycle_count, valid_write_count, EXPECTED_WRITES, tile_end_count, golden_error_count);
    if (valid_write_count != EXPECTED_WRITES || golden_error_count != 0)
      $fatal(1, "timing-safe gate-level workload failed output validation");
    $finish;
  end
endmodule
