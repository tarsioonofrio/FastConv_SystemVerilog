`timescale 1ns/1ps

// Common functional workload for the scalar and column-I/O Conv interfaces.
// It uses the canonical generated data package and checks final output memory
// contents without relying on implementation-specific DUT internals.
module tb_power;
  import pack_data::*;
  import pack_param::*;

  localparam int unsigned NBITS = 20;
  localparam int unsigned INPUT_MEMORY_SIZE = $size(const_data);
  localparam int unsigned OUTPUT_MEMORY_SIZE = FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE * N_CHANNEL_OUT;
  // Keep address width identical across all four candidates and aligned with
  // the frozen FPGA pilot; this avoids hiding area differences in an address
  // width change caused by the testbench.
  localparam int unsigned NADDR = 16;
  localparam int unsigned EXPECTED_OUTPUT_WORDS = OUTPUT_MEMORY_SIZE;
  localparam realtime HALF_PERIOD_NS = 1.577;

  logic clk = 1'b0;
  logic reset = 1'b1;
  logic p_start = 1'b0;
  logic p_end;
  logic p_input_en;
  logic [NADDR-1:0] p_input_addr;
`ifdef COLUMN_IO
  logic [CONV_INPUT_SIZE*NBITS-1:0] p_input_data;
  logic [CONV_OUTPUT_SIZE*NBITS-1:0] p_output_data_write;
  logic [CONV_OUTPUT_SIZE*NBITS-1:0] p_output_data_read;
`else
  logic [NBITS-1:0] p_input_data;
  logic [NBITS-1:0] p_output_data_write;
  logic [NBITS-1:0] p_output_data_read;
`endif
  logic p_input_valid;
  logic p_output_en;
  logic p_output_wr;
  logic [NADDR-1:0] p_output_addr;
  logic p_output_valid;

  logic [NBITS-1:0] output_scoreboard [0:OUTPUT_MEMORY_SIZE-1];
  integer output_write_words;
  integer active_cycles;
  logic measuring;

  always #(HALF_PERIOD_NS) clk = ~clk;

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

`ifdef COLUMN_IO
  logic [NBITS-1:0] input_word [0:CONV_INPUT_SIZE-1];
  logic [CONV_INPUT_SIZE-1:0] input_valid_lane;
  for (genvar lane = 0; lane < CONV_INPUT_SIZE; lane++) begin: INPUT_ROM_LANE
    Memory #(.NADDR(NADDR), .NBITS(NBITS), .LATENCY(1), .ROM(1)) memory_input (
      .clk(clk), .reset(reset), .chip_en(p_input_en), .wr_en(1'b0),
      .address(p_input_addr + NADDR'(lane)), .data_in('0),
      .data_out(input_word[lane]), .data_valid(input_valid_lane[lane])
    );
    always_comb p_input_data[lane*NBITS +: NBITS] = input_word[lane];
  end
  assign p_input_valid = input_valid_lane[0];

  always_comb begin: OUTPUT_COLUMN_READ_BLOCK
    for (int unsigned lane = 0; lane < CONV_OUTPUT_SIZE; lane++) begin
      int unsigned lane_addr;
      lane_addr = int'(p_output_addr) + lane*FEAT_OUTPUT_SIZE;
      p_output_data_read[lane*NBITS +: NBITS] =
          (p_output_en && lane_addr < OUTPUT_MEMORY_SIZE) ? output_scoreboard[lane_addr] : '0;
    end
  end
  assign p_output_valid = p_output_en;
`else
  Memory #(.NADDR(NADDR), .NBITS(NBITS), .LATENCY(1), .ROM(1)) memory_input (
    .clk(clk), .reset(reset), .chip_en(p_input_en), .wr_en(1'b0),
    .address(p_input_addr), .data_in('0), .data_out(p_input_data),
    .data_valid(p_input_valid)
  );
  Memory #(.NADDR(NADDR), .NBITS(NBITS), .LATENCY(1), .ROM(0)) memory_output (
    .clk(clk), .reset(reset), .chip_en(p_output_en), .wr_en(p_output_wr),
    .address(p_output_addr), .data_in(p_output_data_write),
    .data_out(p_output_data_read), .data_valid(p_output_valid)
  );
`endif

  always_ff @(posedge clk) begin: WORKLOAD_SCOREBOARD_BLOCK
    if (reset) begin
      output_write_words <= 0;
      active_cycles <= 0;
      measuring <= 1'b0;
      output_scoreboard <= '{default: '0};
    end else begin
      if (p_start)
        measuring <= 1'b1;
      if (measuring)
        active_cycles <= active_cycles + 1;

      if (p_output_en && p_output_wr) begin
`ifdef COLUMN_IO
        for (int unsigned lane = 0; lane < CONV_OUTPUT_SIZE; lane++) begin
          int unsigned lane_addr;
          lane_addr = int'(p_output_addr) + lane*FEAT_OUTPUT_SIZE;
          if (lane_addr < OUTPUT_MEMORY_SIZE) begin
            output_scoreboard[lane_addr] <= p_output_data_write[lane*NBITS +: NBITS];
          end
        end
        output_write_words <= output_write_words + CONV_OUTPUT_SIZE;
`else
        if (p_output_addr < OUTPUT_MEMORY_SIZE) begin
          output_scoreboard[p_output_addr] <= p_output_data_write;
          output_write_words <= output_write_words + 1;
        end
`endif
      end
    end
  end

  task automatic check_final_output(output integer errors);
    begin
      errors = 0;
      for (int unsigned address = 0; address < OUTPUT_MEMORY_SIZE; address++) begin
        if ($signed(output_scoreboard[address]) != $signed(const_feat_out[address])) begin
          errors++;
          if (errors <= 8)
            $display("POWER_GOLDEN_MISMATCH address=%0d got=%0d expected=%0d",
                     address, $signed(output_scoreboard[address]), $signed(const_feat_out[address]));
        end
      end
    end
  endtask

  initial begin: TEST_SEQUENCE_BLOCK
    integer final_output_errors;
    // Hold reset through the FPGA global startup interval (GSR is 100 ns).
    repeat (70) @(negedge clk);
    reset = 1'b0;
    repeat (8) @(negedge clk);
    p_start = 1'b1;
    @(negedge clk);
    p_start = 1'b0;
    @(posedge p_end);
    repeat (2) @(negedge clk);
    check_final_output(final_output_errors);
    if (output_write_words != N_CHANNEL_IN * OUTPUT_MEMORY_SIZE)
      $fatal(1, "POWER_RESULT_BAD_WRITE_COUNT got=%0d expected=%0d",
             output_write_words, N_CHANNEL_IN * OUTPUT_MEMORY_SIZE);
    if (final_output_errors != 0)
      $fatal(1, "POWER_RESULT_GOLDEN_FAIL mismatches=%0d", final_output_errors);
    $display("POWER_RESULT PASS writes=%0d final_words=%0d mismatches=%0d active_cycles=%0d",
             output_write_words, OUTPUT_MEMORY_SIZE, final_output_errors, active_cycles);
    $finish;
  end

  initial begin: WATCHDOG_BLOCK
    #200000;
    $fatal(1, "POWER_RESULT_TIMEOUT p_end=%0b writes=%0d", p_end, output_write_words);
  end
endmodule
