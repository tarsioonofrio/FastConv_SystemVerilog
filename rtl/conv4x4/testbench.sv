`timescale 1ns/1ps

module tb;
  import pack_data::*;
  import pack_param::*;
  import pack_mux_mult::*;

  // Geometry of the regenerated three-channel 32x32 dataset.
  localparam int unsigned N_CHANNEL_IN = 3;
  localparam int unsigned N_CHANNEL_OUT = 3;
  localparam int unsigned FEAT_INPUT_SIZE = 32;
  localparam int unsigned FEAT_INPUT_WIDTH = FEAT_INPUT_SIZE;
  localparam int unsigned FEAT_OUTPUT_SIZE = FEAT_INPUT_SIZE - 2;
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
  localparam logic [1:0] ST_CONV_INVERSE = 2'b11;
  localparam int unsigned OUTPUT_TILES_PER_AXIS =
    (FEAT_OUTPUT_SIZE + CONV_OUTPUT_SIZE - 1) / CONV_OUTPUT_SIZE;
  localparam int unsigned EXPECTED_INVERSE_COUNT =
    N_CHANNEL_IN * N_CHANNEL_OUT * OUTPUT_TILES_PER_AXIS * OUTPUT_TILES_PER_AXIS;

  function automatic int expected_output_value(input int unsigned address);
    int channel;
    int pixel;
    int tile_row;
    int tile_col;
    int local_row;
    int local_col;
    int tile_index;
    int local_index;
    begin
      channel = address / (FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE);
      pixel = address % (FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE);
      tile_row = (pixel / FEAT_OUTPUT_SIZE) / CONV_OUTPUT_SIZE;
      tile_col = (pixel % FEAT_OUTPUT_SIZE) / CONV_OUTPUT_SIZE;
      local_row = (pixel / FEAT_OUTPUT_SIZE) % CONV_OUTPUT_SIZE;
      local_col = pixel % CONV_OUTPUT_SIZE;
      tile_index = channel * OUTPUT_TILES_PER_AXIS * OUTPUT_TILES_PER_AXIS +
                   tile_row * OUTPUT_TILES_PER_AXIS + tile_col;
      // The inverse block emits tile columns before tile rows.
      local_index = local_col * CONV_OUTPUT_SIZE + local_row;
      expected_output_value = const_feat_out_batch[tile_index][local_index];
    end
  endfunction

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
  logic in_inverse_d;
  int conv_inverse_check_idx;
  int output_error_count;
  int write_count;
  int output_out_of_range_count;
  int input_out_of_range_count;
  int cycle_count;

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

  // Keep the testbench memory path identical to the hardware interface:
  // input samples come from a ROM instance and output partial sums are read
  // and written through a RAM instance. Address-range checks remain in the
  // monitor below so an invalid DUT address is reported without indexing the
  // verification mirror.
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
      in_inverse_d <= 1'b0;
      conv_inverse_check_idx <= 0;
      output_error_count <= 0;
      write_count <= 0;
      output_out_of_range_count <= 0;
      input_out_of_range_count <= 0;
      cycle_count <= 0;
    end else begin
      cycle_count <= cycle_count + 1;
      in_inverse_d <= (dut.st_conv_current == ST_CONV_INVERSE);
      if ((dut.st_conv_current == ST_CONV_INVERSE) && !in_inverse_d)
        conv_inverse_check_idx <= conv_inverse_check_idx + 1;

      if (p_output_en && p_output_wr) begin
        write_count <= write_count + 1;
        if (p_output_addr < OUTPUT_MEMORY_SIZE) begin
          output_bank[p_output_addr] <= p_output_data_write;
          if ((dut.r_output_channel_counter_input == (N_CHANNEL_IN - 1)) &&
              ($signed(p_output_data_write) !=
               $signed(expected_output_value(p_output_addr)))) begin
            output_error_count <= output_error_count + 1;
            if (output_error_count < 8)
              $display("ERROR WRITE GOLDEN: time=%0t addr=%0d got=%0d expected=%0d",
                       $realtime, p_output_addr, $signed(p_output_data_write),
                       expected_output_value(p_output_addr));
          end
        end else begin
          output_out_of_range_count <= output_out_of_range_count + 1;
          if (output_out_of_range_count < 8)
            $display("ERROR WRITE ADDRESS OUT OF RANGE: time=%0t addr=%0d data=%0d",
                     $realtime, p_output_addr, $signed(p_output_data_write));
        end
      end
      if (p_input_en && (p_input_addr >= INPUT_MEMORY_SIZE))
        input_out_of_range_count <= input_out_of_range_count + 1;
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

    if (output_out_of_range_count != 0)
      $fatal(1, "output address out of range: %0d", output_out_of_range_count);
    $display("input samples clipped: %0d", input_out_of_range_count);
    if (write_count != N_CHANNEL_IN * N_CHANNEL_OUT *
                       FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE)
      $fatal(1, "unexpected write count: got %0d", write_count);

    if (output_error_count != 0)
      $fatal(1, "output golden mismatch count: %0d", output_error_count);
    if (conv_inverse_check_idx != EXPECTED_INVERSE_COUNT)
      $fatal(1, "unexpected inverse count: got %0d expected %0d",
             conv_inverse_check_idx, EXPECTED_INVERSE_COUNT);
    $display("4x4 simulation passed: inverse_tiles=%0d cycles=%0d writes=%0d input samples clipped=%0d",
             conv_inverse_check_idx, cycle_count, write_count,
             input_out_of_range_count);
    $finish;
  end
endmodule
