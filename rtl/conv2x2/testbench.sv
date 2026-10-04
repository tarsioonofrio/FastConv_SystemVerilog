`timescale 1ns/1ps

module tb #(
  // The same testbench is used for the parameterized, fixed-streaming and
  // fully-parallel Conv sources. The DUT source supplies its own default when
  // this parameter is not overridden by a simulator or Make target.
  parameter int unsigned NUM_MULT = 4,
  parameter bit ALLOW_GOLDEN_MISMATCH = 1'b0
);
  import pack_data::*;
  import pack_param::*;

  // Parameters and memory dimensions are imported from the generated package.
  localparam int unsigned FEAT_INPUT_WIDTH = FEAT_INPUT_SIZE;
  localparam int unsigned NBITS = 20;
  localparam int unsigned LATENCY = 1;
  localparam int unsigned ROM = 1;
  localparam time CLOCK_PERIOD = 10ns;
  localparam real CLOCK_PERIOD_NS = 10.0;
  localparam int unsigned INPUT_MEMORY_SIZE = $size(const_data);
  localparam int unsigned OUTPUT_MEMORY_SIZE = FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE * N_CHANNEL_OUT;
  localparam int unsigned INPUT_ADDR_WIDTH = $clog2(INPUT_MEMORY_SIZE);
  localparam int unsigned OUTPUT_ADDR_WIDTH = $clog2(OUTPUT_MEMORY_SIZE);
  localparam int unsigned NADDR = (INPUT_ADDR_WIDTH > OUTPUT_ADDR_WIDTH) ? INPUT_ADDR_WIDTH : OUTPUT_ADDR_WIDTH;

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
  realtime job_start_time;
  realtime job_end_time;
  realtime job_execution_time;
  int job_execution_cycles;
  logic [NBITS-1:0] output_bank [0:FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT - 1];
  logic conv_end_d;
  logic [1:0] input_base_feat;
  assign p_input_data_write = '0;
`ifdef GATE_LEVEL
  // The mapped netlist may remove the RTL alias w_input_base_feat. Decode the
  // four input-row states directly so the same TB remains usable post-synthesis.
  always_comb begin
    case (dut.st_input_current)
      4'd3: input_base_feat = 2'd0; // READ_IN_10A
      4'd4: input_base_feat = 2'd1; // READ_IN_10B
      4'd5: input_base_feat = 2'd2; // READ_IN_8C
      4'd6: input_base_feat = 2'd3; // READ_IN_8D
      default: input_base_feat = 2'd0;
    endcase
  end
`else
  assign input_base_feat = dut.w_input_base_feat;
`endif
  assign input_sample_in_bounds = (CONV_OUTPUT_SIZE == 4) ?
      (((dut.r_input_addr_feat % FEAT_INPUT_WIDTH) + dut.r_input_addr_count < FEAT_INPUT_WIDTH) &&
       ((dut.r_input_addr_feat / FEAT_INPUT_WIDTH) + input_base_feat < FEAT_INPUT_SIZE)) : 1'b1;
  assign p_input_data = input_sample_in_bounds ? p_input_data_mem : '0;

  // Instanciação do Módulo (DUT)
`ifdef GATE_LEVEL
  // A mapped gate-level module has no parameter list; its dimensions are
  // already elaborated by synthesis. Keep the same instance name and ports
  // so the checking logic and SDF command file remain unchanged.
  Conv dut (
`else
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
    .NUM_MULT(NUM_MULT)
  ) dut (
`endif
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

  // Generate the 100 MHz clock used by the original 2x2 testbench.
  initial clk = 0;
  always #(CLOCK_PERIOD / 2) clk = ~clk;

  // Validate one completion event per tile and all valid writes through the
  // Memory instances. w_conv_end is the common contract across all variants;
  // no variant-specific FSM state is inspected here.
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      conv_inverse_check_idx <= 0;
      output_error_count <= 0;
      output_out_of_range_count <= 0;
      input_out_of_range_count <= 0;
      write_count <= 0;
      cycle_count <= 0;
      conv_end_d <= 1'b0;
      output_bank <= '{default: '0};
    end else begin
      cycle_count <= cycle_count + 1;
      conv_end_d <= dut.w_conv_end;
      if (dut.w_conv_end && !conv_end_d)
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
`ifdef XRUN
    $shm_open("dut.shm");
    $shm_probe(tb.dut, "ASM");
`endif

    // Reset inicial (Ativo alto conforme código fonte)
    reset = 1;
    p_start = 0;

    // Mantém reset por 20 ns
    #20 reset = 0;

    #80 p_start = 1;
    @(posedge clk);
    job_start_time = $realtime;
    #10 p_start = 0;

    // aguarda p_end subir
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

      // espera mais 200 ns
    #200;

    if ((output_error_count != 0) && !ALLOW_GOLDEN_MISMATCH)
      $fatal(1, "output golden mismatch count: %0d", output_error_count);
    if (conv_inverse_check_idx != EXPECTED_INVERSE_COUNT)
      $fatal(1, "unexpected inverse count: got %0d expected %0d",
             conv_inverse_check_idx, EXPECTED_INVERSE_COUNT);
    if (write_count != N_CHANNEL_IN * N_CHANNEL_OUT * FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE)
      $fatal(1, "unexpected valid write count: got %0d", write_count);
    $display("2x2 simulation completed: golden_mismatches=%0d inverse_tiles=%0d cycles=%0d valid_writes=%0d input_samples_clipped=%0d invalid_output_beats=%0d",
             output_error_count,
             conv_inverse_check_idx, cycle_count, write_count,
             input_out_of_range_count, output_out_of_range_count);
    if (output_error_count != 0)
      $display("GOLDEN_MISMATCHES_ALLOWED only for explicit approximation experiments");
    $finish;
  end

endmodule
