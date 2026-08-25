`timescale 1ns/1ps

module tb;
  import pack_data::*;
  import pack_param::*;
  import pack_mux_mult::*;

  localparam int NBITS = 20;
  localparam int NADDR = 13;
  // One output map is allocated per output channel. The input-channel passes
  // accumulate into the same addresses, so they do not increase this depth.
  localparam int OUTPUT_SIZE = FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE * N_CHANNEL_OUT;

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
  logic [NBITS-1:0] output_mem [0:OUTPUT_SIZE-1];
  int write_count;
  int oob_count;
  int cycles;
  int value_errors;
  bit saw_end;

  always #5 clk = ~clk;

  // Combinational ROM model used by this focused controller test.
  assign p_input_data = (p_input_en && (p_input_addr < $size(const_data)))
                      ? NBITS'(const_data[p_input_addr]) : '0;
  assign p_input_valid = p_input_en;
  assign p_output_data_read = (p_output_en && (p_output_addr < OUTPUT_SIZE))
                            ? output_mem[p_output_addr] : '0;
  assign p_output_valid = p_output_en;

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
    .clk(clk), .reset(reset), .p_start(p_start), .p_end(p_end),
    .p_input_en(p_input_en), .p_input_addr(p_input_addr),
    .p_input_data(p_input_data), .p_input_valid(p_input_valid),
    .p_output_en(p_output_en), .p_output_wr(p_output_wr),
    .p_output_addr(p_output_addr), .p_output_data_write(p_output_data_write),
    .p_output_data_read(p_output_data_read), .p_output_valid(p_output_valid)
  );

  always_ff @(posedge clk) begin
    if (reset) begin
      output_mem <= '{default: '0};
      write_count <= 0;
      oob_count <= 0;
    end else if (p_output_en && p_output_wr) begin
      if (p_output_addr < OUTPUT_SIZE)
        output_mem[p_output_addr] <= p_output_data_write;
      else begin
        oob_count <= oob_count + 1;
        if (oob_count < 8)
          $display("OOB write addr=%0d data=%0d time=%0t", p_output_addr, $signed(p_output_data_write), $time);
      end
      write_count <= write_count + 1;
    end
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
    while (!p_end && cycles < 2_000_000) begin
      @(posedge clk);
      cycles++;
    end

    saw_end = p_end;
    // Allow the final nonblocking output-memory counter update to settle.
    #1;

    if (!saw_end)
      $fatal(1, "2x2 convolution timeout after %0d cycles", cycles);
    if (oob_count != 0)
      $fatal(1, "output address out of bounds: %0d", oob_count);
    if (write_count != N_CHANNEL_IN * N_CHANNEL_OUT * FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE)
      $fatal(1, "unexpected write count: got %0d", write_count);
    value_errors = 0;
    for (int ch = 0; ch < N_CHANNEL_OUT; ch++)
      for (int row = 0; row < FEAT_OUTPUT_SIZE; row++)
        for (int col = 0; col < FEAT_OUTPUT_SIZE; col++) begin
          int expected;
          int got;
          expected = const_feat_out[ch * FEAT_OUTPUT_SIZE + row][col];
          got = $signed(output_mem[ch * FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE +
                                    row * FEAT_OUTPUT_SIZE + col]);
          if (got != expected) begin
            if (value_errors < 8)
              $display("VALUE_MISMATCH addr=%0d got=%0d expected=%0d", ch * FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE + row * FEAT_OUTPUT_SIZE + col, got, expected);
            value_errors++;
          end
        end
    if (value_errors != 0)
      $fatal(1, "numerical mismatch count: %0d", value_errors);
    $display("2x2 smoke test passed: cycles=%0d writes=%0d", cycles, write_count);
    $finish;
  end
endmodule
