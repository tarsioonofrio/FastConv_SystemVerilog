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

  int count_fout = 0;
  int i = 0;
  int j = 0;

  // Clock generation (10ns period)
  initial clk = 0;
  always #0.5 clk = ~clk;

  // DUT instantiation
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
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);

    reset = 1;
    p_start = 0;
    @(posedge clk);
    reset = 0;
    p_start = 1;

    // Start processamento
    $display("=== Start processing ===");

    @(posedge clk);
    p_start = 0;
    i = 0;
    j = 0;

    while (i < FOUT1_SIZE) begin
      @(posedge clk);
      #1ps;
      if (w_output_en && w_output_wr) begin
        if ($signed(const_feat_out_batch[i][j]) != $signed(w_output_data_write)) begin
          $display("Time %0t | const_feat_out[%0d][%0d] = %0d | Output = %0d", $time, i, j, const_feat_out_batch[i][j], w_output_data_write);
          $display("=== ERROR - End simulation ====");
        end
        if (j == FOUT2_SIZE - 1) begin
          j = 0;
          i++;
        end else begin
          j++;
        end
      end
    end

    wait(p_end);
    $display("=== No errors - End simulation ===");
    $finish;
  end
endmodule
