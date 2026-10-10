`timescale 1ns/1ps

module tb_prefetch8_column #(
`ifdef ASIC_NUM_MULT
  parameter int unsigned MAC_COUNT = `ASIC_NUM_MULT
`else
  parameter int unsigned MAC_COUNT = 8
`endif
);
  import pack_data::*;
  import pack_param::*;

`ifdef NBITS16
  localparam int unsigned NBITS = 16;
`else
  localparam int unsigned NBITS = 20;
`endif
  localparam int unsigned FEAT_INPUT_WIDTH = FEAT_INPUT_SIZE;
  localparam int unsigned LATENCY = 1;
  localparam int unsigned INPUT_MEMORY_SIZE = $size(const_data);
  localparam int unsigned FEATURE_MEMORY_WORDS =
      FEAT_INPUT_SIZE * FEAT_INPUT_WIDTH * N_CHANNEL_IN;
  localparam int unsigned OUTPUT_MEMORY_SIZE = FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE * N_CHANNEL_OUT;
  localparam int unsigned RAW_WEIGHT_WORDS_PER_BEAT = CONV_KERNEL_SIZE;
  localparam int unsigned EXPECTED_USEFUL_WEIGHT_BEATS =
      N_CHANNEL_IN * N_CHANNEL_OUT * CONV_KERNEL_SIZE * CONV_KERNEL_SIZE /
      RAW_WEIGHT_WORDS_PER_BEAT;
  localparam int unsigned INPUT_ADDR_WIDTH = $clog2(INPUT_MEMORY_SIZE);
  localparam int unsigned OUTPUT_ADDR_WIDTH = $clog2(OUTPUT_MEMORY_SIZE);
  localparam int unsigned NADDR = (INPUT_ADDR_WIDTH > OUTPUT_ADDR_WIDTH) ? INPUT_ADDR_WIDTH : OUTPUT_ADDR_WIDTH;
  localparam int unsigned INPUT_TILES_PER_AXIS =
      (FEAT_OUTPUT_SIZE + CONV_OUTPUT_SIZE - 1) / CONV_OUTPUT_SIZE;
  localparam int unsigned EXPECTED_INVERSE_COUNT =
      N_CHANNEL_IN * N_CHANNEL_OUT * INPUT_TILES_PER_AXIS * INPUT_TILES_PER_AXIS;

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
  int terminal_inverse_event_count;
  int output_error_count;
  int gate_output_mismatch_count;
  int output_out_of_range_count;
  int input_out_of_range_count;
  int valid_output_word_count;
  int weight_read_beat_count;
  int useful_weight_read_beat_count;
  int cycle_count;
  realtime job_start_time;
  realtime job_end_time;
  realtime job_execution_time;
  int job_execution_cycles;
  localparam real CLOCK_PERIOD_NS = 2.0;
  logic conv_end_d;

  function automatic int expected_output_value(input int unsigned address);
    expected_output_value = const_feat_out[address];
  endfunction

  always #(CLOCK_PERIOD_NS / 2.0) clk = ~clk;

`ifndef GATE_LEVEL
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
    .NUM_MULT(MAC_COUNT)
  ) dut (
`else
  Conv dut (
`endif
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

`ifdef XRUN
  initial begin: POWER_ACTIVITY_CAPTURE_BLOCK
    $shm_open("dut.shm");
    $shm_probe(tb_prefetch8_column.dut, "ASM");
  end
`endif

  always_comb begin: COLUMN_INPUT_ADDRESS_BLOCK
    for (int unsigned lane = 0; lane < CONV_INPUT_SIZE; lane++) begin
      // Feature reads transfer a full input column; weight reads transfer one
      // contiguous 3-word spatial-kernel row in lanes zero through two.
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
`ifdef GATE_LEVEL
    // The mapped gate netlist does not expose the FSM state. Check only the
    // externally observable package-memory bounds in this mode.
    for (int unsigned lane = 0; lane < CONV_INPUT_SIZE; lane++) begin
      if (column_input_addr[lane] >= INPUT_MEMORY_SIZE)
        input_column_in_bounds = 1'b0;
    end
`else
    if (dut.st_input_current != 4'd2) begin // READ_WEIGHTS
      for (int unsigned lane = 0; lane < CONV_INPUT_SIZE; lane++) begin
        if ((column_input_addr[lane] >= INPUT_MEMORY_SIZE) ||
            ((local_base % FEAT_INPUT_WIDTH) + lane >= FEAT_INPUT_WIDTH) ||
            ((local_base / FEAT_INPUT_WIDTH) >= FEAT_INPUT_SIZE))
          input_column_in_bounds = 1'b0;
      end
    end
`endif
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
      terminal_inverse_event_count <= 0;
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
`ifndef GATE_LEVEL
      conv_end_d <= dut.w_conv_end;
      if (dut.w_conv_end && !conv_end_d) begin
        if (dut.r_input_channel_counter_output < N_CHANNEL_OUT)
          inverse_tile_count <= inverse_tile_count + 1;
        else
          terminal_inverse_event_count <= terminal_inverse_event_count + 1;
      end

      if ((dut.st_input_current == 4'd2) && p_input_valid) begin // READ_WEIGHTS
        weight_read_beat_count <= weight_read_beat_count + 1;
        if (dut.r_input_channel_counter_output < N_CHANNEL_OUT)
          useful_weight_read_beat_count <= useful_weight_read_beat_count + 1;
      end
`else
      if (p_input_valid && (p_input_addr >= FEATURE_MEMORY_WORDS)) begin
        weight_read_beat_count <= weight_read_beat_count + 1;
        useful_weight_read_beat_count <= useful_weight_read_beat_count + 1;
      end
`endif

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
`ifndef GATE_LEVEL
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
`endif
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
    @(posedge clk);
    job_start_time = $realtime;
    #10 p_start = 1'b0;

    if (p_end !== 1'b1)
      @(posedge p_end);
    job_end_time = $realtime;
    job_execution_time = job_end_time - job_start_time;
    job_execution_cycles = $rtoi(job_execution_time / CLOCK_PERIOD_NS + 0.5);
    begin
      integer runtime_file;
      runtime_file = $fopen("execution_time.txt", "w");
      if (runtime_file == 0)
        $fatal(1, "could not open execution_time.txt for writing");
      $fdisplay(runtime_file, "measurement=accepted_p_start_to_p_end");
      $fdisplay(runtime_file, "clock_period_ns=%0.3f", CLOCK_PERIOD_NS);
      $fdisplay(runtime_file, "start_time_ns=%0.3f", job_start_time);
      $fdisplay(runtime_file, "end_time_ns=%0.3f", job_end_time);
      $fdisplay(runtime_file, "job_execution_time_ns=%0.3f", job_execution_time);
      $fdisplay(runtime_file, "job_execution_time_us=%0.6f", job_execution_time / 1000.0);
      $fdisplay(runtime_file, "job_execution_cycles=%0d", job_execution_cycles);
      $fclose(runtime_file);
    end
    $display("Job execution time: %0.3f ns (%0.6f us), %0d cycles",
             job_execution_time, job_execution_time / 1000.0, job_execution_cycles);
`ifdef GATE_LEVEL
    // The mapped netlist does not preserve internal FSM/counter names. Check
    // the completed output bank after all externally visible output writes.
    wait (valid_output_word_count ==
          N_CHANNEL_IN * N_CHANNEL_OUT * FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE);
    @(negedge clk);
    gate_output_mismatch_count = 0;
    for (int unsigned address = 0; address < OUTPUT_MEMORY_SIZE; address++) begin
      if ($signed(output_bank[address]) !=
          $signed(expected_output_value(address))) begin
        gate_output_mismatch_count++;
        if (gate_output_mismatch_count <= 8)
          $display("ERROR GATE GOLDEN: address=%0d got=%0d expected=%0d",
                   address, $signed(output_bank[address]),
                   expected_output_value(address));
      end
    end
`else
    // p_end marks job latency; wait separately for the terminal inverse event
    // used by the post-job functional checks.
    wait (terminal_inverse_event_count == 1);
    #10ps;
`endif

`ifdef GATE_LEVEL
    if (gate_output_mismatch_count != 0)
      $fatal(1, "gate-level output golden mismatch count: %0d",
             gate_output_mismatch_count);
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
    if (terminal_inverse_event_count != 1)
      $fatal(1, "unexpected terminal inverse event count: got %0d expected 1",
             terminal_inverse_event_count);
    if (useful_weight_read_beat_count != EXPECTED_USEFUL_WEIGHT_BEATS)
      $fatal(1, "unexpected useful weight read beats: got %0d expected %0d",
             useful_weight_read_beat_count, EXPECTED_USEFUL_WEIGHT_BEATS);
`endif
    if (input_out_of_range_count != 0 || output_out_of_range_count != 0)
      $fatal(1, "out-of-range accesses: input=%0d output=%0d",
             input_out_of_range_count, output_out_of_range_count);

    $display("prefetch8-column simulation passed: inverse_tiles=%0d terminal_inverse_events=%0d cycles=%0d weight_read_beats=%0d useful_weight_beats=%0d valid_writes=%0d input_oob=%0d output_oob=%0d",
             inverse_tile_count, terminal_inverse_event_count, cycle_count, weight_read_beat_count,
             useful_weight_read_beat_count, valid_output_word_count,
             input_out_of_range_count, output_out_of_range_count);
    $finish;
  end

  initial begin: WATCHDOG_BLOCK
    #1000000;
`ifdef GATE_LEVEL
    $fatal(1, "prefetch8-column gate-level timeout: input_addr=%0d input_valid=%0b output_en=%0b output_wr=%0b p_end=%0b",
           p_input_addr, p_input_valid, p_output_en, p_output_wr, p_end);
`else
    $fatal(1, "prefetch8-column timeout: input_state=%s input_next=%s conv_state=%s conv_next=%s output_state=%s output_next=%s input_addr=%0d input_valid=%0b prefetch_active=%0b prefetch_full=%0b conv_end=%0b conv_release=%0b weight_valid=%0b input_channel=%0d output_channel=%0d input_windows=%0d input_col=%0d output_windows=%0d output_read_count=%0d output_write_count=%0d output_en=%0b output_wr=%0b",
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
