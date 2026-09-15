// Deterministic non-zero workload for post-implementation SAIF capture.
// The ROM contents come from the canonical generated pack_data package.
module tb_power #(
  parameter int unsigned JOBS = 1
);
  import pack_data::*;
  import pack_param::*;

  localparam int unsigned NBITS = 20;
  localparam int unsigned NADDR = 16;
  localparam int unsigned LATENCY = 1;
  localparam int unsigned ROM = 1;
  localparam int unsigned OUTPUT_MEMORY_SIZE = FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE * N_CHANNEL_OUT;
  localparam int unsigned WORKLOAD_SEED = 1;

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

  longint unsigned cycle_counter;
  longint unsigned launch_cycle;
  longint unsigned previous_end_cycle;
  longint unsigned latency_cycles;
  longint unsigned initiation_interval_cycles;
  longint unsigned previous_tile_end_cycle;
  longint unsigned tile_initiation_interval_cycles;
  integer tile_end_count;
  logic tile_end_d;
  integer jobs_completed;

  always #5 clk = ~clk;

`ifdef GATE_LEVEL
  // The routed Vivado netlist has no parameter interface.
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

  Memory #(.NADDR(NADDR), .NBITS(NBITS), .LATENCY(LATENCY), .ROM(ROM)) memory_input (
    .clk(clk), .reset(reset), .chip_en(p_input_en), .wr_en(1'b0),
    .address(p_input_addr), .data_in('0), .data_out(p_input_data),
    .data_valid(p_input_valid)
  );

  Memory #(.NADDR(NADDR), .NBITS(NBITS), .LATENCY(LATENCY), .ROM(0)) memory_output (
    .clk(clk), .reset(reset), .chip_en(p_output_en), .wr_en(p_output_wr),
    .address(p_output_addr), .data_in(p_output_data_write),
    .data_out(p_output_data_read), .data_valid(p_output_valid)
  );

  always_ff @(posedge clk) begin
    if (reset) begin
      cycle_counter <= 0;
      launch_cycle <= 0;
      previous_end_cycle <= 0;
      latency_cycles <= 0;
      initiation_interval_cycles <= 0;
      previous_tile_end_cycle <= 0;
      tile_initiation_interval_cycles <= 0;
      tile_end_count <= 0;
      tile_end_d <= 1'b0;
      jobs_completed <= 0;
    end else begin
      cycle_counter <= cycle_counter + 1;
      if (p_start)
        launch_cycle <= cycle_counter;
      if (p_end) begin
        latency_cycles <= cycle_counter - launch_cycle;
        if (jobs_completed > 0)
          initiation_interval_cycles <= cycle_counter - previous_end_cycle;
        previous_end_cycle <= cycle_counter;
        jobs_completed <= jobs_completed + 1;
      end
      tile_end_d <= dut.w_conv_end;
      if (dut.w_conv_end && !tile_end_d) begin
        if (tile_end_count > 0)
          tile_initiation_interval_cycles <= cycle_counter - previous_tile_end_cycle;
        previous_tile_end_cycle <= cycle_counter;
        tile_end_count <= tile_end_count + 1;
      end
    end
  end

  task automatic launch_job;
    begin
      #80;
      p_start = 1'b1;
      #10;
      p_start = 1'b0;
      @(posedge p_end);
      #10;
    end
  endtask

  initial begin
`ifdef POWER_DUMP
    $dumpfile("tb_power.vcd");
    $dumpvars(0, tb_power);
`endif
    #20 reset = 1'b0;
    for (int job = 0; job < JOBS; job++) begin
      launch_job();
      repeat (2) @(negedge clk);
    end
    $display("POWER_WORKLOAD seed=%0d jobs=%0d latency_cycles=%0d ii_cycles=%0d tile_ends=%0d tile_ii_cycles=%0d", WORKLOAD_SEED,
             jobs_completed, latency_cycles, initiation_interval_cycles, tile_end_count,
             tile_inlabelsitiation_interval_cycles);
    $display("POWER_WORKLOAD_END");
    $finish;
  end
endmodule
