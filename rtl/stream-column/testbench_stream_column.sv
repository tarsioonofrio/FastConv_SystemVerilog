`timescale 1ns/1ps

// Column-interface testbench for the streaming truncated-column Conv variants
// (any tile size).  The input memory transfers one column of CONV_INPUT_SIZE
// words per beat; the output memory transfers one column of CONV_OUTPUT_SIZE
// words per beat.  The output memory is a physical grid of whole windows (its
// row stride is OUTPUT_PHYSICAL_SIZE); only its FEAT_OUTPUT_SIZE corner is the
// logical result, and out-of-range window samples are clipped.
module tb_stream_column #(
`ifdef ASIC_TCN16_M12
  parameter int unsigned NUM_MULT = 12
`elsif ASIC_TCN16_M18
  parameter int unsigned NUM_MULT = 18
`else
  parameter int unsigned NUM_MULT = pack_param::HADAMARD_SIZE
`endif
);
  import pack_data::*;
  import pack_param::*;

  localparam int unsigned NBITS = pack_data::NBITS;
  localparam int unsigned FEAT_INPUT_WIDTH = FEAT_INPUT_SIZE;
  localparam int unsigned LATENCY = 1;
  localparam int unsigned INPUT_MEMORY_SIZE = $size(const_data);
  localparam int unsigned OUTPUT_TILES_PER_AXIS =
      (FEAT_OUTPUT_SIZE + CONV_OUTPUT_SIZE - 1) / CONV_OUTPUT_SIZE;
  localparam int unsigned OUTPUT_PHYSICAL_SIZE = OUTPUT_TILES_PER_AXIS * CONV_OUTPUT_SIZE;
  localparam int unsigned OUTPUT_CHANNEL_WORDS = OUTPUT_PHYSICAL_SIZE * OUTPUT_PHYSICAL_SIZE;
  localparam int unsigned OUTPUT_MEMORY_SIZE = OUTPUT_CHANNEL_WORDS * N_CHANNEL_OUT;
  localparam int unsigned FEAT_MAP_WORDS = FEAT_INPUT_SIZE * FEAT_INPUT_WIDTH;
  localparam int unsigned RAW_WEIGHT_WORDS_PER_BEAT = CONV_KERNEL_SIZE;
  localparam int unsigned EXPECTED_USEFUL_WEIGHT_BEATS =
      N_CHANNEL_IN * N_CHANNEL_OUT * CONV_KERNEL_SIZE * CONV_KERNEL_SIZE /
      RAW_WEIGHT_WORDS_PER_BEAT;
  localparam int unsigned INPUT_ADDR_WIDTH = $clog2(INPUT_MEMORY_SIZE);
  localparam int unsigned OUTPUT_ADDR_WIDTH = $clog2(OUTPUT_MEMORY_SIZE);
  // The mapped ASIC core keeps its default fixed address width; RTL runs use
  // the minimum width required by this workload.
`ifdef GATE_LEVEL
  localparam int unsigned NADDR = 16;
`else
  localparam int unsigned NADDR = (INPUT_ADDR_WIDTH > OUTPUT_ADDR_WIDTH) ? INPUT_ADDR_WIDTH : OUTPUT_ADDR_WIDTH;
`endif
  localparam int unsigned RAW_WEIGHT_BASE = N_CHANNEL_IN * FEAT_MAP_WORDS +
                                            N_CHANNEL_IN * N_CHANNEL_OUT * HADAMARD_SIZE * HADAMARD_SIZE;
  localparam int unsigned EXPECTED_INVERSE_COUNT =
      N_CHANNEL_IN * N_CHANNEL_OUT * OUTPUT_TILES_PER_AXIS * OUTPUT_TILES_PER_AXIS;

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
  logic [CONV_INPUT_SIZE-1:0] column_input_in_bounds;
  logic [NBITS-1:0] output_bank [0:OUTPUT_MEMORY_SIZE-1];

  int inverse_tile_count;
  int terminal_inverse_event_count;
  int output_error_count;
  int output_clipped_word_count;
  int input_clipped_beat_count;
  int valid_output_word_count;
  int weight_read_beat_count;
  int useful_weight_read_beat_count;
  int cycle_count;
  int end_cycle;  // cycle at which p_end first rises (active job length)
  logic conv_end_d;

  // The golden output is the FEAT_OUTPUT_SIZE x FEAT_OUTPUT_SIZE logical map.
  function automatic int expected_output_value(input int unsigned channel,
                                               input int unsigned row,
                                               input int unsigned col);
    expected_output_value = const_feat_out[
        channel * FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE + row * FEAT_OUTPUT_SIZE + col];
  endfunction

  always #5 clk = ~clk;

`ifdef ASIC_CAPTURE_SHM
  // Optional Joules activity capture for ASIC gate-level campaigns. Keep this
  // disabled for normal RTL and FPGA SAIF simulations.
  initial begin: ASIC_SHM_CAPTURE_BLOCK
    $shm_open("dut.shm");
    $shm_probe(tb_stream_column.dut, "ASM");
  end
`endif

`ifdef GATE_LEVEL
  // The mapped gate-level netlist has fixed parameters, so elaboration must
  // instantiate it without RTL parameter overrides.
  Conv
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
    .NUM_MULT(NUM_MULT)
`ifdef WPN16_PIPE_WEIGHT_TRANSFORM
    , .PIPE_WEIGHT_TRANSFORM(1'b1)
`endif
`ifdef WPN16_PIPE_DSP_MULTIPLIER
    , .PIPE_DSP_MULTIPLIER(1'b1)
`endif
`ifdef WPN16_PIPE_INVERSE_ACCUMULATE
    , .PIPE_INVERSE_ACCUMULATE(1'b1)
`endif
  )
`endif
  dut (
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

  // Every lane reads the word at address + lane, so a beat returns CONV_INPUT_SIZE
  // consecutive words (one image row segment, or one raw-weight kernel row).
  always_comb begin: COLUMN_INPUT_ADDRESS_BLOCK
    for (int unsigned lane = 0; lane < CONV_INPUT_SIZE; lane++)
      column_input_addr[lane] = p_input_addr + NADDR'(lane);
  end

  // Feature reads that fall outside the current channel's image (right edge,
  // bottom edge, or the next channel's data) return zero: the padding of the
  // partial last window.  Weight reads are never clipped.
  always_comb begin: COLUMN_INPUT_BOUNDS_BLOCK
    int unsigned channel;
    int unsigned local_offset;
    channel = int'(p_input_addr) / FEAT_MAP_WORDS;
    local_offset = int'(p_input_addr) % FEAT_MAP_WORDS;
    for (int unsigned lane = 0; lane < CONV_INPUT_SIZE; lane++) begin
      column_input_in_bounds[lane] = 1'b1;
`ifdef GATE_LEVEL
      if (int'(p_input_addr) < RAW_WEIGHT_BASE) begin
        if (((int'(column_input_addr[lane]) / FEAT_MAP_WORDS) != channel) ||
            ((local_offset % FEAT_INPUT_WIDTH) + lane >= FEAT_INPUT_WIDTH))
          column_input_in_bounds[lane] = 1'b0;
      end
`else
      if (!dut.w_input_read_weights) begin
        if ((channel != int'(dut.r_input_channel_counter_input)) ||
            ((local_offset % FEAT_INPUT_WIDTH) + lane >= FEAT_INPUT_WIDTH))
          column_input_in_bounds[lane] = 1'b0;
      end
`endif
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
          (column_input_in_bounds[lane] && (column_input_addr[lane] < INPUT_MEMORY_SIZE))
              ? column_input_word[lane] : '0;
    end
  end
  assign p_input_valid = column_input_valid[0];

  // Output beat: lane l is the word at address + l*OUTPUT_PHYSICAL_SIZE.
  always_comb begin: COLUMN_OUTPUT_READ_BLOCK
    for (int unsigned lane = 0; lane < CONV_OUTPUT_SIZE; lane++) begin
      int unsigned lane_addr;
      lane_addr = p_output_addr + lane * OUTPUT_PHYSICAL_SIZE;
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
      terminal_inverse_event_count <= 0;
      output_error_count <= 0;
      output_clipped_word_count <= 0;
      input_clipped_beat_count <= 0;
      valid_output_word_count <= 0;
      weight_read_beat_count <= 0;
      useful_weight_read_beat_count <= 0;
      cycle_count <= 0;
      end_cycle <= 0;
      conv_end_d <= 1'b0;
      output_bank <= '{default: '0};
    end else begin
      cycle_count <= cycle_count + 1;
      if (p_end && end_cycle == 0)
        end_cycle <= cycle_count;
`ifndef GATE_LEVEL
      conv_end_d <= dut.w_conv_end;
      if (dut.w_conv_end && !conv_end_d) begin
        if (dut.r_input_channel_counter_output < N_CHANNEL_OUT)
          inverse_tile_count <= inverse_tile_count + 1;
        else
          terminal_inverse_event_count <= terminal_inverse_event_count + 1;
      end
`endif

`ifdef GATE_LEVEL
      if (p_input_en && p_input_valid && (int'(p_input_addr) >= RAW_WEIGHT_BASE)) begin
        weight_read_beat_count <= weight_read_beat_count + 1;
        useful_weight_read_beat_count <= useful_weight_read_beat_count + 1;
      end
`else
      if (dut.w_input_read_weights && p_input_valid) begin
        weight_read_beat_count <= weight_read_beat_count + 1;
        if (dut.r_input_channel_counter_output < N_CHANNEL_OUT)
          useful_weight_read_beat_count <= useful_weight_read_beat_count + 1;
      end
`endif

      // Count clipped beats only through completion; lanes crossing a feature
      // row/channel boundary are padded as part of the real workload.
      if (p_input_en && (column_input_in_bounds != '1) && (end_cycle == 0))
        input_clipped_beat_count <= input_clipped_beat_count + 1;

      if (p_output_en && p_output_wr) begin
        logic beat_has_error;
        int unsigned beat_valid_words;
        int unsigned beat_clipped_words;
        beat_has_error = 1'b0;
        beat_valid_words = 0;
        beat_clipped_words = 0;
        for (int unsigned lane = 0; lane < CONV_OUTPUT_SIZE; lane++) begin
          int unsigned lane_addr;
          int unsigned channel;
          int unsigned row;
          int unsigned col;
          lane_addr = p_output_addr + lane * OUTPUT_PHYSICAL_SIZE;
          channel = lane_addr / OUTPUT_CHANNEL_WORDS;
          row = (lane_addr % OUTPUT_CHANNEL_WORDS) / OUTPUT_PHYSICAL_SIZE;
          col = (lane_addr % OUTPUT_CHANNEL_WORDS) % OUTPUT_PHYSICAL_SIZE;
          if ((lane_addr < OUTPUT_MEMORY_SIZE) && (row < FEAT_OUTPUT_SIZE) && (col < FEAT_OUTPUT_SIZE)) begin
            output_bank[lane_addr] <= p_output_data_write[lane*NBITS +: NBITS];
            beat_valid_words = beat_valid_words + 1;
`ifndef GATE_LEVEL
            if ((dut.r_output_channel_counter_input == (N_CHANNEL_IN - 1)) &&
                ($signed(p_output_data_write[lane*NBITS +: NBITS]) !=
                 $signed(expected_output_value(channel, row, col)))) begin
              beat_has_error = 1'b1;
              if (output_error_count < 8)
                $display("ERROR COLUMN WRITE GOLDEN: time=%0t ch=%0d row=%0d col=%0d got=%0d expected=%0d",
                         $realtime, channel, row, col,
                         $signed(p_output_data_write[lane*NBITS +: NBITS]),
                         expected_output_value(channel, row, col));
            end
`endif
          end else begin
            beat_clipped_words = beat_clipped_words + 1;
          end
        end
        valid_output_word_count <= valid_output_word_count + beat_valid_words;
        output_clipped_word_count <= output_clipped_word_count + beat_clipped_words;
        if (beat_has_error)
          output_error_count <= output_error_count + 1;
      end
    end
  end

`ifdef ASIC_DIAG_TRACE
  // Optional transaction trace for comparing RTL and mapped gate simulations.
  // It is inactive in normal synthesis, simulation, and power runs.
  int diag_input_beats;
  int diag_output_beats;
  initial begin
    diag_input_beats = 0;
    diag_output_beats = 0;
  end
  always @(posedge clk) begin: ASIC_DIAG_TRACE_BLOCK
    if (!reset && p_input_en && p_input_valid && diag_input_beats < 48) begin
      $display("ASIC_DIAG_INPUT cycle=%0d addr=%0d data=%h valid=%0b",
               cycle_count, p_input_addr, p_input_data, p_input_valid);
      diag_input_beats <= diag_input_beats + 1;
    end
    if (!reset && p_output_en && p_output_wr && diag_output_beats < 48) begin
      $display("ASIC_DIAG_OUTPUT cycle=%0d addr=%0d data=%h",
               cycle_count, p_output_addr, p_output_data_write);
      diag_output_beats <= diag_output_beats + 1;
    end
  end
`endif

  initial begin: TEST_SEQUENCE_BLOCK
`ifdef ASIC_GATE_RESET_PULSE
    // Start low, then assert reset with an explicit edge so mapped standard-cell
    // asynchronous-reset models see a deterministic event at time zero.
    reset = 1'b0;
    #1 reset = 1'b1;
    #19 reset = 1'b0;
`else
    reset = 1'b1;
    #20 reset = 1'b0;
`endif
    p_start = 1'b0;
    #80 p_start = 1'b1;
    #10 p_start = 1'b0;

    if (p_end !== 1'b1)
      @(posedge p_end);
    // Let the final write handshake drain, then require the three controllers
    // to be idle without launching an unused terminal tile or issuing another
    // memory request.
    repeat (3) @(posedge clk);

`ifdef GATE_LEVEL
    begin: FINAL_GATE_OUTPUT_GOLDEN_CHECK
      int unsigned gate_mismatch_count;
      gate_mismatch_count = 0;
      for (int unsigned channel = 0; channel < N_CHANNEL_OUT; channel++) begin
        for (int unsigned row = 0; row < FEAT_OUTPUT_SIZE; row++) begin
          for (int unsigned col = 0; col < FEAT_OUTPUT_SIZE; col++) begin
            int unsigned addr;
            addr = channel * OUTPUT_CHANNEL_WORDS + row * OUTPUT_PHYSICAL_SIZE + col;
            if ($signed(output_bank[addr]) != $signed(expected_output_value(channel, row, col))) begin
              gate_mismatch_count++;
              if (gate_mismatch_count <= 8)
                $display("ERROR GATE GOLDEN: ch=%0d row=%0d col=%0d got=%0d expected=%0d",
                         channel, row, col, $signed(output_bank[addr]),
                         $signed(expected_output_value(channel, row, col)));
            end
          end
        end
      end
      if (gate_mismatch_count != 0)
        $fatal(1, "gate-level output golden mismatch count: %0d", gate_mismatch_count);
    end
`else
    if (output_error_count != 0)
      $fatal(1, "output golden mismatch count: %0d", output_error_count);
`endif
    if (valid_output_word_count != N_CHANNEL_IN * N_CHANNEL_OUT * FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE)
      $fatal(1, "unexpected valid write count: got %0d", valid_output_word_count);
`ifndef GATE_LEVEL
    if (inverse_tile_count != EXPECTED_INVERSE_COUNT)
      $fatal(1, "unexpected inverse count: got %0d expected %0d",
             inverse_tile_count, EXPECTED_INVERSE_COUNT);
    if (terminal_inverse_event_count != 0)
      $fatal(1, "unexpected terminal inverse event count: got %0d expected 0",
             terminal_inverse_event_count);
    if (dut.st_input_current.name() != "WAIT_INPUT" ||
        dut.st_conv_current.name() != "WAIT_CONV" ||
        dut.st_output_current.name() != "WAIT_OUTPUT")
      $fatal(1, "controller did not return idle: input=%s conv=%s output=%s",
             dut.st_input_current.name(), dut.st_conv_current.name(), dut.st_output_current.name());
`endif
    if (p_input_en || p_output_en || p_output_wr)
      $fatal(1, "memory request or write remains active after job completion");
    if (useful_weight_read_beat_count != EXPECTED_USEFUL_WEIGHT_BEATS)
      $fatal(1, "unexpected useful weight read beats: got %0d expected %0d",
             useful_weight_read_beat_count, EXPECTED_USEFUL_WEIGHT_BEATS);

    $display("stream-column simulation passed: tile=%0dx%0d hadamard=%0d out=%0d inverse_tiles=%0d terminal_inverse_events=%0d cycles_to_end=%0d cycles=%0d weight_read_beats=%0d useful_weight_beats=%0d valid_writes=%0d input_clipped_beats=%0d output_clipped_words=%0d",
             CONV_INPUT_SIZE, CONV_INPUT_SIZE, HADAMARD_SIZE, CONV_OUTPUT_SIZE,
             inverse_tile_count, terminal_inverse_event_count, end_cycle, cycle_count, weight_read_beat_count,
             useful_weight_read_beat_count, valid_output_word_count,
             input_clipped_beat_count, output_clipped_word_count);
    $finish;
  end

  initial begin: WATCHDOG_BLOCK
    #2000000;
`ifdef GATE_LEVEL
    $fatal(1, "stream-column gate-level timeout: input_addr=%0d input_valid=%0b output_en=%0b output_wr=%0b",
           p_input_addr, p_input_valid, p_output_en, p_output_wr);
`else
    $fatal(1, "stream-column timeout: input_state=%s input_next=%s conv_state=%s conv_next=%s output_state=%s output_next=%s input_addr=%0d input_valid=%0b prefetch_active=%0b prefetch_full=%0b conv_end=%0b conv_release=%0b weight_valid=%0b input_channel=%0d output_channel=%0d input_windows=%0d input_col=%0d output_windows=%0d output_read_count=%0d output_write_count=%0d output_en=%0b output_wr=%0b",
           dut.st_input_current.name(), dut.st_input_next.name(),
           dut.st_conv_current.name(), dut.st_conv_next.name(),
           dut.st_output_current.name(), dut.st_output_next.name(),
           p_input_addr, p_input_valid, dut.r_input_prefetch_active, dut.r_input_prefetch_full,
           dut.w_conv_end, dut.w_conv_input_release, dut.r_weight_tile_valid, dut.r_input_channel_counter_input,
           dut.r_output_channel_counter_input, dut.r_input_window_counter_acc,
           dut.r_input_window_counter_col, dut.r_output_window_counter_acc,
           dut.r_output_read_count, dut.r_output_write_count, p_output_en, p_output_wr);
`endif
  end
endmodule
