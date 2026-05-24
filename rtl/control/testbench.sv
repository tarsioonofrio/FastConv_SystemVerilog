`timescale 1ns/1ps

module tb;
  import pack_data::*;
  import pack_param::*;
  import pack_mux_mult::*;

  // Parâmetros do DUT

  // localparam int unsigned KERNEL_SIZE  =  6;
  localparam int unsigned FEAT_INPUT_WIDTH = FEAT_INPUT_SIZE;
  // localparam int unsigned CONV_MULTIPLY_STEPS = 6;
  localparam int unsigned NBITS = 20;

  localparam int unsigned INPUT_MEMORY_SIZE = N_CHANNEL_IN*FEAT_INPUT_SIZE*FEAT_INPUT_WIDTH + N_CHANNEL_OUT*N_CHANNEL_IN*HADAMARD_SIZE*HADAMARD_SIZE;

  localparam int unsigned INPUT_MEMORY_INIT_SIZE = 1083;
  localparam int unsigned NADDR     = 16;

  // Sinais de interface
  logic clk;
  logic reset;
  logic p_start, p_end;
  logic p_input_en;
  logic [NADDR-1:0] p_input_addr;
  logic [19:0] p_input_data;
  logic p_input_valid;
  logic p_output_en;
  logic p_output_wr;
  logic [NADDR-1:0] p_output_addr;
  logic [NBITS-1:0] p_output_data_write;
  logic [NBITS-1:0] p_output_data_read;
  logic p_output_valid;
  int input_addr_idx;
  int conv_inverse_check_idx;
  int output_error_count;
  logic [NBITS-1:0] output_bank [0:FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT - 1];
  logic [NBITS-1:0] const_feat_out_linear [0:FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE - 1];
  logic in_inverse_d;
  localparam logic [1:0] ST_CONV_INVERSE = 2'b11;
  localparam int OUTPUT_TILES_PER_AXIS = (FEAT_OUTPUT_SIZE + CONV_OUTPUT_SIZE - 1) / CONV_OUTPUT_SIZE;
  localparam int OUTPUT_CHANNEL_STRIDE = FEAT_OUTPUT_SIZE * CONV_OUTPUT_SIZE * OUTPUT_TILES_PER_AXIS;

  // Reads directly from the dataset package memory image.
  always_comb begin
    input_addr_idx = int'(p_input_addr);
    if (input_addr_idx < INPUT_MEMORY_SIZE)
      p_input_data = NBITS'(const_data[input_addr_idx]);
    else
      p_input_data = '0;
  end
  always_comb begin
    if (int'(p_output_addr) < $size(output_bank))
      p_output_data_read = output_bank[p_output_addr];
    else
      p_output_data_read = '0;
  end
  assign p_input_valid = 1'b1;
  assign p_output_valid = 1'b1;

  // Instanciação do Módulo (DUT)
  Control #(
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

  // Gerador de Clock: 100MHz -> Período de 10ns
  initial clk = 0;
  always #5 clk = ~clk;

  // Validate each inverse output window against golden batch data.
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      conv_inverse_check_idx <= 0;
      output_error_count <= 0;
      in_inverse_d <= 1'b0;
      output_bank <= '{default: '0};
    end else begin
      in_inverse_d <= (dut.st_conv_current == ST_CONV_INVERSE);

      if ((dut.st_conv_current == ST_CONV_INVERSE) && !in_inverse_d) begin
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

      if (p_output_en && p_output_wr) begin
        int output_channel;
        int addr_in_channel;
        int output_linear_idx;
        logic signed [NBITS-1:0] expected_accum;
        logic [NBITS-1:0] expected_out;

        expected_accum = $signed(p_output_data_read) + $signed(dut.r_output_write[dut.r_output_write_count]);
        if ($signed(expected_accum) != $signed(p_output_data_write)) begin
          output_error_count <= output_error_count + 1;
          $display("ERROR WRITE ACCUM: t=%0t addr=%0d read=%0d partial=%0d exp=%0d got=%0d",
                   $realtime, p_output_addr, $signed(p_output_data_read),
                   $signed(dut.r_output_write[dut.r_output_write_count]),
                   $signed(expected_accum), $signed(p_output_data_write));
        end

        output_bank[p_output_addr] <= p_output_data_write;
        output_channel = int'(p_output_addr) / OUTPUT_CHANNEL_STRIDE;
        addr_in_channel = int'(p_output_addr) % OUTPUT_CHANNEL_STRIDE;
        output_linear_idx = output_channel * FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE + addr_in_channel;

        if (output_channel < N_CHANNEL_OUT && addr_in_channel < FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE) begin
          expected_out = const_feat_out_linear[addr_in_channel];
          // Golden check only when accumulation over input channels is complete.
          if (dut.r_input_channel_counter_input == dut.CHANNEL_INPUT_COUNTER_WIDTH'(N_CHANNEL_IN - 1)) begin
            if ($signed(expected_out) != $signed(p_output_data_write)) begin
              output_error_count <= output_error_count + 1;
              $display("ERROR WRITE GOLDEN: t=%0t addr=%0d ch=%0d off=%0d exp=%0d got=%0d",
                       $realtime, p_output_addr, output_channel, addr_in_channel,
                       $signed(expected_out), $signed(p_output_data_write));
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

    // Build linearized golden OFMAP for direct indexed access.
    for (int row = 0; row < FEAT_OUTPUT_SIZE; row++) begin
      for (int col = 0; col < FEAT_OUTPUT_SIZE; col++) begin
        const_feat_out_linear[row * FEAT_OUTPUT_SIZE + col] = NBITS'(const_feat_out[row][col]);
      end
    end

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
    $display("Total de erros de escrita de output: %0d", output_error_count);
    $finish;
  end

endmodule
