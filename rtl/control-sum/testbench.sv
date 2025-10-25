module tb;
  timeunit 1ns;
  timeprecision 1ps;

  import pack_def::*;
  import pack_data::*;
  import pack_param::*;
  import pack_typedef::*;

  logic clk;
  logic reset;

  logic w_start;
  logic w_end;

  logic w_conv_start;
  logic w_conv_idle;
  logic w_conv_end;

  type_input w_conv_input;
  type_weight w_conv_weight;
  type_output w_conv_output;

  logic w_input_en;
  logic w_input_wr;
  logic w_input_valid;
  logic[NADDR-1:0] w_input_addr;
  logic_vector w_input_in;
  logic_vector w_input_data;

  logic w_output_en;
  logic w_output_wr;
  logic w_output_valid;
  logic[NADDR-1:0] w_output_addr;
  logic_vector w_output_data_read;
  logic_vector w_output_out;


  int count_fout = 0;

  // Clock generation (10ns period)
  initial clk = 0;
  always #0.5 clk = ~clk;

  // DUT instantiation
  Control #(
    .NADDR(NADDR),
    .NBITS(NBITS),
    .LATENCY(LATENCY),
    .ROM(ROM),
    // .QUANT(QUANT),
    // .FEAT_INPUT_SIZE(FEAT_INPUT_SIZE),
    // .FEAT_OUTPUT_SIZE(FEAT_OUTPUT_SIZE),
    // .N_WINDOW(N_WINDOW),
    // .N_CHANNEL_IN(N_CHANNEL_IN),
    // .N_CHANNEL_OUT(N_CHANNEL_OUT),
    .LAST_WINDOW(LAST_WINDOW)
  ) dut (
    .clk(clk),
    .reset(reset),

    .p_start(w_start),
    .p_end(w_end),

    .p_conv_start(w_conv_start),
    .p_conv_idle(w_conv_idle),
    .p_conv_end(w_conv_end),

    .p_conv_input(w_conv_input),
    .p_conv_weight(w_conv_weight),
    .p_conv_output(w_conv_output),

    .p_input_en(w_input_en),
    .p_input_addr(w_input_addr),
    .p_input_valid(w_input_valid),
    .p_input_data(w_input_data),

    .p_output_en(w_output_en),
    .p_output_wr(w_output_wr),
    .p_output_addr(w_output_addr),
    .p_output_data_read(w_output_data_read),
    .p_output_data_write(w_output_out),
    .p_output_valid(w_output_valid)
  );

  Memory #(
    .NADDR(NADDR),
    .NBITS(NBITS),
    .LATENCY(LATENCY),
    .ROM(ROM)
  ) memory_read(
    .clk(clk),
    .reset(reset),
    .chip_en(w_input_en),
    .wr_en(w_input_wr),
    .address(w_input_addr),
    .data_in(w_input_in),
    .data_out(w_input_data),
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
    .data_in(w_output_data_read),
    .data_out(w_output_out),
    .data_valid(w_output_valid)
  );

  Conv #(
    .QUANT(QUANT),
    .NBITS(NBITS)
  ) conv (
    .clk(clk),
    .reset(reset),

    .p_start(w_conv_start),
    .p_end(w_conv_end),
    .p_idle(w_conv_idle),
    .p_input(w_conv_input),
    .p_weight(w_conv_weight),
    .p_output(w_conv_output)
  );

  // Inicialização dos sinais e reset
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);

    reset = 1;
    w_start = 0;
    @(posedge clk);
    reset = 0;
    w_start = 1;
    @(posedge clk);
    w_start = 0;

    // Start processamento
    $display("=== Start processing ===");

    for (int i = 0; i < FOUT1_SIZE; i++) begin
      @(posedge clk);
      wait(w_conv_end);
      @(posedge clk);
      for (int j = 0; j < FOUT2_SIZE; j++) begin
        @(posedge clk);
        wait(w_output_en);
        if ($signed(const_feat_out_batch[i][j]) != $signed(w_output_data_read)) begin
          $display("Time %0t | const_feat_out[%0d][%0d] = %0d | Output = %0d", $time, i, j, const_feat_out_batch[i][j], w_output_data_read);
          $display("=== ERROR - End simulation ====");
        end
      end
    end

    wait(w_end);
    $display("=== No errors - End simulation ===");
    $finish;
  end
endmodule
