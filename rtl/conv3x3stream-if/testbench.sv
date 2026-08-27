`timescale 1ns/1ps

module tb #(
  parameter int unsigned NUM_MULT = 6,
  parameter int unsigned STATE_MULT = 6
);
  // Shared testbench for the fixed IF3x3 streaming variants.
  import pack_data::*;
  import pack_param::*;

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
  localparam int unsigned NADDR              = (INPUT_ADDR_WIDTH > OUTPUT_ADDR_WIDTH) ? INPUT_ADDR_WIDTH : OUTPUT_ADDR_WIDTH;

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
  int cycle_count;
  int core_cycle_count;
  int output_error_count;
  logic [NBITS-1:0] output_bank [0:FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT - 1];
  logic in_inverse_d;
  localparam logic [1:0] ST_CONV_INVERSE = 2'b11;
  localparam int OUTPUT_TILES_PER_AXIS = (FEAT_OUTPUT_SIZE + CONV_OUTPUT_SIZE - 1) / CONV_OUTPUT_SIZE;
  localparam int WINDOW_COUNT_PER_COLUMN_TB = OUTPUT_TILES_PER_AXIS;
  localparam int OUTPUT_CHANNEL_STRIDE = FEAT_OUTPUT_SIZE * CONV_OUTPUT_SIZE * OUTPUT_TILES_PER_AXIS;
  localparam int WINDOW_COUNT_PER_CHANNEL_TB = OUTPUT_TILES_PER_AXIS * OUTPUT_TILES_PER_AXIS;

  assign p_input_data_write = '0;

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

  // assign p_input_valid = p_input_en;

  // Gerador de Clock: 100MHz -> Período de 10ns
  initial clk = 0;
  always #5 clk = ~clk;

  // Validate each inverse output window against golden batch data.
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      conv_inverse_check_idx <= 0;
      cycle_count <= 0;
      core_cycle_count <= 0;
      output_error_count <= 0;
      in_inverse_d <= 1'b0;
      output_bank <= '{default: '0};
    end else begin
      cycle_count <= cycle_count + 1;
      if (dut.st_conv_current != 2'b00)
        core_cycle_count <= core_cycle_count + 1;
      in_inverse_d <= (dut.st_conv_current == ST_CONV_INVERSE);

      if ((dut.st_conv_current == ST_CONV_INVERSE) && !in_inverse_d) begin
        if (conv_inverse_check_idx < $size(const_feat_out_batch)) begin
          for (int k = 0; k < CONV_OUTPUT_SIZE * CONV_OUTPUT_SIZE; k++) begin
            if ($signed(dut.w_stream_final_output[k]) != $signed(const_feat_out_batch[conv_inverse_check_idx][k])) begin
              // $display("ERROR INVERSE[%0d] idx=%0d expected=%0d got=%0d time=%0t",
              //          k, conv_inverse_check_idx, const_feat_out_batch[conv_inverse_check_idx][k], $signed(dut.w_stream_final_output[k]), $realtime);
            end
          end
        end
        else begin
          // $display("ERROR: conv_inverse_check_idx overflow idx=%0d time=%0t", conv_inverse_check_idx, $realtime);
        end
        conv_inverse_check_idx <= conv_inverse_check_idx + 1;
      end

      if (p_output_en && p_output_wr) begin
        int output_channel;
        int addr_in_channel;
        logic signed [NBITS-1:0] expected_accum;
        logic [NBITS-1:0] expected_out;


        expected_accum = $signed(p_output_data_read) + $signed(dut.r_output_write[dut.r_output_write_count]);

        output_bank[p_output_addr] <= p_output_data_write;
        output_channel = int'(p_output_addr) / OUTPUT_CHANNEL_STRIDE;
        addr_in_channel = int'(p_output_addr) % OUTPUT_CHANNEL_STRIDE;
        if (addr_in_channel < FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE) begin
          // Golden compare only on final accumulation write (last input channel).
          if (dut.r_output_channel_counter_input == (N_CHANNEL_IN - 1)) begin
            expected_out = NBITS'(const_feat_out[p_output_addr]);
            if ($signed(p_output_data_write) != $signed(expected_out)) begin
              output_error_count <= output_error_count + 1;
              $display("ERROR WRITE GOLDEN: t=%0t addr=%0d ch=%0d off=%0d got=%0d exp=%0d accum_exp=%0d read=%0d inv=%0d",
                       $realtime, p_output_addr, output_channel, addr_in_channel, $signed(p_output_data_write),
                       $signed(expected_out), expected_accum, $signed(p_output_data_read),
                       $signed(dut.r_output_write[dut.r_output_write_count]));
            end
          end
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

    $display("Simulacao finalizada em %0t", $realtime);
    $display("Inversas verificadas: %0d", conv_inverse_check_idx);
    $display("Ciclos de sistema: %0d", cycle_count);
    $display("Ciclos ativos do core: %0d", core_cycle_count);
    $display("Total de erros de escrita de output: %0d", output_error_count);
    $finish;
  end

endmodule
