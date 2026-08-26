`timescale 1ns/1ps

module tb;
  import pack_data::*;
  import pack_param::*;
  import pack_mux_mult::*;

  localparam int unsigned FEAT_INPUT_WIDTH = FEAT_INPUT_SIZE;
  localparam int unsigned NBITS = 20;
  localparam int unsigned LATENCY = 1;
  localparam int unsigned ROM = 1;

  // Include the generated header, transformed weights and all feature maps.
  localparam int unsigned INPUT_MEMORY_SIZE =
      N_CHANNEL_IN * FEAT_INPUT_SIZE * FEAT_INPUT_WIDTH +
      N_CHANNEL_OUT * N_CHANNEL_IN * HADAMARD_SIZE * HADAMARD_SIZE +
      N_CHANNEL_IN * N_CHANNEL_OUT;
  localparam int unsigned OUTPUT_MEMORY_SIZE =
      FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE * N_CHANNEL_OUT;
  localparam int unsigned INPUT_ADDR_WIDTH = $clog2(INPUT_MEMORY_SIZE);
  localparam int unsigned OUTPUT_ADDR_WIDTH = $clog2(OUTPUT_MEMORY_SIZE);
  localparam int unsigned NADDR =
      (INPUT_ADDR_WIDTH > OUTPUT_ADDR_WIDTH) ? INPUT_ADDR_WIDTH : OUTPUT_ADDR_WIDTH;

  localparam logic [1:0] ST_CONV_INVERSE = 2'b11;

  logic clk;
  logic reset;
  logic p_start;
  logic p_end;

  logic p_input_en;
  logic [NADDR-1:0] p_input_addr;
  logic [NBITS-1:0] p_input_data;
  logic [NBITS-1:0] p_input_data_write;
  logic p_input_valid;

  logic p_output_en;
  logic p_output_wr;
  logic [NADDR-1:0] p_output_addr;
  logic [NBITS-1:0] p_output_data_write;
  logic [NBITS-1:0] p_output_data_read;
  logic p_output_valid;

  logic [NBITS-1:0] output_bank [0:OUTPUT_MEMORY_SIZE-1];
  logic in_inverse_d;
  int conv_inverse_check_idx;
  int output_error_count;
  int output_oob_count;
  int write_count;
  int cycle_count;

  assign p_input_data_write = '0;

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
    .NUM_MULT(NUM_MULT),
    .STATE_MULT(STATE_MULT)
  ) dut (
    .clk(clk),
    .reset(reset),
    .p_start(p_start),
    .p_input_en(p_input_en),
    .p_input_addr(p_input_addr),
    .p_input_data(p_input_data),
    .p_input_valid(p_input_valid),
    .p_output_en(p_output_en),
    .p_output_wr(p_output_wr),
    .p_output_addr(p_output_addr),
    .p_output_data_write(p_output_data_write),
    .p_output_data_read(p_output_data_read),
    .p_output_valid(p_output_valid),
    .p_end(p_end)
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
    .data_in(p_input_data_write),
    .data_out(p_input_data),
    .data_valid(p_input_valid)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  // Capture every output write and retain a testbench-side output image.
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      output_bank <= '{default: '0};
      write_count <= 0;
      output_oob_count <= 0;
      cycle_count <= 0;
    end else begin
      cycle_count <= cycle_count + 1;
      if (p_output_en && p_output_wr) begin
        write_count <= write_count + 1;
        if (p_output_addr < OUTPUT_MEMORY_SIZE)
          output_bank[p_output_addr] <= p_output_data_write;
        else begin
          output_oob_count <= output_oob_count + 1;
          if (output_oob_count < 8)
            $display("ERROR WRITE ADDR OOB: time=%0t addr=%0d data=%0d",
                     $realtime, p_output_addr, $signed(p_output_data_write));
        end

        // Check the final accumulation write as it leaves the DUT.
        if (dut.r_output_channel_counter_input == (N_CHANNEL_IN - 1) &&
            p_output_addr < OUTPUT_MEMORY_SIZE &&
            $signed(p_output_data_write) !=
            $signed(const_feat_out[p_output_addr / FEAT_OUTPUT_SIZE]
                                        [p_output_addr % FEAT_OUTPUT_SIZE])) begin
          output_error_count <= output_error_count + 1;
          if (output_error_count < 8)
            $display("ERROR WRITE GOLDEN: time=%0t addr=%0d got=%0d expected=%0d",
                     $realtime, p_output_addr, $signed(p_output_data_write),
                     $signed(const_feat_out[p_output_addr / FEAT_OUTPUT_SIZE]
                                              [p_output_addr % FEAT_OUTPUT_SIZE]));
        end
      end
    end
  end

  // Count inverse tiles while the final output value is checked at the write
  // port below.  Each inverse is an input-channel partial sum; the generated
  // output golden is the accumulation across all input channels.
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      conv_inverse_check_idx <= 0;
      in_inverse_d <= 1'b0;
    end else begin
      in_inverse_d <= (dut.st_conv_current == ST_CONV_INVERSE);
      if ((dut.st_conv_current == ST_CONV_INVERSE) && !in_inverse_d)
        conv_inverse_check_idx <= conv_inverse_check_idx + 1;
    end
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);

    reset = 1'b1;
    p_start = 1'b0;
    #20 reset = 1'b0;
    #80 p_start = 1'b1;
    #10 p_start = 1'b0;

    if (p_end !== 1'b1)
      @(posedge p_end);
    #200;

    if (write_count != N_CHANNEL_IN * N_CHANNEL_OUT * FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE)
      $fatal(1, "unexpected write count: got %0d", write_count);
    if (output_oob_count != 0)
      $fatal(1, "output address out of bounds: %0d", output_oob_count);
    if (output_error_count != 0)
      $fatal(1, "output golden mismatch count: %0d", output_error_count);
    if (conv_inverse_check_idx !=
        N_CHANNEL_IN * N_CHANNEL_OUT * FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE /
        (CONV_OUTPUT_SIZE * CONV_OUTPUT_SIZE))
      $fatal(1, "unexpected inverse count: got %0d expected %0d",
             conv_inverse_check_idx,
             N_CHANNEL_IN * N_CHANNEL_OUT * FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE /
             (CONV_OUTPUT_SIZE * CONV_OUTPUT_SIZE));

    $display("2x2 simulation passed: inverse_tiles=%0d cycles=%0d writes=%0d",
             conv_inverse_check_idx, cycle_count, write_count);
    $finish;
  end
endmodule
