`timescale 1ns/1ps

module tb;
  import pack_data::*;
  import pack_param::*;
  import pack_mux_mult::*;

  // Match the 2 ns (500 MHz) clock constrained by the ASIC Genus SDC.
  localparam time CLOCK_PERIOD = 2ns;
  localparam real CLOCK_PERIOD_NS = 2.0;

  // Parâmetros do DUT

  // localparam int unsigned KERNEL_SIZE  =  6;
  localparam int unsigned FEAT_INPUT_WIDTH = FEAT_INPUT_SIZE;
  // localparam int unsigned CONV_MULTIPLY_STEPS = 6;
  localparam int unsigned NBITS = 20;
  localparam int unsigned LATENCY = 1;
  localparam int unsigned ROM = 1;

  localparam int unsigned INPUT_MEMORY_SIZE  = N_CHANNEL_IN*FEAT_INPUT_SIZE*FEAT_INPUT_WIDTH + N_CHANNEL_OUT*N_CHANNEL_IN*HADAMARD_SIZE*HADAMARD_SIZE;
  localparam int unsigned OUTPUT_MEMORY_SIZE = FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT - 1;
  localparam int unsigned INPUT_ADDR_WIDTH   = $clog2(INPUT_MEMORY_SIZE);
  localparam int unsigned OUTPUT_ADDR_WIDTH  = $clog2(OUTPUT_MEMORY_SIZE);
`ifdef GATE_LEVEL
  // The mapped netlist uses the fixed NADDR=16 interface from list-define.txt.
  localparam int unsigned NADDR = 16;
`else
  localparam int unsigned NADDR = (INPUT_ADDR_WIDTH > OUTPUT_ADDR_WIDTH) ? INPUT_ADDR_WIDTH : OUTPUT_ADDR_WIDTH;
`endif

  // Sinais de interface
  logic clk;
  logic reset;
  logic p_start, p_end;
  logic p_input_en;
  logic [NADDR-1:0] p_input_addr;
  logic [19:0] p_input_data;
  logic [NBITS-1:0] p_input_data_write;
  logic p_input_valid;
  logic p_input_valid_mem;
  logic p_output_en;
  logic p_output_wr;
  logic [NADDR-1:0] p_output_addr;
  logic [NBITS-1:0] p_output_data_write;
  logic [NBITS-1:0] p_output_data_read;
  logic p_output_valid;
  int conv_inverse_check_idx;
  int output_error_count;
  int write_count;
  int cycle_count;
  realtime job_start_time;
  realtime job_end_time;
  realtime job_execution_time;
  int job_execution_cycles;
  logic job_active;
  logic [NBITS-1:0] output_bank [0:FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT - 1];
  logic output_bank_written [0:FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT - 1];
  logic in_inverse_d;
  localparam logic [1:0] ST_CONV_INVERSE = 2'b11;
  localparam int OUTPUT_TILES_PER_AXIS = (FEAT_OUTPUT_SIZE + CONV_OUTPUT_SIZE - 1) / CONV_OUTPUT_SIZE;
  localparam int WINDOW_COUNT_PER_COLUMN_TB = OUTPUT_TILES_PER_AXIS;
  localparam int OUTPUT_CHANNEL_STRIDE = FEAT_OUTPUT_SIZE * CONV_OUTPUT_SIZE * OUTPUT_TILES_PER_AXIS;
  localparam int WINDOW_COUNT_PER_CHANNEL_TB = OUTPUT_TILES_PER_AXIS * OUTPUT_TILES_PER_AXIS;
  localparam int EXPECTED_OUTPUT_VALUES = FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE * N_CHANNEL_OUT;
  localparam int OUTPUT_MEMORY_INDEX_WIDTH = $clog2(
    FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT);

  assign p_input_data_write = '0;

  // Instanciação do Módulo (DUT)
  // RTL simulation uses parameter overrides; the mapped gate-level top is
  // already elaborated with those values and has no parameter interface.
`ifdef GATE_LEVEL
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
    .NUM_MULT(NUM_MULT),
    .STATE_MULT(STATE_MULT)
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

  // assign p_input_valid = p_input_en;

  // Generate the same 500 MHz clock used by the Genus constraints.
  initial clk = 0;
  always #(CLOCK_PERIOD / 2) clk = ~clk;

  // Capture writes from the external interface. Final output validation runs
  // after p_end so it does not depend on internal RTL names in mapped netlists.
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      conv_inverse_check_idx <= 0;
      output_error_count <= 0;
      write_count <= 0;
      cycle_count <= 0;
      job_active <= 1'b0;
      in_inverse_d <= 1'b0;
      output_bank <= '{default: '0};
      output_bank_written <= '{default: 1'b0};
    end else begin
      if (p_start && !job_active) begin
        cycle_count <= 0;
        job_active <= 1'b1;
      end else if (job_active) begin
        cycle_count <= cycle_count + 1;
        if (p_end)
          job_active <= 1'b0;
      end
`ifndef GATE_LEVEL
      in_inverse_d <= (dut.st_conv_current == ST_CONV_INVERSE);
      if (dut.st_conv_current == 2'b10 && conv_inverse_check_idx < 1)
        $display("DBG BASE TC HAD row=%0d p=%0d,%0d,%0d,%0d,%0d", dut.r_conv_multiply_count, $signed(dut.w_conv_product[0]), $signed(dut.w_conv_product[1]), $signed(dut.w_conv_product[2]), $signed(dut.w_conv_product[3]), $signed(dut.w_conv_product[4]));
      if (dut.st_conv_current == 2'b11 && !in_inverse_d && conv_inverse_check_idx < 1)
        $display("DBG BASE TC INV got=%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d exp=%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d", $signed(dut.w_conv_inverse[0]), $signed(dut.w_conv_inverse[1]), $signed(dut.w_conv_inverse[2]), $signed(dut.w_conv_inverse[3]), $signed(dut.w_conv_inverse[4]), $signed(dut.w_conv_inverse[5]), $signed(dut.w_conv_inverse[6]), $signed(dut.w_conv_inverse[7]), $signed(dut.w_conv_inverse[8]), $signed(const_feat_out_batch[0][0]), $signed(const_feat_out_batch[0][1]), $signed(const_feat_out_batch[0][2]), $signed(const_feat_out_batch[0][3]), $signed(const_feat_out_batch[0][4]), $signed(const_feat_out_batch[0][5]), $signed(const_feat_out_batch[0][6]), $signed(const_feat_out_batch[0][7]), $signed(const_feat_out_batch[0][8]));

      if ((dut.st_conv_current == ST_CONV_INVERSE) && !in_inverse_d) begin
        if (conv_inverse_check_idx < 1)
          $display("BASE INV %0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d", $signed(dut.w_conv_inverse[0]), $signed(dut.w_conv_inverse[1]), $signed(dut.w_conv_inverse[2]), $signed(dut.w_conv_inverse[3]), $signed(dut.w_conv_inverse[4]), $signed(dut.w_conv_inverse[5]), $signed(dut.w_conv_inverse[6]), $signed(dut.w_conv_inverse[7]), $signed(dut.w_conv_inverse[8]));
        if (conv_inverse_check_idx < $size(const_feat_out_batch)) begin
          for (int k = 0; k < CONV_OUTPUT_SIZE * CONV_OUTPUT_SIZE; k++) begin
            if ($signed(dut.w_conv_inverse[k]) != $signed(const_feat_out_batch[conv_inverse_check_idx][k])) begin
              // $display("ERROR INVERSE[%0d] idx=%0d expected=%0d got=%0d time=%0t",
              //          k, conv_inverse_check_idx, const_feat_out_batch[conv_inverse_check_idx][k], $signed(dut.w_conv_inverse[k]), $realtime);
            end
          end
        end
        else begin
          // $display("ERROR: conv_inverse_check_idx overflow idx=%0d time=%0t", conv_inverse_check_idx, $realtime);
        end
        conv_inverse_check_idx <= conv_inverse_check_idx + 1;
      end
`endif

      if (p_output_en && p_output_wr) begin
        int output_channel;
        int addr_in_channel;

        write_count <= write_count + 1;
        output_channel = int'(p_output_addr) / OUTPUT_CHANNEL_STRIDE;
        addr_in_channel = int'(p_output_addr) % OUTPUT_CHANNEL_STRIDE;
        if (int'(p_output_addr) < EXPECTED_OUTPUT_VALUES) begin
          output_bank[OUTPUT_MEMORY_INDEX_WIDTH'(p_output_addr)] <= p_output_data_write;
          output_bank_written[OUTPUT_MEMORY_INDEX_WIDTH'(p_output_addr)] <= 1'b1;
        end else begin
          output_error_count <= output_error_count + 1;
          $display("ERROR WRITE ADDR OOB: t=%0t addr=%0d ch=%0d off=%0d",
                   $realtime, p_output_addr, output_channel, addr_in_channel);
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

    // Keep the original two reset cycles and eight idle cycles before start.
    repeat (2) @(negedge clk);
    reset = 0;
    repeat (8) @(negedge clk);
    p_start = 1;
    @(posedge clk);
    job_start_time = $realtime;
    @(negedge clk);
    p_start = 0;

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

    // Let the final output-memory write settle, then compare the complete
    // final output image through the testbench memory model only.
    repeat (20) @(posedge clk);

    begin
      int final_golden_error_count;
      final_golden_error_count = 0;
      for (int addr = 0; addr < EXPECTED_OUTPUT_VALUES; addr++) begin
        if (!output_bank_written[addr]) begin
          final_golden_error_count++;
          if (final_golden_error_count <= 8)
            $display("ERROR MISSING OUTPUT: addr=%0d", addr);
        end else if ($signed(output_bank[addr]) != $signed(NBITS'(const_feat_out[addr]))) begin
          final_golden_error_count++;
          if (final_golden_error_count <= 8)
            $display("ERROR FINAL GOLDEN: addr=%0d got=%0d expected=%0d",
                     addr, $signed(output_bank[addr]), $signed(NBITS'(const_feat_out[addr])));
        end
      end

      $display("Simulacao finalizada em %0t", $realtime);
      $display("Total de erros de escrita de output: %0d", output_error_count + final_golden_error_count);
      if (write_count != N_CHANNEL_IN * N_CHANNEL_OUT * FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE)
        $fatal(1, "unexpected valid write count: got %0d", write_count);
      if (output_error_count + final_golden_error_count != 0)
        $fatal(1, "output golden mismatch count: %0d", output_error_count + final_golden_error_count);
`ifdef GATE_LEVEL
      $display("3x3 simulation completed: inverse_tiles=%0d cycles=%0d valid_writes=%0d input_samples_clipped=0 invalid_output_beats=%0d",
               write_count / (CONV_OUTPUT_SIZE * CONV_OUTPUT_SIZE), cycle_count, write_count, output_error_count);
`else
      $display("3x3 simulation completed: inverse_tiles=%0d cycles=%0d valid_writes=%0d input_samples_clipped=0 invalid_output_beats=%0d",
               conv_inverse_check_idx, cycle_count, write_count, output_error_count);
`endif
    end
    $finish;
  end

endmodule
