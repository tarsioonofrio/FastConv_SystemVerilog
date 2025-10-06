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

  logic p_conv_start;
  logic p_conv_end;

  type_input p_input;
  type_weight p_weight;
  type_output p_output;

  logic w_read_en;
  logic w_read_wr;
  logic w_read_valid;
  logic[NADDR-1:0] w_read_addr;
  logic_vector w_read_in;
  logic_vector w_read_data;

  logic w_write_chip;
  logic w_write_en;
  logic w_write_valid;
  logic[NADDR-1:0] w_write_addr;
  logic_vector w_write_data;
  logic_vector w_write_out;


  int count_fout = 0;

  // Clock generation (10ns period)
  initial clk = 0;
  always #5 clk = ~clk;

  // DUT instantiation
  Control #(
    .NADDR(NADDR),
    .NBITS(NBITS),
    .LATENCY(LATENCY),
    .ROM(ROM),
    .QUANT(QUANT),
    .FEAT_INPUT_SIZE(FEAT_INPUT_SIZE),
    .FEAT_OUTPUT_SIZE(FEAT_OUTPUT_SIZE),
    .N_WINDOW(N_WINDOW),
    .N_CHANNEL_IN(N_CHANNEL_IN),
    .N_CHANNEL_OUT(N_CHANNEL_OUT),
    .LAST_WINDOW(LAST_WINDOW)
  ) dut (
    .clk(clk),
    .reset(reset),

    .p_start(p_start),
    .p_end(p_end),
    .p_conv_start(p_conv_start),
    .p_conv_end(p_conv_end),
    .p_input(p_input),
    .p_weight(p_weight),
    .p_output(p_output),

    .p_read_en(w_read_en),
    .p_read_addr(w_read_addr),
    .p_read_valid(w_read_valid),
    .p_read_data(w_read_data),

    .p_write_en(w_write_en),
    .p_write_addr(w_write_addr),
    .p_write_data(w_write_data)
  );

  Memory #(
    .NADDR(NADDR),
    .NBITS(NBITS),
    .LATENCY(LATENCY),
    .ROM(ROM)
  ) memory_read(
    .clk(clk),
    .reset(reset),
    .chip_en(w_read_en),
    .wr_en(w_read_wr),
    .address(w_read_addr),
    .data_in(w_read_in),
    .data_out(w_read_data),
    .data_valid(w_read_valid)
  );

  Memory #(
    .NADDR(NADDR),
    .NBITS(NBITS),
    .LATENCY(LATENCY),
    .ROM(0)
  ) memory_write(
    .clk(clk),
    .reset(reset),
    .chip_en(w_write_en),
    .wr_en(w_write_en),
    .address(w_write_addr),
    .data_in(w_write_data),
    .data_out(w_write_out),
    .data_valid(w_write_valid)
  );

  Conv #(
    .QUANT(QUANT),
    .NBITS(NBITS)
  ) conv (
    .clk(clk),
    .reset(reset),

    .p_start(p_conv_start),
    .p_end(p_conv_end),
    .p_input(p_input),
    .p_weight(p_weight),
    .p_output(p_output)
  );

  // Inicialização dos sinais e reset
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);

    reset = 1;
    p_start = 0;
    @(posedge clk);
    reset = 0;
    p_start = 1;
    @(posedge clk);
    p_start = 0;

    // Start processamento
    $display("=== Start processing ===");

    for (int i = 0; i < FOUT1_SIZE; i++) begin
      @(posedge clk);
      wait(p_conv_end);
      @(posedge clk);
      for (int j = 0; j < FOUT2_SIZE; j++) begin
        @(posedge clk);
        wait(w_write_en);
        if ($signed(const_feat_out_batch[i][j]) != $signed(w_write_data)) begin
          $display("Time %0t | const_feat_out[%0d][%0d] = %0d | Output = %0d", $time, i, j, const_feat_out_batch[i][j], w_write_data);
          $display("=== ERROR - End simulation ====");
        end
      end
    end

    wait(p_end);
    $display("=== No errors - End simulation ===");
    $finish;
  end
endmodule
