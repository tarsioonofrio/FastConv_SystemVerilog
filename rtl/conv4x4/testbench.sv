`timescale 1ns/1ps

module tb;
  import pack_data::*;
  import pack_param::*;
  import pack_mux_mult::*;

  localparam int unsigned FEAT_INPUT_WIDTH = FEAT_INPUT_SIZE;
  localparam int unsigned NBITS = 20;
  localparam int unsigned LATENCY = 1;
  localparam int unsigned ROM = 1;
  localparam int unsigned INPUT_MEMORY_SIZE = $size(const_data);
  localparam int unsigned OUTPUT_TILES_PER_AXIS = (FEAT_OUTPUT_SIZE + CONV_OUTPUT_SIZE - 1) / CONV_OUTPUT_SIZE;
  localparam int unsigned OUTPUT_PHYSICAL_SIZE = OUTPUT_TILES_PER_AXIS * CONV_OUTPUT_SIZE;
  localparam int unsigned OUTPUT_MEMORY_SIZE = OUTPUT_PHYSICAL_SIZE * OUTPUT_PHYSICAL_SIZE * N_CHANNEL_OUT;
  localparam int unsigned INPUT_ADDR_WIDTH = $clog2(INPUT_MEMORY_SIZE);
  localparam int unsigned OUTPUT_ADDR_WIDTH = $clog2(OUTPUT_MEMORY_SIZE);
  localparam int unsigned NADDR = (INPUT_ADDR_WIDTH > OUTPUT_ADDR_WIDTH) ? INPUT_ADDR_WIDTH : OUTPUT_ADDR_WIDTH;
  localparam logic [1:0] ST_CONV_INVERSE = 2'b11;
  localparam int EXPECTED_INVERSE_COUNT = N_CHANNEL_IN * N_CHANNEL_OUT * OUTPUT_TILES_PER_AXIS * OUTPUT_TILES_PER_AXIS;

  logic clk;
  logic reset;
  logic p_start, p_end;
  logic p_input_en;
  logic [NADDR-1:0] p_input_addr;
  logic [NBITS-1:0] p_input_data;
  logic [NBITS-1:0] p_input_data_mem;
  logic input_sample_in_bounds;
  logic [NADDR-1:0] input_channel_offset;
  logic [NBITS-1:0] p_input_data_write;
  logic p_input_valid;
  logic p_output_en;
  logic p_output_wr;
  logic [NADDR-1:0] p_output_addr;
  logic [NBITS-1:0] p_output_data_write;
  logic [NBITS-1:0] p_output_data_read;
  logic p_output_valid;

  function automatic bit output_pixel_in_bounds(input int unsigned address);
    int unsigned channel_offset;
    int unsigned row;
    int unsigned col;
    begin
      channel_offset = address % (OUTPUT_PHYSICAL_SIZE * OUTPUT_PHYSICAL_SIZE);
      row = channel_offset / OUTPUT_PHYSICAL_SIZE;
      col = channel_offset % OUTPUT_PHYSICAL_SIZE;
      output_pixel_in_bounds = (address < OUTPUT_MEMORY_SIZE) &&
                               (row < FEAT_OUTPUT_SIZE) &&
                               (col < FEAT_OUTPUT_SIZE);
    end
  endfunction

  function automatic int logical_output_address(input int unsigned address);
    int unsigned channel_offset;
    int unsigned channel;
    int unsigned row;
    int unsigned col;
    begin
      channel = address / (OUTPUT_PHYSICAL_SIZE * OUTPUT_PHYSICAL_SIZE);
      channel_offset = address % (OUTPUT_PHYSICAL_SIZE * OUTPUT_PHYSICAL_SIZE);
      row = channel_offset / OUTPUT_PHYSICAL_SIZE;
      col = channel_offset % OUTPUT_PHYSICAL_SIZE;
      logical_output_address = channel * FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE +
                               row * FEAT_OUTPUT_SIZE + col;
    end
  endfunction

  function automatic int expected_output_value(input int unsigned address);
    expected_output_value = const_feat_out[logical_output_address(address)];
  endfunction

  int conv_inverse_check_idx;
  int output_error_count;
  int output_out_of_range_count;
  int input_out_of_range_count;
  int write_count;
  int cycle_count;
  logic [NBITS-1:0] output_bank [0:OUTPUT_MEMORY_SIZE - 1];
  logic in_inverse_d;

  assign p_input_data_write = '0;
  // Remove the channel base before checking the physical feature-map bounds.
  assign input_channel_offset = dut.r_input_addr_feat % (FEAT_INPUT_SIZE * FEAT_INPUT_WIDTH);
  // r_input_addr_feat already points at the row selected by the current
  // READ_IN_6* state.  Do not add w_input_base_feat a second time here: that
  // falsely clipped rows 4 and 5 of every 6x6 tile.
  assign input_sample_in_bounds = (CONV_OUTPUT_SIZE == 4) ?
      (((input_channel_offset % FEAT_INPUT_WIDTH) + dut.r_input_addr_count < FEAT_INPUT_WIDTH) &&
       ((input_channel_offset / FEAT_INPUT_WIDTH) < FEAT_INPUT_SIZE) &&
       ((dut.r_input_addr_feat / (FEAT_INPUT_SIZE * FEAT_INPUT_WIDTH)) == dut.r_input_channel_counter_input)) : 1'b1;
  assign p_input_data = input_sample_in_bounds ? p_input_data_mem : '0;

  Conv #(
    .N_CHANNEL_IN(N_CHANNEL_IN), .N_CHANNEL_OUT(N_CHANNEL_OUT),
    .FEAT_INPUT_SIZE(FEAT_INPUT_SIZE), .FEAT_INPUT_WIDTH(FEAT_INPUT_SIZE),
    .NADDR(NADDR), .NBITS(NBITS), .QUANT(QUANT_BITS),
    .CONV_OUTPUT_SIZE(CONV_OUTPUT_SIZE), .CONV_INPUT_SIZE(CONV_INPUT_SIZE),
    .HADAMARD_SIZE(HADAMARD_SIZE), .NUM_MULT(NUM_MULT), .STATE_MULT(STATE_MULT)
  ) dut (
    .clk(clk), .reset(reset), .p_start(p_start), .p_input_en(p_input_en),
    .p_input_addr(p_input_addr), .p_input_data(p_input_data),
    .p_input_valid(p_input_valid), .p_output_en(p_output_en),
    .p_output_wr(p_output_wr), .p_output_addr(p_output_addr),
    .p_output_data_write(p_output_data_write), .p_output_data_read(p_output_data_read),
    .p_output_valid(p_output_valid), .p_end(p_end)
  );

  Memory #(.NADDR(NADDR), .NBITS(NBITS), .LATENCY(LATENCY), .ROM(0)) memory_output (
    .clk(clk), .reset(reset), .chip_en(p_output_en),
    .wr_en(p_output_wr && output_pixel_in_bounds(p_output_addr)),
    .address(p_output_addr), .data_in(p_output_data_write),
    .data_out(p_output_data_read), .data_valid(p_output_valid)
  );

  Memory #(.NADDR(NADDR), .NBITS(NBITS), .LATENCY(LATENCY), .ROM(ROM)) memory_input (
    .clk(clk), .reset(reset), .chip_en(p_input_en), .wr_en(1'b0),
    .address(p_input_addr), .data_in(p_input_data_write),
    .data_out(p_input_data_mem), .data_valid(p_input_valid)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  // Validate inverse transitions and all valid writes through the Memory instances.
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      conv_inverse_check_idx <= 0;
      output_error_count <= 0;
      output_out_of_range_count <= 0;
      input_out_of_range_count <= 0;
      write_count <= 0;
      cycle_count <= 0;
      in_inverse_d <= 1'b0;
      output_bank <= '{default: '0};
    end else begin
      cycle_count <= cycle_count + 1;
      in_inverse_d <= (dut.st_conv_current == ST_CONV_INVERSE);
      if ((dut.st_conv_current == ST_CONV_INVERSE) && !in_inverse_d)
        conv_inverse_check_idx <= conv_inverse_check_idx + 1;
      if (p_input_en && !input_sample_in_bounds)
        input_out_of_range_count <= input_out_of_range_count + 1;
      if (p_output_en && p_output_wr) begin
        if (output_pixel_in_bounds(p_output_addr)) begin
          write_count <= write_count + 1;
          output_bank[p_output_addr] <= p_output_data_write;
          if ((dut.r_output_channel_counter_input == (N_CHANNEL_IN - 1)) &&
              ($signed(p_output_data_write) != $signed(expected_output_value(p_output_addr)))) begin
            output_error_count <= output_error_count + 1;
            if (output_error_count < 8)
              $display("ERROR WRITE GOLDEN: time=%0t addr=%0d got=%0d expected=%0d",
                       $realtime, p_output_addr, $signed(p_output_data_write),
                       expected_output_value(p_output_addr));
          end
        end else begin
          output_out_of_range_count <= output_out_of_range_count + 1;
        end
      end
    end
  end

  initial begin
    // $dumpfile("dump.vcd");
    // $dumpvars(0, tb);
`ifdef XRUN
    $shm_open("dut.shm");
    $shm_probe(tb.dut, "ASM");
`endif
    reset = 1;
    p_start = 0;
    #20 reset = 0;
    #80 p_start = 1;
    #10 p_start = 0;
    if (p_end !== 1'b1)
      @(posedge p_end);
    #200;
    if (output_error_count != 0)
      $fatal(1, "output golden mismatch count: %0d", output_error_count);
    if (conv_inverse_check_idx != EXPECTED_INVERSE_COUNT)
      $fatal(1, "unexpected inverse count: got %0d expected %0d",
             conv_inverse_check_idx, EXPECTED_INVERSE_COUNT);
    if (write_count != N_CHANNEL_IN * N_CHANNEL_OUT * FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE)
      $fatal(1, "unexpected valid write count: got %0d", write_count);
    $display("4x4 simulation passed: inverse_tiles=%0d cycles=%0d valid_writes=%0d input_samples_clipped=%0d invalid_output_beats=%0d",
             conv_inverse_check_idx, cycle_count, write_count,
             input_out_of_range_count, output_out_of_range_count);
    $finish;
  end
endmodule
