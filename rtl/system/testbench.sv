module tb;
  timeunit 1ns;
  timeprecision 1ps;

  import pack_def::*;
  import pack_data::*;
  import pack_param::*;
  import pack_typedef::*;

  logic clk;
  logic reset;

  logic p_start;
  logic p_end;

  logic w_input_en;
  logic w_input_wr;
  logic w_input_valid;
  logic[NADDR-1:0] w_input_addr;
  logic_vector w_input_data_write;
  logic_vector w_input_data_read;

  logic w_output_en;
  logic w_output_wr;
  logic w_output_valid;
  logic[NADDR-1:0] w_output_addr;
  logic_vector w_output_data_read;
  logic_vector w_output_data_write;

  int count_fout;
  int i = 0;
  int j = 0;
  int total_out_rows = 0;
  time t_start = 0;
  time t_end = 0;
  time t_total = 0;
  integer time_fd = 0;
  int cycle_count;
  int mem_input_reads;
  int mem_output_reads;
  int mem_output_writes;
  int error_count = 0;
  logic count_cycles;

  // Clock generation (10ns period)
  initial clk = 0;
  always #5 clk = ~clk;

  // Counters for cycles and memory transactions.
  always @(posedge clk) begin
    if (reset) begin
      cycle_count <= 0;
      mem_input_reads <= 0;
      mem_output_reads <= 0;
      mem_output_writes <= 0;
      count_cycles <= 0;
    end else begin
      if (p_start) begin
        cycle_count <= 0;
        mem_input_reads <= 0;
        mem_output_reads <= 0;
        mem_output_writes <= 0;
        count_cycles <= 1;
      end else if (count_cycles) begin
        cycle_count <= cycle_count + 1;
        if (w_input_en && w_input_valid) begin
          mem_input_reads <= mem_input_reads + 1;
        end
        if (w_output_en && !w_output_wr && w_output_valid) begin
          mem_output_reads <= mem_output_reads + 1;
        end
        if (w_output_en && w_output_wr) begin
          mem_output_writes <= mem_output_writes + 1;
        end
        if (p_end) begin
          count_cycles <= 0;
        end
      end
    end
  end

  // DUT instantiation
`ifdef GATE_LEVEL
  System dut (
    .clk(clk),
    .reset(reset),

    .p_start(p_start),
    .p_end(p_end),

    .p_input_en(w_input_en),
    .p_input_addr(w_input_addr),
    .p_input_valid(w_input_valid),
    .p_input_data(w_input_data_read),

    .p_output_en(w_output_en),
    .p_output_wr(w_output_wr),
    .p_output_addr(w_output_addr),
    .p_output_data_read(w_output_data_read),
    .p_output_data_write(w_output_data_write),
    .p_output_valid(w_output_valid)
  );
`else
  System #(
    .NADDR(NADDR),
    .NBITS(NBITS),
    .LATENCY(LATENCY),
    .ROM(ROM),
    .QUANT(QUANT) //,
    // .FEAT_INPUT_SIZE(FEAT_INPUT_SIZE),
    // .FEAT_OUTPUT_SIZE(FEAT_OUTPUT_SIZE),
    // .N_WINDOW(N_WINDOW),
    // .N_CHANNEL_IN(N_CHANNEL_IN),
    // .N_CHANNEL_OUT(N_CHANNEL_OUT),
    // .LAST_WINDOW(LAST_WINDOW)
  ) dut (
    .clk(clk),
    .reset(reset),

    .p_start(p_start),
    .p_end(p_end),

    .p_input_en(w_input_en),
    .p_input_addr(w_input_addr),
    .p_input_valid(w_input_valid),
    .p_input_data(w_input_data_read),

    .p_output_en(w_output_en),
    .p_output_wr(w_output_wr),
    .p_output_addr(w_output_addr),
    .p_output_data_read(w_output_data_read),
    .p_output_data_write(w_output_data_write),
    .p_output_valid(w_output_valid)
  );
`endif

  Memory #(
    .NADDR(NADDR),
    .NBITS(NBITS),
    .LATENCY(LATENCY),
    .ROM(ROM)
  ) memory_read(
    .clk(clk),
    .reset(reset),
    .chip_en(w_input_en),
    .wr_en(1'b0),
    .address(w_input_addr),
    .data_in(w_input_data_write),
    .data_out(w_input_data_read),
    .data_valid(w_input_valid)
  );

  Memory #(
    .NADDR(NADDR),
    .NBITS(NBITS),
    .LATENCY(LATENCY),
    .ROM(0)
  ) memory_write(
    .clk(clk),
    .reset(reset),
    .chip_en(w_output_en),
    .wr_en(w_output_wr),
    .address(w_output_addr),
    .data_in(w_output_data_write),
    .data_out(w_output_data_read),
    .data_valid(w_output_valid)
  );

  // Inicialização dos sinais e reset
  initial begin
`ifdef XRUN
    $shm_open("dut.shm");
    $shm_probe(tb.dut, "ASM");
`else
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);
`endif

    reset = 1;
    p_start = 0;
    @(posedge clk);
    reset = 0;
    p_start = 1;

    // Start processamento
    $display("=== Start processing ===");
    t_start = $realtime;

    @(posedge clk);
    p_start = 0;

    wait(p_end);

    $display("\n*** TIME %0f ***\n", $realtime);
    $display("\n*** TOTAL CYCLES %0d ***\n", cycle_count);
    $display("\n*** MEM INPUT READS %0d ***\n", mem_input_reads);
    $display("\n*** MEM OUTPUT READS %0d ***\n", mem_output_reads);
    $display("\n*** MEM OUTPUT WRITES %0d ***\n", mem_output_writes);
    t_end = $realtime;

    total_out_rows = FEAT_OUTPUT_SIZE * N_CHANNEL_OUT;
    for (i = 0; i < total_out_rows; i++) begin
      for (j = 0; j < FEAT_OUTPUT_SIZE; j++) begin
        logic_vector expected_out;
        logic_vector actual_out;

        expected_out = logic_vector'(const_feat_out[i][j]);
        actual_out = memory_write.data[i * FEAT_OUTPUT_SIZE + j];
        if ($signed(expected_out) != $signed(actual_out)) begin
          error_count++;
          $display("Time %0t | const_feat_out[%0d][%0d] = %0d | Output memory = %0d",
                   $time, i, j, const_feat_out[i][j], $signed(actual_out));
          $display("=== ERROR - End simulation ====");
        end
      end
    end

    t_total = t_end - t_start;
    time_fd = $fopen("sim.log", "w");
    if (time_fd) begin
      $fdisplay(time_fd, "Total execution time: %f", t_total);
      $fdisplay(time_fd, "Total cycles: %0d", cycle_count);
      $fdisplay(time_fd, "Memory input reads: %0d", mem_input_reads);
      $fdisplay(time_fd, "Memory output reads: %0d", mem_output_reads);
      $fdisplay(time_fd, "Memory output writes: %0d", mem_output_writes);
      $fclose(time_fd);
    end
    if (error_count == 0)
      $display("=== No errors - End simulation ===");
    else
      $display("=== ERROR - End simulation: %0d mismatches ====", error_count);
    $display("\n*** TIME %0f ***\n", $realtime);
    $display("\n*** TOTAL CYCLES %0d ***\n", cycle_count);
    $display("\n*** MEM INPUT READS %0d ***\n", mem_input_reads);
    $display("\n*** MEM OUTPUT READS %0d ***\n", mem_output_reads);
    $display("\n*** MEM OUTPUT WRITES %0d ***\n", mem_output_writes);
    $finish;
  end
endmodule
