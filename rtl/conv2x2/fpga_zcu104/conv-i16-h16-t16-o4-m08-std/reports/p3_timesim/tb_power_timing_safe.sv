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
  integer trace_capture_count = 0;
  integer trace_output_count = 0;
  integer trace_final_write_count = 0;
  logic trace_sample_pending = 1'b0;
  logic [NADDR-1:0] trace_addr_at_drive = '0;
  logic [NBITS-1:0] trace_data_at_drive = '0;
  logic [NBITS-1:0] trace_raw_at_drive = '0;
  logic [NBITS-1:0] trace_expected_at_drive = '0;
  logic trace_valid_at_drive = 1'b0;
  realtime trace_drive_time = 0.0;

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

`ifdef P3_TRACE_COMB_MEMORY
  // Reproduce the original zero-delay asynchronous memory response for the
  // short address/data diagnostic; do not register responses on negedge.
  assign p_input_data = input_sample_in_bounds ? p_input_data_raw : '0;
  assign p_input_valid = p_input_valid_raw;
  assign p_output_data_read = p_output_data_read_raw;
  assign p_output_valid = p_output_valid_raw;
`endif

  always @(negedge clk) begin
`ifndef P3_TRACE_COMB_MEMORY
    // Hold external memory responses from negedge through the next posedge.
    p_input_data = input_sample_in_bounds ? p_input_data_raw : '0;
    p_input_valid = p_input_valid_raw;
    p_output_data_read = p_output_data_read_raw;
    p_output_valid = p_output_valid_raw;
`endif
`ifdef P3_TRACE_FIRST50
    if (!reset && p_input_en && trace_capture_count < 50) begin
      trace_sample_pending = 1'b1;
      trace_addr_at_drive = p_input_addr;
      trace_data_at_drive = p_input_data;
      trace_raw_at_drive = p_input_data_raw;
      trace_expected_at_drive = (input_sample_in_bounds && (p_input_addr < $size(const_data))) ?
                                NBITS'(const_data[p_input_addr]) : '0;
      trace_valid_at_drive = p_input_valid;
      trace_drive_time = $realtime;
    end
`endif
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
`ifdef P3_TRACE_FIRST50
      if (trace_sample_pending) begin
        $display("P3_INPUT_TRACE n=%0d drive_ns=%0.0f capture_ns=%0.0f addr_negedge=%0d addr_posedge=%0d en_posedge=%b data_negedge=%0d data_posedge=%0d raw_negedge=%0d raw_posedge=%0d expected_negedge=%0d expected_posedge=%0d valid_negedge=%b valid_posedge=%b state=%0d addr_feat=%0d addr_count=%0d",
                 trace_capture_count, trace_drive_time, $realtime, trace_addr_at_drive,
                 p_input_addr, p_input_en, $signed(trace_data_at_drive),
                 $signed(p_input_data), $signed(trace_raw_at_drive),
                 $signed(p_input_data_raw), $signed(trace_expected_at_drive),
                 $signed(input_sample_in_bounds ?
                   ((p_input_addr < $size(const_data)) ? NBITS'(const_data[p_input_addr]) : '0) : '0),
                 trace_valid_at_drive, p_input_valid, dut.st_input_current,
                 dut.r_input_addr_feat, dut.r_input_addr_count);
        trace_capture_count = trace_capture_count + 1;
        trace_sample_pending = 1'b0;
        if (trace_capture_count == 50) begin
          $display("P3_INPUT_TRACE_END captures=%0d cycles=%0d", trace_capture_count, cycle_count);
          $finish;
        end
      end
`endif
      if (dut.w_conv_end && !tile_end_d)
        tile_end_count <= tile_end_count + 1;
`ifdef P3_TRACE_FIRST_OUTPUT
      if (p_output_en && p_output_addr < OUTPUT_MEMORY_SIZE) begin
        if (trace_output_count < 50)
          $display("P3_OUTPUT_TRACE n=%0d time_ns=%0.0f en=%b wr=%b addr=%0d data_write=%0d data_read=%0d ram_before=%0d valid=%b input_channel=%0d golden=%0d",
                   trace_output_count, $realtime, p_output_en, p_output_wr,
                   p_output_addr, $signed(p_output_data_write),
                   $signed(p_output_data_read),
                   $signed(memory_output.data[p_output_addr]), p_output_valid,
                   dut.r_output_channel_counter_input,
                   $signed(const_feat_out[p_output_addr]));
        trace_output_count = trace_output_count + 1;
        if (p_output_wr &&
            dut.r_output_channel_counter_input == (N_CHANNEL_IN - 1)) begin
          trace_final_write_count = trace_final_write_count + 1;
          if (trace_final_write_count == 10) begin
            $display("P3_OUTPUT_TRACE_END events=%0d final_writes=%0d cycles=%0d",
                     trace_output_count, trace_final_write_count, cycle_count);
            $finish;
          end
        end
      end
`endif
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
