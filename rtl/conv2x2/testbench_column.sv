`timescale 1ns/1ps

module tb_column;
  import pack_data::*;
  import pack_param::*;

  localparam int unsigned NBITS = 20;
  localparam int unsigned FEAT_INPUT_WIDTH = FEAT_INPUT_SIZE;
  localparam int unsigned LATENCY = 1;
  localparam int unsigned INPUT_MEMORY_SIZE = $size(const_data);
  localparam int unsigned OUTPUT_MEMORY_SIZE = FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE * N_CHANNEL_OUT;
  localparam int unsigned INPUT_ADDR_WIDTH = $clog2(INPUT_MEMORY_SIZE);
  localparam int unsigned OUTPUT_ADDR_WIDTH = $clog2(OUTPUT_MEMORY_SIZE);
  localparam int unsigned NADDR = (INPUT_ADDR_WIDTH > OUTPUT_ADDR_WIDTH) ? INPUT_ADDR_WIDTH : OUTPUT_ADDR_WIDTH;
  localparam int unsigned INPUT_TILES_PER_AXIS =
      (FEAT_OUTPUT_SIZE + CONV_OUTPUT_SIZE - 1) / CONV_OUTPUT_SIZE;
  localparam int unsigned EXPECTED_INVERSE_COUNT =
      N_CHANNEL_IN * N_CHANNEL_OUT * INPUT_TILES_PER_AXIS * INPUT_TILES_PER_AXIS;
  localparam int unsigned EXPECTED_WEIGHT_READ_BEATS =
      N_CHANNEL_IN * N_CHANNEL_OUT * (HADAMARD_SIZE * HADAMARD_SIZE / CONV_INPUT_SIZE);

  logic clk = 1'b0;
  logic reset;
  logic p_start;
  logic p_end;
  logic p_input_en;
  logic [NADDR-1:0] p_input_addr;
  logic [CONV_INPUT_SIZE*NBITS-1:0] p_input_data;
  logic p_input_valid;
  logic p_output_en;
  logic p_output_wr;
  logic [NADDR-1:0] p_output_addr;
  logic [CONV_OUTPUT_SIZE*NBITS-1:0] p_output_data_write;
  logic [CONV_OUTPUT_SIZE*NBITS-1:0] p_output_data_read;
  logic p_output_valid;

  logic [NADDR-1:0] column_input_addr [0:CONV_INPUT_SIZE-1];
  logic [NBITS-1:0] column_input_word [0:CONV_INPUT_SIZE-1];
  logic [CONV_INPUT_SIZE-1:0] column_input_valid;
  logic input_column_in_bounds;
  logic [NBITS-1:0] output_bank [0:OUTPUT_MEMORY_SIZE-1];

  int inverse_tile_count;
  int output_error_count;
  int output_out_of_range_count;
  int input_out_of_range_count;
  int valid_output_word_count;
  int weight_read_beat_count;
  int useful_weight_read_beat_count;
  int cycle_count;
  logic conv_end_d;

  function automatic int expected_output_value(input int unsigned address);
    expected_output_value = const_feat_out[address];
  endfunction

  always #5 clk = ~clk;

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

  always_comb begin: COLUMN_INPUT_ADDRESS_BLOCK
    for (int unsigned lane = 0; lane < CONV_INPUT_SIZE; lane++) begin
      // Both feature and weight reads use adjacent memory words per beat.
      column_input_addr[lane] = p_input_addr + NADDR'(lane);
    end
  end

  for (genvar lane = 0; lane < CONV_INPUT_SIZE; lane++) begin: COLUMN_INPUT_MEMORY_LANE
    Memory #(
      .NADDR(NADDR),
      .NBITS(NBITS),
      .LATENCY(LATENCY),
      .ROM(1)
    ) memory_input_lane (
      .clk(clk),
      .reset(reset),
      .chip_en(p_input_en),
      .wr_en(1'b0),
      .address(column_input_addr[lane]),
      .data_in('0),
      .data_out(column_input_word[lane]),
      .data_valid(column_input_valid[lane])
    );

    always_comb begin
      p_input_data[lane*NBITS +: NBITS] =
          (column_input_addr[lane] < INPUT_MEMORY_SIZE) ? column_input_word[lane] : '0;
    end
  end
  assign p_input_valid = column_input_valid[0];

  always_comb begin: COLUMN_INPUT_BOUNDS_CHECK_BLOCK
    int unsigned local_base;
    input_column_in_bounds = 1'b1;
    local_base = int'(p_input_addr) % (FEAT_INPUT_SIZE * FEAT_INPUT_WIDTH);
    if (dut.st_input_current != 4'd2) begin // READ_WEIGHTS
      for (int unsigned lane = 0; lane < CONV_INPUT_SIZE; lane++) begin
        if ((column_input_addr[lane] >= INPUT_MEMORY_SIZE) ||
            ((local_base % FEAT_INPUT_WIDTH) + lane >= FEAT_INPUT_WIDTH) ||
            ((local_base / FEAT_INPUT_WIDTH) >= FEAT_INPUT_SIZE))
          input_column_in_bounds = 1'b0;
      end
    end
  end

  always_comb begin: COLUMN_OUTPUT_READ_BLOCK
    for (int unsigned lane = 0; lane < CONV_OUTPUT_SIZE; lane++) begin
      int unsigned lane_addr;
      lane_addr = p_output_addr + lane*FEAT_OUTPUT_SIZE;
      if (lane_addr < OUTPUT_MEMORY_SIZE)
        p_output_data_read[lane*NBITS +: NBITS] = output_bank[lane_addr];
      else
        p_output_data_read[lane*NBITS +: NBITS] = '0;
    end
  end
  assign p_output_valid = p_output_en;

  always_ff @(posedge clk or posedge reset) begin: WORKLOAD_CHECK_BLOCK
    if (reset) begin
      inverse_tile_count <= 0;
      output_error_count <= 0;
      output_out_of_range_count <= 0;
      input_out_of_range_count <= 0;
      valid_output_word_count <= 0;
      weight_read_beat_count <= 0;
      useful_weight_read_beat_count <= 0;
      cycle_count <= 0;
      conv_end_d <= 1'b0;
      output_bank <= '{default: '0};
    end else begin
      cycle_count <= cycle_count + 1;
      if (dut.st_input_current == 4'd2) begin // READ_WEIGHTS
        weight_read_beat_count <= weight_read_beat_count + 1;
        if (!dut.w_input_last_channel_output)
          useful_weight_read_beat_count <= useful_weight_read_beat_count + 1;
      end
      conv_end_d <= dut.w_conv_end;
      if (dut.w_conv_end && !conv_end_d)
        inverse_tile_count <= inverse_tile_count + 1;

      if (p_input_en && !input_column_in_bounds)
        input_out_of_range_count <= input_out_of_range_count + 1;

      if (p_output_en && p_output_wr) begin
        logic beat_has_error;
        beat_has_error = 1'b0;
        for (int unsigned lane = 0; lane < CONV_OUTPUT_SIZE; lane++) begin
          int unsigned lane_addr;
          lane_addr = p_output_addr + lane*FEAT_OUTPUT_SIZE;
          if (lane_addr < OUTPUT_MEMORY_SIZE) begin
            output_bank[lane_addr] <= p_output_data_write[lane*NBITS +: NBITS];
            valid_output_word_count <= valid_output_word_count + CONV_OUTPUT_SIZE;
            if ((dut.r_output_channel_counter_input == (N_CHANNEL_IN - 1)) &&
                ($signed(p_output_data_write[lane*NBITS +: NBITS]) !=
                 $signed(expected_output_value(lane_addr)))) begin
              beat_has_error = 1'b1;
              if (output_error_count < 8)
                $display("ERROR COLUMN WRITE GOLDEN: time=%0t lane=%0d addr=%0d got=%0d expected=%0d",
                         $realtime, lane, lane_addr,
                         $signed(p_output_data_write[lane*NBITS +: NBITS]),
                         expected_output_value(lane_addr));
            end
          end else begin
            output_out_of_range_count <= output_out_of_range_count + 1;
          end
        end
        if (beat_has_error)
          output_error_count <= output_error_count + 1;
      end
    end
  end

  initial begin: TEST_SEQUENCE_BLOCK
    reset = 1'b1;
    p_start = 1'b0;
    #20 reset = 1'b0;
    #80 p_start = 1'b1;
    #10 p_start = 1'b0;

    if (p_end !== 1'b1)
      @(posedge p_end);
    #200;

    if (output_error_count != 0)
      $fatal(1, "output golden mismatch count: %0d", output_error_count);
    if (inverse_tile_count != EXPECTED_INVERSE_COUNT)
      $fatal(1, "unexpected inverse count: got %0d expected %0d",
             inverse_tile_count, EXPECTED_INVERSE_COUNT);
    if (valid_output_word_count != N_CHANNEL_IN * N_CHANNEL_OUT * FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE)
      $fatal(1, "unexpected valid write count: got %0d", valid_output_word_count);
    if (useful_weight_read_beat_count != EXPECTED_WEIGHT_READ_BEATS)
      $fatal(1, "unexpected useful weight read beat count: got %0d expected %0d",
             useful_weight_read_beat_count, EXPECTED_WEIGHT_READ_BEATS);
    if (weight_read_beat_count != (EXPECTED_WEIGHT_READ_BEATS + 1))
      $fatal(1, "unexpected total weight read beat count: got %0d expected %0d",
             weight_read_beat_count, EXPECTED_WEIGHT_READ_BEATS + 1);
    if (input_out_of_range_count != 0 || output_out_of_range_count != 0)
      $fatal(1, "out-of-range accesses: input=%0d output=%0d",
             input_out_of_range_count, output_out_of_range_count);

    $display("std-column simulation passed: inverse_tiles=%0d cycles=%0d weight_read_beats=%0d useful_weight_beats=%0d valid_writes=%0d input_oob=%0d output_oob=%0d",
             inverse_tile_count, cycle_count, weight_read_beat_count, useful_weight_read_beat_count,
             valid_output_word_count, input_out_of_range_count, output_out_of_range_count);
    $finish;
  end
endmodule
