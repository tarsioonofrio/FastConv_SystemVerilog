`timescale 1ns/1ps

module tb;
  import pack_data::*;
  import pack_param::*;
  import pack_mux_mult::*;

  // Keep the verification wrapper aligned with the 2x2/3x3 controllers.
  localparam int unsigned NBITS = 20;
  localparam int unsigned LATENCY = 1;
  localparam int unsigned ROM = 1;
  localparam int unsigned INPUT_MEMORY_SIZE = $size(const_data);
  localparam int unsigned OUTPUT_MEMORY_SIZE =
    FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE * N_CHANNEL_OUT;
  localparam int unsigned INPUT_ADDR_WIDTH = $clog2(INPUT_MEMORY_SIZE);
  localparam int unsigned OUTPUT_ADDR_WIDTH = $clog2(OUTPUT_MEMORY_SIZE);
  localparam int unsigned NADDR =
    (INPUT_ADDR_WIDTH > OUTPUT_ADDR_WIDTH) ? INPUT_ADDR_WIDTH : OUTPUT_ADDR_WIDTH;

  logic clk = 1'b0;
  logic reset = 1'b1;
  logic p_start = 1'b0;
  logic p_end;
  logic p_input_en;
  logic [NADDR-1:0] p_input_addr;
  logic [NBITS-1:0] p_input_data;
  logic p_input_valid;
  logic p_output_en;
  logic p_output_wr;
  logic [NADDR-1:0] p_output_addr;
  logic [NBITS-1:0] p_output_data_write;
  logic [NBITS-1:0] p_output_data_read;
  logic p_output_valid;
  logic [NBITS-1:0] output_bank [0:OUTPUT_MEMORY_SIZE-1];
  int write_count;
  int oob_count;
  int cycles;
  int value_errors;
  bit saw_end;

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
    .NUM_MULT(NUM_MULT),
    .STATE_MULT(STATE_MULT)
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

  Memory #(
    .NADDR(NADDR),
    .NBITS(NBITS),
    .LATENCY(LATENCY),
    .ROM(0)
  ) memory_output (
    .clk(clk),
    .reset(reset),
    .chip_en(p_output_en),
    .wr_en(p_output_wr),
    .address(p_output_addr),
    .data_in(p_output_data_write),
    .data_out(p_output_data_read),
    .data_valid(p_output_valid)
  );

  Memory #(
    .NADDR(NADDR),
    .NBITS(NBITS),
    .LATENCY(LATENCY),
    .ROM(ROM)
  ) memory_input (
    .clk(clk),
    .reset(reset),
    .chip_en(p_input_en),
    .wr_en(1'b0),
    .address(p_input_addr),
    .data_in('0),
    .data_out(p_input_data),
    .data_valid(p_input_valid)
  );

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      output_bank <= '{default: '0};
      write_count <= 0;
      oob_count <= 0;
    end else if (p_output_en && p_output_wr) begin
      write_count <= write_count + 1;
      if (p_output_addr < OUTPUT_MEMORY_SIZE)
        output_bank[p_output_addr] <= p_output_data_write;
      else
        oob_count <= oob_count + 1;
    end
  end

  always_ff @(posedge clk or posedge reset) begin
    if (reset)
      saw_end <= 1'b0;
    else if (p_end)
      saw_end <= 1'b1;
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);

    repeat (2) @(posedge clk);
    reset <= 1'b0;
    repeat (8) @(posedge clk);
    p_start <= 1'b1;
    @(posedge clk);
    p_start <= 1'b0;

    cycles = 0;
    while (!saw_end && cycles < 2_000_000) begin
      @(posedge clk);
      cycles++;
    end
    #1;

    if (!saw_end) begin
      $display("TIMEOUT input_state=%0d conv_state=%0d output_state=%0d input_ch=%0d output_ch=%0d in_win=%0d out_win=%0d out_write=%0d out_read=%0d",
               dut.st_input_current, dut.st_conv_current, dut.st_output_current,
               dut.r_input_channel_counter_input, dut.r_input_channel_counter_output,
               dut.r_input_window_counter_acc, dut.r_output_window_counter_acc,
               dut.r_output_write_count, dut.r_output_read_count);
      $fatal(1, "4x4 convolution timeout after %0d cycles", cycles);
    end
    if (oob_count != 0)
      $fatal(1, "output address out of bounds: %0d", oob_count);
    if (write_count != N_CHANNEL_IN * N_CHANNEL_OUT *
                       FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE)
      $fatal(1, "unexpected write count: got %0d", write_count);

    value_errors = 0;
    for (int ch = 0; ch < N_CHANNEL_OUT; ch++)
      for (int row = 0; row < FEAT_OUTPUT_SIZE; row++)
        for (int col = 0; col < FEAT_OUTPUT_SIZE; col++) begin
          int expected;
          int got;
          expected = const_feat_out[ch * FEAT_OUTPUT_SIZE + row][col];
          got = $signed(output_bank[ch * FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE +
                                     row * FEAT_OUTPUT_SIZE + col]);
          if (got != expected) begin
            if (value_errors < 8)
              $display("VALUE_MISMATCH addr=%0d got=%0d expected=%0d",
                       ch * FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE +
                       row * FEAT_OUTPUT_SIZE + col, got, expected);
            value_errors++;
          end
        end

    if (value_errors != 0)
      $fatal(1, "numerical mismatch count: %0d", value_errors);
    $display("4x4 controller smoke test passed: cycles=%0d writes=%0d",
             cycles, write_count);
    $finish;
  end
endmodule
