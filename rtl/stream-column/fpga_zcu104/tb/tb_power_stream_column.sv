`timescale 1ns/1ps

// Functional post-route workload for the streaming column-interface variants.
// This bench uses only the Conv top-level ports, so it also works with the
// flattened post-implementation functional netlist.
module tb_power_stream_column;
  import pack_data::*;
  import pack_param::*;

  localparam int unsigned NBITS = 20;
  localparam int unsigned INPUT_MEMORY_SIZE = $size(const_data);
  localparam int unsigned FEAT_INPUT_WIDTH = FEAT_INPUT_SIZE;
  localparam int unsigned FEAT_OUTPUT_SIZE = FEAT_INPUT_SIZE - CONV_KERNEL_SIZE + 1;
  localparam int unsigned FEAT_MAP_WORDS = FEAT_INPUT_SIZE * FEAT_INPUT_WIDTH;
  localparam int unsigned TRANSFORMED_WEIGHT_WORDS =
      N_CHANNEL_IN * N_CHANNEL_OUT * HADAMARD_SIZE * HADAMARD_SIZE;
  localparam int unsigned RAW_WEIGHT_BASE = N_CHANNEL_IN * FEAT_MAP_WORDS + TRANSFORMED_WEIGHT_WORDS;
  localparam int unsigned OUTPUT_TILES_PER_AXIS =
      (FEAT_OUTPUT_SIZE + CONV_OUTPUT_SIZE - 1) / CONV_OUTPUT_SIZE;
  localparam int unsigned OUTPUT_PHYSICAL_SIZE = OUTPUT_TILES_PER_AXIS * CONV_OUTPUT_SIZE;
  localparam int unsigned OUTPUT_CHANNEL_WORDS = OUTPUT_PHYSICAL_SIZE * OUTPUT_PHYSICAL_SIZE;
  localparam int unsigned OUTPUT_MEMORY_SIZE = OUTPUT_CHANNEL_WORDS * N_CHANNEL_OUT;
  localparam int unsigned INPUT_ADDR_WIDTH = $clog2(INPUT_MEMORY_SIZE);
  localparam int unsigned OUTPUT_ADDR_WIDTH = $clog2(OUTPUT_MEMORY_SIZE);
  localparam int unsigned NADDR = (INPUT_ADDR_WIDTH > OUTPUT_ADDR_WIDTH) ? INPUT_ADDR_WIDTH : OUTPUT_ADDR_WIDTH;
  localparam int unsigned EXPECTED_WRITE_BEATS =
      N_CHANNEL_IN * N_CHANNEL_OUT * OUTPUT_TILES_PER_AXIS * OUTPUT_TILES_PER_AXIS * CONV_OUTPUT_SIZE;
  localparam realtime HALF_PERIOD_NS = 1.577287;

  logic clk = 1'b0;
  logic reset = 1'b1;
  logic p_start = 1'b0;
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
  int unsigned output_write_beats;
  int unsigned active_cycles;
  int unsigned cycle_count;
  int unsigned start_cycle;
  logic measuring;

  always #(HALF_PERIOD_NS) clk = ~clk;

`ifdef GATE_LEVEL
  Conv dut (
`else
  Conv #(
    .N_CHANNEL_IN(N_CHANNEL_IN),
    .N_CHANNEL_OUT(N_CHANNEL_OUT),
    .FEAT_INPUT_SIZE(FEAT_INPUT_SIZE),
    .FEAT_INPUT_WIDTH(FEAT_INPUT_WIDTH),
    .NADDR(NADDR),
    .NBITS(NBITS),
    .QUANT(QUANT_BITS),
    .CONV_OUTPUT_SIZE(CONV_OUTPUT_SIZE),
    .CONV_INPUT_SIZE(CONV_INPUT_SIZE),
    .HADAMARD_SIZE(HADAMARD_SIZE),
    .NUM_MULT(HADAMARD_SIZE)
  ) dut (
`endif
    .clk(clk), .reset(reset), .p_start(p_start), .p_end(p_end),
    .p_input_en(p_input_en), .p_input_addr(p_input_addr),
    .p_input_data(p_input_data), .p_input_valid(p_input_valid),
    .p_output_en(p_output_en), .p_output_wr(p_output_wr),
    .p_output_addr(p_output_addr), .p_output_data_write(p_output_data_write),
    .p_output_data_read(p_output_data_read), .p_output_valid(p_output_valid)
  );

  // One beat reads a vertical column.  Padding must not wrap across an image
  // row or channel; the raw-weight tail is read contiguously instead.
  always_comb begin: COLUMN_INPUT_ADDRESS_BLOCK
    int unsigned base_channel;
    int unsigned base_offset;
    logic reading_raw_weights;
`ifdef GATE_LEVEL
    reading_raw_weights = (int'(p_input_addr) >= RAW_WEIGHT_BASE);
`else
    reading_raw_weights = dut.w_input_read_weights;
`endif
    base_channel = int'(p_input_addr) / FEAT_MAP_WORDS;
    base_offset = int'(p_input_addr) % FEAT_MAP_WORDS;
    for (int unsigned lane = 0; lane < CONV_INPUT_SIZE; lane++) begin
      column_input_addr[lane] = p_input_addr + NADDR'(lane);
      column_input_in_bounds[lane] = 1'b1;
`ifdef GATE_LEVEL
      if (!reading_raw_weights &&
          ((base_channel != int'(dut.r_input_channel_counter_input)) ||
           ((base_offset % FEAT_INPUT_WIDTH) + lane >= FEAT_INPUT_WIDTH)))
`else
      if (!reading_raw_weights &&
          ((base_channel != int'(dut.r_input_channel_counter_input)) ||
           ((base_offset % FEAT_INPUT_WIDTH) + lane >= FEAT_INPUT_WIDTH)))
`endif
        column_input_in_bounds[lane] = 1'b0;
    end
  end

  for (genvar lane = 0; lane < CONV_INPUT_SIZE; lane++) begin: COLUMN_INPUT_MEMORY_LANE
    Memory #(.NADDR(NADDR), .NBITS(NBITS), .LATENCY(1), .ROM(1)) memory_input (
      .clk(clk), .reset(reset), .chip_en(p_input_en), .wr_en(1'b0),
      .address(column_input_addr[lane]), .data_in('0),
      .data_out(column_input_word[lane]), .data_valid(column_input_valid[lane])
    );
    always_comb begin
      p_input_data[lane*NBITS +: NBITS] =
          (column_input_in_bounds[lane] && (column_input_addr[lane] < INPUT_MEMORY_SIZE))
              ? column_input_word[lane] : '0;
    end
  end
  assign p_input_valid = column_input_valid[0];

  // Output columns are stored in the physical grid of whole convolution
  // windows.  For 4x4, this grid is 32x32 while the logical result is 30x30.
  always_comb begin: COLUMN_OUTPUT_READ_BLOCK
    for (int unsigned lane = 0; lane < CONV_OUTPUT_SIZE; lane++) begin
      int unsigned lane_address;
      lane_address = int'(p_output_addr) + lane * OUTPUT_PHYSICAL_SIZE;
      p_output_data_read[lane*NBITS +: NBITS] =
          (lane_address < OUTPUT_MEMORY_SIZE) ? output_bank[lane_address] : '0;
    end
  end
  assign p_output_valid = p_output_en;

  always_ff @(posedge clk or posedge reset) begin: SCOREBOARD_BLOCK
    if (reset) begin
      output_write_beats <= 0;
      active_cycles <= 0;
      cycle_count <= 0;
      start_cycle <= 0;
      measuring <= 1'b0;
      output_bank <= '{default: '0};
    end else begin
      cycle_count <= cycle_count + 1;
      if (p_start) begin
        measuring <= 1'b1;
        start_cycle <= cycle_count;
      end
      if (measuring && !p_end)
        active_cycles <= active_cycles + 1;

      if (p_output_en && p_output_wr) begin
        output_write_beats <= output_write_beats + 1;
        for (int unsigned lane = 0; lane < CONV_OUTPUT_SIZE; lane++) begin
          int unsigned lane_address;
          int unsigned lane_row;
          int unsigned lane_col;
          lane_address = int'(p_output_addr) + lane * OUTPUT_PHYSICAL_SIZE;
          lane_row = (lane_address % OUTPUT_CHANNEL_WORDS) / OUTPUT_PHYSICAL_SIZE;
          lane_col = (lane_address % OUTPUT_CHANNEL_WORDS) % OUTPUT_PHYSICAL_SIZE;
          if ((lane_address < OUTPUT_MEMORY_SIZE) && (lane_row < FEAT_OUTPUT_SIZE) &&
              (lane_col < FEAT_OUTPUT_SIZE))
            output_bank[lane_address] <= p_output_data_write[lane*NBITS +: NBITS];
        end
      end
    end
  end

  task automatic check_final_output(output integer errors);
    begin
      errors = 0;
      for (int unsigned channel = 0; channel < N_CHANNEL_OUT; channel++) begin
        for (int unsigned row = 0; row < FEAT_OUTPUT_SIZE; row++) begin
          for (int unsigned col = 0; col < FEAT_OUTPUT_SIZE; col++) begin
            int unsigned physical_address;
            int unsigned golden_address;
            physical_address = channel * OUTPUT_CHANNEL_WORDS + row * OUTPUT_PHYSICAL_SIZE + col;
            golden_address = channel * FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE + row * FEAT_OUTPUT_SIZE + col;
            if ($signed(output_bank[physical_address]) != $signed(const_feat_out[golden_address])) begin
              errors++;
              if (errors <= 8)
                $display("POWER_GOLDEN_MISMATCH ch=%0d row=%0d col=%0d got=%0d expected=%0d",
                         channel, row, col, $signed(output_bank[physical_address]),
                         $signed(const_feat_out[golden_address]));
            end
          end
        end
      end
    end
  endtask

  initial begin: TEST_SEQUENCE_BLOCK
    integer final_output_errors;
    // Match the project's functional testbench while holding start past the
    // FPGA startup GSR interval used by post-implementation simulation.
    reset = 1'b1;
    p_start = 1'b0;
    #20 reset = 1'b0;
    #100;
    p_start = 1'b1;
    #10;
    p_start = 1'b0;
    @(posedge p_end);
    repeat (3) @(posedge clk);
    check_final_output(final_output_errors);
    if (output_write_beats != EXPECTED_WRITE_BEATS)
      $fatal(1, "POWER_RESULT_BAD_WRITE_BEATS got=%0d expected=%0d",
             output_write_beats, EXPECTED_WRITE_BEATS);
    if (final_output_errors != 0)
      $fatal(1, "POWER_RESULT_GOLDEN_FAIL mismatches=%0d", final_output_errors);
    $display("STREAM_COLUMN_POWER_PASS writes=%0d physical_words=%0d final_words=%0d mismatches=%0d active_cycles=%0d",
             output_write_beats, output_write_beats * CONV_OUTPUT_SIZE,
             N_CHANNEL_OUT * FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE,
             final_output_errors, active_cycles);
    $finish;
  end

  initial begin: WATCHDOG_BLOCK
    #200000;
    $fatal(1, "STREAM_COLUMN_POWER_TIMEOUT p_end=%0b writes=%0d", p_end, output_write_beats);
  end
endmodule
