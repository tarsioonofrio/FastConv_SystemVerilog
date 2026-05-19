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
  localparam int unsigned NADDR     = $clog2(INPUT_MEMORY_SIZE);

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
  logic in_inverse_d;
  localparam logic [1:0] ST_CONV_INVERSE = 2'b11;

  function automatic int f_transposed_index(input int idx);
    int row_idx;
    int col_idx;
    begin
      row_idx = idx / CONV_OUTPUT_SIZE;
      col_idx = idx % CONV_OUTPUT_SIZE;
      f_transposed_index = col_idx * CONV_OUTPUT_SIZE + row_idx;
    end
  endfunction

  // Reads directly from the dataset package memory image.
  always_comb begin
    input_addr_idx = int'(p_input_addr);
    if (input_addr_idx < INPUT_MEMORY_SIZE)
      p_input_data = NBITS'(const_data[input_addr_idx]);
    else
      p_input_data = '0;
  end
  assign p_input_valid = 1'b1;
  assign p_output_data_read = '0;
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
      in_inverse_d <= 1'b0;
    end else begin
      in_inverse_d <= (dut.st_conv_current == ST_CONV_INVERSE);

      if ((dut.st_conv_current == ST_CONV_INVERSE) && !in_inverse_d) begin
        if (conv_inverse_check_idx < $size(const_feat_out_batch)) begin
          for (int k = 0; k < CONV_OUTPUT_SIZE * CONV_OUTPUT_SIZE; k++) begin
            int t_idx;
            t_idx = f_transposed_index(k);
            if ($signed(dut.w_conv_inverse[k]) != $signed(const_feat_out_batch[conv_inverse_check_idx][t_idx])) begin
              $display("ERROR INVERSE[%0d] idx=%0d expected=%0d got=%0d time=%0t",
                       k, conv_inverse_check_idx, const_feat_out_batch[conv_inverse_check_idx][t_idx], $signed(dut.w_conv_inverse[k]), $realtime);
            end
          end
        end
        // else begin
        //   $display("ERROR: conv_inverse_check_idx overflow idx=%0d time=%0t", conv_inverse_check_idx, $realtime);
        // end
        conv_inverse_check_idx <= conv_inverse_check_idx + 1;
      end
    end
  end

  // Estímulos
  initial begin

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
    $finish;
  end

endmodule
