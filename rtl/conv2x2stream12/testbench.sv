`timescale 1ns/1ps

module tb;
  // This directory is the dedicated 12-register-word streaming variant.
  localparam bit STREAMING_CONV_MODE = 1'b1;
  import pack_data::*;
  import pack_param::*;
  import pack_mux_mult::*;

  // Parameters and memory dimensions are imported from the generated package.
  localparam int unsigned FEAT_INPUT_WIDTH = FEAT_INPUT_SIZE;
  localparam int unsigned NBITS = 20;
  localparam int unsigned LATENCY = 1;
  localparam int unsigned ROM = 1;
  localparam int unsigned INPUT_MEMORY_SIZE = $size(const_data);
  localparam int unsigned OUTPUT_MEMORY_SIZE = FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE * N_CHANNEL_OUT;
  localparam int unsigned INPUT_ADDR_WIDTH = $clog2(INPUT_MEMORY_SIZE);
  localparam int unsigned OUTPUT_ADDR_WIDTH = $clog2(OUTPUT_MEMORY_SIZE);
  localparam int unsigned NADDR = (INPUT_ADDR_WIDTH > OUTPUT_ADDR_WIDTH) ? INPUT_ADDR_WIDTH : OUTPUT_ADDR_WIDTH;

  localparam logic [1:0] ST_CONV_INVERSE = 2'b11;
  localparam int OUTPUT_TILES_PER_AXIS = (FEAT_OUTPUT_SIZE + CONV_OUTPUT_SIZE - 1) / CONV_OUTPUT_SIZE;
  localparam int EXPECTED_INVERSE_COUNT = N_CHANNEL_IN * N_CHANNEL_OUT * OUTPUT_TILES_PER_AXIS * OUTPUT_TILES_PER_AXIS;

  // Sinais de interface
  logic clk;
  logic reset;
  logic p_start, p_end;
  logic p_input_en;
  logic [NADDR-1:0] p_input_addr;
  logic [19:0] p_input_data;
  logic [NBITS-1:0] p_input_data_mem;
  logic input_sample_in_bounds;
  logic [NBITS-1:0] p_input_data_write;
  logic p_input_valid;
  logic p_output_en;
  logic p_output_wr;
  logic [NADDR-1:0] p_output_addr;
  logic [NBITS-1:0] p_output_data_write;
  logic [NBITS-1:0] p_output_data_read;
  logic p_output_valid;

  // Map a physical output address to the generated tile-major golden data.
  function automatic int expected_output_value(input int unsigned address);
    begin
      // The generated flat output follows the physical RAM address order
      // used by the controller.
      expected_output_value = const_feat_out[address];
    end
  endfunction
  int conv_inverse_check_idx;
  int output_error_count;
  int output_out_of_range_count;
  int input_out_of_range_count;
  int write_count;
  int cycle_count;
  int core_cycle_count;
  logic [NBITS-1:0] output_bank [0:FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT - 1];
  logic in_inverse_d;
  assign p_input_data_write = '0;
  assign input_sample_in_bounds = (CONV_OUTPUT_SIZE == 4) ?
      (((dut.r_input_addr_feat % FEAT_INPUT_WIDTH) + dut.r_input_addr_count < FEAT_INPUT_WIDTH) &&
       ((dut.r_input_addr_feat / FEAT_INPUT_WIDTH) + dut.w_input_base_feat < FEAT_INPUT_SIZE)) : 1'b1;
  assign p_input_data = input_sample_in_bounds ? p_input_data_mem : '0;

  // Instanciação do Módulo (DUT)
  Conv #(
    .N_CHANNEL_IN(N_CHANNEL_IN),
    .N_CHANNEL_OUT(N_CHANNEL_OUT),
    .FEAT_INPUT_SIZE(FEAT_INPUT_SIZE),
    .FEAT_INPUT_WIDTH(FEAT_INPUT_SIZE),
    .NADDR(NADDR),
    // .CONV_MULTIPLY_STEPS(CONV_MULTIPLY_STEPS),
    .NBITS(NBITS),
    .QUANT(QUANT_BITS),
    .CONV_OUTPUT_SIZE(CONV_OUTPUT_SIZE),
    .CONV_INPUT_SIZE(CONV_INPUT_SIZE),
    .HADAMARD_SIZE(HADAMARD_SIZE),
    .NUM_MULT(NUM_MULT),
    .STATE_MULT(STATE_MULT),
    .STREAMING_CONV(STREAMING_CONV_MODE)
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
    .wr_en(p_output_wr && (p_output_addr < OUTPUT_MEMORY_SIZE)),
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
    .data_out(p_input_data_mem),
    .data_valid(p_input_valid)
  );

  // assign p_input_valid = p_input_en;

  // Gerador de Clock: 100MHz -> Período de 10ns
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
      core_cycle_count <= 0;
      in_inverse_d <= 1'b0;
      output_bank <= '{default: '0};
    end else begin
      cycle_count <= cycle_count + 1;
      if (dut.st_conv_current != 2'b00)
        core_cycle_count <= core_cycle_count + 1;
      in_inverse_d <= (dut.st_conv_current == ST_CONV_INVERSE);
      if ((dut.st_conv_current == ST_CONV_INVERSE) && !in_inverse_d)
        conv_inverse_check_idx <= conv_inverse_check_idx + 1;
      if (p_input_en && !input_sample_in_bounds)
        input_out_of_range_count <= input_out_of_range_count + 1;
      if (p_output_en && p_output_wr) begin
        if (p_output_addr < OUTPUT_MEMORY_SIZE) begin
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

  // Estímulos
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);

    // Reset inicial (Ativo alto conforme código fonte)
    reset = 1;
    p_start = 0;

    // Mantém reset por 20 ns
    #20 reset = 0;

    #80 p_start = 1;
    #10 p_start = 0;

    // aguarda p_end subir
    if (p_end !== 1'b1)
          @(posedge p_end);

      // espera mais 200 ns
    #200;

    if (output_error_count != 0)
      $fatal(1, "output golden mismatch count: %0d", output_error_count);
    if (conv_inverse_check_idx != EXPECTED_INVERSE_COUNT)
      $fatal(1, "unexpected inverse count: got %0d expected %0d",
             conv_inverse_check_idx, EXPECTED_INVERSE_COUNT);
    if (write_count != N_CHANNEL_IN * N_CHANNEL_OUT * FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE)
      $fatal(1, "unexpected valid write count: got %0d", write_count);
    $display("2x2 simulation passed: inverse_tiles=%0d cycles=%0d valid_writes=%0d input_samples_clipped=%0d invalid_output_beats=%0d",
             conv_inverse_check_idx, cycle_count, write_count,
             input_out_of_range_count, output_out_of_range_count);
    $display("Core active cycles: %0d", core_cycle_count);
    $finish;
  end

endmodule
