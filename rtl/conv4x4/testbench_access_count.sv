`timescale 1ns/1ps

// Count-only workload for the largest active 4x4 convolution variants.
// The input and output memory interfaces return random data; numerical output
// is intentionally not checked. Each case uses a 32x32 image and equal input
// and output channel counts from 32 through 512.
module tb_conv4x4_access_count #(
  parameter int unsigned NUM_MULT = 32,
  parameter int unsigned NBITS = 16,
  parameter int unsigned HADAMARD_SIZE = 8
);
  logic clk = 1'b0;
  logic done_ch32, done_ch64, done_ch128, done_ch256, done_ch512;

  always #1 clk = ~clk;

  access_count_case #(
    .IMAGE_SIZE(32), .NUM_MULT(NUM_MULT), .NBITS(NBITS),
    .HADAMARD_SIZE(HADAMARD_SIZE), .N_CHANNEL_IN(32), .N_CHANNEL_OUT(32)
  ) case_ch32 (.clk(clk), .done(done_ch32));

  access_count_case #(
    .IMAGE_SIZE(32), .NUM_MULT(NUM_MULT), .NBITS(NBITS),
    .HADAMARD_SIZE(HADAMARD_SIZE), .N_CHANNEL_IN(64), .N_CHANNEL_OUT(64)
  ) case_ch64 (.clk(clk), .done(done_ch64));

  access_count_case #(
    .IMAGE_SIZE(32), .NUM_MULT(NUM_MULT), .NBITS(NBITS),
    .HADAMARD_SIZE(HADAMARD_SIZE), .N_CHANNEL_IN(128), .N_CHANNEL_OUT(128)
  ) case_ch128 (.clk(clk), .done(done_ch128));

  access_count_case #(
    .IMAGE_SIZE(32), .NUM_MULT(NUM_MULT), .NBITS(NBITS),
    .HADAMARD_SIZE(HADAMARD_SIZE), .N_CHANNEL_IN(256), .N_CHANNEL_OUT(256)
  ) case_ch256 (.clk(clk), .done(done_ch256));

  access_count_case #(
    .IMAGE_SIZE(32), .NUM_MULT(NUM_MULT), .NBITS(NBITS),
    .HADAMARD_SIZE(HADAMARD_SIZE), .N_CHANNEL_IN(512), .N_CHANNEL_OUT(512)
  ) case_ch512 (.clk(clk), .done(done_ch512));

  initial begin: CAMPAIGN_FINISH_BLOCK
    wait (done_ch32 && done_ch64 && done_ch128 && done_ch256 && done_ch512);
    $display("ACCESS_COUNT_CAMPAIGN_PASS variant_m=%0d nbits=%0d hadamard=%0d image=32 channels=32,64,128,256,512",
             NUM_MULT, NBITS, HADAMARD_SIZE);
    $finish;
  end

  initial begin: CAMPAIGN_TIMEOUT_BLOCK
    #2s;
    $fatal(1, "access-count campaign timed out");
  end
endmodule


module access_count_case #(
  parameter int unsigned IMAGE_SIZE = 32,
  parameter int unsigned NUM_MULT = 32,
  parameter int unsigned NBITS = 16,
  parameter int unsigned HADAMARD_SIZE = 8,
  parameter int unsigned N_CHANNEL_IN = 3,
  parameter int unsigned N_CHANNEL_OUT = 12,
  parameter int unsigned CONV_INPUT_SIZE = 6,
  parameter int unsigned CONV_OUTPUT_SIZE = 4,
  parameter int unsigned CONV_KERNEL_SIZE = 3
) (
  input logic clk,
  output logic done
);
  localparam int unsigned FEAT_WORDS = N_CHANNEL_IN * IMAGE_SIZE * IMAGE_SIZE;
  // Reserve the largest possible transformed-weight area plus raw kernel
  // weights. This keeps all generated RTL addresses representable.
  localparam int unsigned MAX_INPUT_WORDS = FEAT_WORDS +
      N_CHANNEL_IN * N_CHANNEL_OUT * HADAMARD_SIZE * HADAMARD_SIZE +
      N_CHANNEL_IN * N_CHANNEL_OUT * CONV_KERNEL_SIZE * CONV_KERNEL_SIZE;
  localparam int unsigned FEAT_OUTPUT_SIZE = IMAGE_SIZE - CONV_KERNEL_SIZE + 1;
  localparam int unsigned OUTPUT_TILES_PER_AXIS =
      (FEAT_OUTPUT_SIZE + CONV_OUTPUT_SIZE - 1) / CONV_OUTPUT_SIZE;
  localparam int unsigned OUTPUT_PHYSICAL_SIZE =
      OUTPUT_TILES_PER_AXIS * CONV_OUTPUT_SIZE;
  localparam int unsigned OUTPUT_WORDS =
      N_CHANNEL_OUT * OUTPUT_PHYSICAL_SIZE * OUTPUT_PHYSICAL_SIZE;
  localparam int unsigned ADDRESS_WORDS =
      (MAX_INPUT_WORDS > OUTPUT_WORDS) ? MAX_INPUT_WORDS : OUTPUT_WORDS;
  localparam int unsigned NADDR = $clog2(ADDRESS_WORDS);
  localparam int unsigned INPUT_BEAT_WIDTH = CONV_INPUT_SIZE * NBITS;
  localparam int unsigned OUTPUT_BEAT_WIDTH = CONV_OUTPUT_SIZE * NBITS;

  logic reset;
  logic p_start;
  logic p_end;
  logic p_input_en;
  logic [NADDR-1:0] p_input_addr;
  logic [INPUT_BEAT_WIDTH-1:0] p_input_data;
  logic p_input_valid;
  logic p_output_en;
  logic p_output_wr;
  logic [NADDR-1:0] p_output_addr;
  logic [OUTPUT_BEAT_WIDTH-1:0] p_output_data_write;
  logic [OUTPUT_BEAT_WIDTH-1:0] p_output_data_read;
  logic p_output_valid;

  logic [31:0] input_prng;
  logic [31:0] output_prng;
  logic job_active;
  longint unsigned cycle_count;
  longint unsigned feature_read_beats;
  longint unsigned weight_read_beats;
  longint unsigned output_read_beats;
  longint unsigned output_write_beats;
  realtime job_start_time;
  realtime job_end_time;

  function automatic logic [31:0] f_xorshift32(input logic [31:0] value);
    logic [31:0] next_value;
    begin
      next_value = value;
      next_value = next_value ^ (next_value << 13);
      next_value = next_value ^ (next_value >> 17);
      next_value = next_value ^ (next_value << 5);
      f_xorshift32 = next_value;
    end
  endfunction

  assign p_input_valid = p_input_en;
  assign p_output_valid = p_output_en;

  Conv #(
    .N_CHANNEL_IN(N_CHANNEL_IN),
    .N_CHANNEL_OUT(N_CHANNEL_OUT),
    .FEAT_INPUT_SIZE(IMAGE_SIZE),
    .FEAT_INPUT_WIDTH(IMAGE_SIZE),
    .NADDR(NADDR),
    .NBITS(NBITS),
    .QUANT(8),
    .CONV_OUTPUT_SIZE(CONV_OUTPUT_SIZE),
    .CONV_KERNEL_SIZE(CONV_KERNEL_SIZE),
    .CONV_INPUT_SIZE(CONV_INPUT_SIZE),
    .HADAMARD_SIZE(HADAMARD_SIZE),
    .NUM_MULT(NUM_MULT)
  ) dut (
    .clk(clk),
    .reset(reset),
    .p_start(p_start),
    .p_end(p_end),
    .p_input_en(p_input_en),
    .p_input_addr(p_input_addr),
    .p_input_data(p_input_data),
    .p_input_valid(p_input_valid),
    .p_output_en(p_output_en),
    .p_output_wr(p_output_wr),
    .p_output_addr(p_output_addr),
    .p_output_data_write(p_output_data_write),
    .p_output_data_read(p_output_data_read),
    .p_output_valid(p_output_valid)
  );

  // Stimulus changes on the falling edge so it is stable at the DUT's
  // sampling edge. The values are deliberately random and are not checked.
  always @(negedge clk or posedge reset) begin: RANDOM_MEMORY_DATA_BLOCK
    if (reset) begin
      input_prng <= 32'h9e3779b9 ^ IMAGE_SIZE ^ N_CHANNEL_IN;
      output_prng <= 32'h7f4a7c15 ^ IMAGE_SIZE ^ N_CHANNEL_OUT;
      p_input_data <= '0;
      p_output_data_read <= '0;
    end else begin
      if (p_input_en) begin
        for (int unsigned lane = 0; lane < CONV_INPUT_SIZE; lane++) begin
          input_prng = f_xorshift32(input_prng);
          p_input_data[lane*NBITS +: NBITS] <= NBITS'(input_prng);
        end
      end
      if (p_output_en && !p_output_wr) begin
        for (int unsigned lane = 0; lane < CONV_OUTPUT_SIZE; lane++) begin
          output_prng = f_xorshift32(output_prng);
          p_output_data_read[lane*NBITS +: NBITS] <= NBITS'(output_prng);
        end
      end
    end
  end

  // Count accepted memory beats during the p_start-to-p_end interval.
  always @(posedge clk) begin: ACCESS_COUNTER_BLOCK
    if (reset) begin
      done = 1'b0;
      job_active = 1'b0;
      cycle_count = 0;
      feature_read_beats = 0;
      weight_read_beats = 0;
      output_read_beats = 0;
      output_write_beats = 0;
      job_start_time = 0.0;
      job_end_time = 0.0;
    end else if (p_start && !job_active) begin
      job_active = 1'b1;
      job_start_time = $realtime;
    end else if (job_active) begin
      cycle_count = cycle_count + 1;
      if (p_input_en && p_input_valid) begin
        if (dut.w_input_read_weights)
          weight_read_beats = weight_read_beats + 1;
        else
          feature_read_beats = feature_read_beats + 1;
      end
      if (p_output_en && p_output_valid) begin
        if (p_output_wr)
          output_write_beats = output_write_beats + 1;
        else
          output_read_beats = output_read_beats + 1;
      end
      if (p_end) begin
        job_end_time = $realtime;
        $display("ACCESS_COUNT image=%0d cin=%0d cout=%0d m=%0d nbits=%0d h=%0d cycles=%0d time_us=%0.3f feature_read_beats=%0d weight_read_beats=%0d input_read_beats=%0d output_read_beats=%0d output_write_beats=%0d",
                 IMAGE_SIZE, N_CHANNEL_IN, N_CHANNEL_OUT, NUM_MULT, NBITS,
                 HADAMARD_SIZE, cycle_count,
                 (job_end_time - job_start_time) / 1000.0,
                 feature_read_beats, weight_read_beats,
                 feature_read_beats + weight_read_beats,
                 output_read_beats, output_write_beats);
        job_active = 1'b0;
        done = 1'b1;
      end
    end
  end

  initial begin: START_JOB_BLOCK
    reset = 1'b1;
    p_start = 1'b0;
    repeat (3) @(negedge clk);
    reset = 1'b0;
    repeat (8) @(negedge clk);
    p_start = 1'b1;
    @(negedge clk);
    p_start = 1'b0;
  end
endmodule
