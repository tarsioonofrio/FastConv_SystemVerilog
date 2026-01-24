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
  logic_vector w_input_data_write [C1_SIZE-1:0];
  logic_vector w_input_data_read [C1_SIZE-1:0];

  logic w_output_en;
  logic w_output_wr;
  logic w_output_valid;
  logic[NADDR-1:0] w_output_addr;
  logic_vector w_output_data_read [A1_SIZE-1:0];
  logic_vector w_output_data_write [A1_SIZE-1:0];
  logic[NADDR-1:0] w_output_addr_forced;

  logic debug;

  time exec_time;

  int count_fout = 0;
  int i = 0;
  int j = 0;

  // Clock generation (10ns period)
  initial clk = 0;
  always #5 clk = ~clk;

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
    .p_input_data(w_input_data_read),

    .p_output_en(w_output_en),
    .p_output_wr(w_output_wr),
    .p_output_addr(w_output_addr),
    .p_output_data_read(w_output_data_read),
    .p_output_data_write(w_output_data_write),
    .p_output_valid(w_output_valid)
  );

  MemoryColumn #(
    .NADDR(NADDR),
    .NBITS(NBITS),
    .LATENCY(LATENCY),
    .ROM(ROM),
    .FEAT_SIZE(FEAT_INPUT_SIZE),
    .COLUMN_LANES(C1_SIZE)
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

  MemoryColumn #(
    .NADDR(NADDR),
    .NBITS(NBITS),
    .LATENCY(LATENCY),
    .ROM(0),
    .FEAT_SIZE(FEAT_OUTPUT_SIZE),
    .COLUMN_LANES(A1_SIZE)
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

    debug = 0;

    reset = 1;
    w_input_wr = 1'b0;
    for (int lane = 0; lane < C1_SIZE; lane++) begin
      w_input_data_write[lane] = '0;
    end
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
    // exec_time = $realtime;
    $display("\n *** Total Time %0f ***\n", $realtime);

    // debug = 1;

    // Override DUT outputs while reading back memory contents.
    force w_input_en = 1'b0;
    force w_output_en = 1'b1;
    force w_output_wr = 1'b0;
    @(posedge clk);
    for (i = 0; i < FEAT_OUTPUT_SIZE; i += A1_SIZE) begin
      for (j = 0; j < FEAT_OUTPUT_SIZE; j++) begin
        w_output_addr_forced = i * FEAT_OUTPUT_SIZE + j;
        force w_output_addr = w_output_addr_forced;
        @(posedge clk);
        wait(w_output_valid);
        for (int lane = 0; lane < A1_SIZE; lane++) begin
          if ((i + lane) < FEAT_OUTPUT_SIZE) begin
            if ($unsigned(const_feat_out[i + lane][j]) != $unsigned(w_output_data_read[lane])) begin
              $display("Time %0f | const_feat_out[%0d][%0d] = %0d | Output[%0d] = %0d",
                       $realtime, i + lane, j, const_feat_out[i + lane][j], lane, w_output_data_read[lane]);
              $display("=== ERROR - End simulation ====");
            end
          end
        end
      end
    end
    release w_output_addr;
    release w_output_en;
    release w_output_wr;
    release w_input_en;

    $display("=== No errors - End simulation ===");

    $display("\n *** Total Time %0f ***\n", $realtime);

    // $display("Execution time after wait(end) %0f", exec_time);

    #20ns

    $finish;
  end
endmodule

// Column-wide memory model: returns COLUMN_LANES samples for one column address.
module MemoryColumn
  import pack_def::*;
  import pack_data::*;
  import pack_typedef::*;
#(
    parameter int NADDR        = 16,
    parameter int NBITS        = 20,
    parameter int LATENCY      = 1,
    parameter int ROM          = 0,
    parameter int FEAT_SIZE    = 32,
    parameter int COLUMN_LANES = 1
  )
  (
    input  logic            clk, reset, chip_en, wr_en,
    input  logic[NADDR-1:0] address,
    input  logic_vector     data_in [COLUMN_LANES-1:0],
    output logic_vector     data_out [COLUMN_LANES-1:0],
    output logic            data_valid
  );

  timeunit 1ns;
  timeprecision 1ps;

  localparam int DATA_DEPTH = (1 << NADDR);
  localparam int CONST_DATA_SIZE = $size(const_data);

  logic_vector data[0:2**NADDR-1];

  int r_cycles_latency;

  always_ff @(posedge clk) begin
    if (reset)
      data <= '{default: '0};
    else if (chip_en && wr_en && (ROM == 0)) begin
      for (int lane = 0; lane < COLUMN_LANES; lane++) begin
        int lane_addr;
        lane_addr = address + (lane * FEAT_SIZE);
        if (lane_addr < DATA_DEPTH)
          data[lane_addr] <= data_in[lane];
      end
    end
  end

  always_comb begin
    for (int lane = 0; lane < COLUMN_LANES; lane++) begin
      int lane_addr;
      lane_addr = address + (lane * FEAT_SIZE);
      if (chip_en) begin
        if (ROM == 1) begin
          if (lane_addr < CONST_DATA_SIZE)
            data_out[lane] = $signed(const_data[lane_addr]);
          else
            data_out[lane] = '0;
        end else if (lane_addr < DATA_DEPTH) begin
          data_out[lane] = data[lane_addr];
        end else begin
          data_out[lane] = '0;
        end
      end else begin
        data_out[lane] = '0;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (reset || r_cycles_latency == 0)
      r_cycles_latency <= LATENCY - 1;
    else if (chip_en)
      r_cycles_latency <= r_cycles_latency - 1;
  end

  always_comb begin
    if (r_cycles_latency == 0 && chip_en)
      data_valid = 1'b1;
    else
      data_valid = 1'b0;
  end
endmodule
