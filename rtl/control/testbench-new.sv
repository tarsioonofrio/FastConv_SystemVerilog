module tb;
  timeunit 1ns;
  timeprecision 1ps;

  import pack_data::*;
  import pack_param::*;
  import pack_mux_mult::*;


  localparam int NBITS = 16;
  localparam int NADDR = 14;
  localparam int LATENCY = 1;
  localparam int ROM = 1;
  localparam int FEAT_INPUT_WIDTH = FEAT_INPUT_SIZE;
  // localparam int NUM_MULT_LOCAL = 6;
  // localparam int STATE_MULT_LOCAL = 6;
  // localparam int CONV_OUTPUT_SIZE = 3;
  // localparam int CONV_INPUT_SIZE = 5;
  // localparam int HADAMARD_SIZE = 6;

  logic clk;
  logic reset;

  logic w_start;
  logic w_end;

  logic w_conv_start;
  logic w_conv_idle;
  logic w_conv_end;

  logic [NBITS-1:0] w_conv_input [CONV_INPUT_SIZE*CONV_INPUT_SIZE-1:0];
  logic [NBITS-1:0] w_conv_weight [HADAMARD_SIZE*HADAMARD_SIZE-1:0];
  logic [NBITS-1:0] w_conv_output [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0];

  logic w_input_en;
  logic w_input_wr;
  logic w_input_valid;
  logic [NADDR-1:0] w_input_addr;
  logic [NBITS-1:0] w_input_data_write;
  logic [NBITS-1:0] w_input_data_read;

  logic w_output_en;
  logic w_output_wr;
  logic w_output_valid;
  logic [NADDR-1:0] w_output_addr;
  logic [NBITS-1:0] w_output_data_read;
  logic [NBITS-1:0] w_output_data_write;
  logic [NADDR-1:0] w_output_addr_forced;

  logic debug;

  time exec_time;

  int count_fout = 0;
  int i = 0;
  int j = 0;
  int cycle_count = 0;
  localparam int OUTPUT_TILES_PER_AXIS = (FEAT_OUTPUT_SIZE + CONV_OUTPUT_SIZE - 1) / CONV_OUTPUT_SIZE;
  localparam int OUTPUT_CHANNEL_STRIDE = FEAT_OUTPUT_SIZE * CONV_OUTPUT_SIZE * OUTPUT_TILES_PER_AXIS;

  // Clock generation (10ns period)
  initial clk = 0;
  always #5 clk = ~clk;

  // Cycle counter for overall run length after reset deasserts.
  always_ff @(posedge clk or posedge reset) begin: CYCLE_COUNT_BLOCK
    if (reset)
      cycle_count <= 0;
    else
      cycle_count <= cycle_count + 1;
  end

  // DUT instantiation
  Control #(
    .N_CHANNEL_IN(N_CHANNEL_IN),
    .N_CHANNEL_OUT(N_CHANNEL_OUT),
    .FEAT_INPUT_SIZE(FEAT_INPUT_SIZE),
    .FEAT_INPUT_WIDTH(FEAT_INPUT_WIDTH),
    .NADDR(NADDR),
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
    .p_start(w_start),
    .p_end(w_end),
    .p_input_en(w_input_en),
    .p_input_addr(w_input_addr),
    .p_input_data(w_input_data_read),
    .p_input_valid(w_input_valid),
    .p_output_en(w_output_en),
    .p_output_wr(w_output_wr),
    .p_output_addr(w_output_addr),
    .p_output_data_write(w_output_data_write),
    .p_output_data_read(w_output_data_read),
    .p_output_valid(w_output_valid)
  );

  assign w_input_wr = 1'b0;
  assign w_input_data_read = (w_input_en && w_input_addr < $size(const_data)) ? NBITS'(const_data[w_input_addr]) : '0;
  assign w_input_valid = w_input_en;

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

    debug = 0;
    reset = 1;
    w_start = 0;
    @(posedge clk);
    reset = 0;
    w_start = 1;
    @(posedge clk);
    w_start = 0;

    // Start processamento
    $display("=== Start processing ===");


    // for (int i = 0; i < FOUT1_SIZE; i++) begin
    //   @(posedge clk);
    //   wait(dut.w_end_last_channel_out);
    //   wait(dut.p_conv_end);
    //   @(posedge clk);
    //   for (int j = 0; j < FOUT2_SIZE; j++) begin
    //     @(posedge clk);
    //     wait(dut.p_output_wr);
    //     if ($signed(const_feat_out_batch[i][j]) != $signed(dut.p_output_data_write)) begin
    //       $display("Time %0f | const_feat_out[%0d][%0d] = %0d | Output = %0d", $realtime, i, j, const_feat_out_batch[i][j], dut.p_output_data_write);
    //       $display("=== ERROR - End simulation ====");
    //     end
    //   end
    // end


    wait(w_end);
    // Allow the output FSM and memory write latency to drain before readback.
    repeat (LATENCY + 4) @(posedge clk);
    // exec_time = $realtime;
    $display("\n*** TIME %0f ***\n", $realtime);
    $display("\n*** TOTAL CYCLES %0d ***\n", cycle_count);

    // debug = 1;

    // Override DUT outputs while reading back memory contents.
    force w_input_en = 1'b0;
    force w_output_en = 1'b1;
    force w_output_wr = 1'b0;
    @(posedge clk);
    for (i = 0; i < FEAT_OUTPUT_SIZE * N_CHANNEL_OUT; i++) begin
      for (j = 0; j < FEAT_OUTPUT_SIZE; j++) begin
        int output_channel;
        int row_in_channel;
        logic [NBITS-1:0] expected_out;
        output_channel = i / FEAT_OUTPUT_SIZE;
        row_in_channel = i % FEAT_OUTPUT_SIZE;
        w_output_addr_forced = output_channel * OUTPUT_CHANNEL_STRIDE + row_in_channel * FEAT_OUTPUT_SIZE + j;
        force w_output_addr = w_output_addr_forced;
        @(posedge clk);
        wait(w_output_valid);
        expected_out = const_feat_out[i][j];
        if ($signed(expected_out) != $signed(w_output_data_read)) begin
          $display("Time %0f | const_feat_out[%0d][%0d] = %0d | Output = %0d", $realtime, i, j, expected_out, w_output_data_read);
          $display("=== ERROR - End simulation ====");
        end
      end
    end
    release w_output_addr;
    release w_output_en;
    release w_output_wr;
    release w_input_en;

    $display("=== No errors - End simulation ===");

    $display("\n*** TIME %0f ***\n", $realtime);
    $display("\n*** TOTAL CYCLES %0d ***\n", cycle_count);

    // $display("Execution time after wait(end) %0f", exec_time);

    #20ns

    $finish;
  end

endmodule
