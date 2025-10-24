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
  logic p_conv_idle;
  logic p_conv_end;
  logic p_sum_end;
  logic p_conv_end_control;
  logic p_start_channel;

  type_input p_input;
  type_weight p_weight;
  type_output p_output_conv;
  type_output p_input_channel;
  type_output p_output_channel;
  type_output p_output_control;

  logic w_read_en;
  logic w_read_wr;
  logic w_read_valid;
  logic[NADDR-1:0] w_read_addr;
  logic_vector w_read_data_in;
  logic_vector w_read_data_out;
  
  logic p_sum_channel;
  logic w_start_channel;
  logic w_write_chip;
  logic w_write_valid;
  logic w_write_en;
  logic w_chip_en;
  logic w_write_en_control;
  logic w_read_en_channel;
  logic[NADDR-1:0] w_write_addr;
  logic[NADDR-1:0] w_write_addr_control;
  logic[NADDR-1:0] w_read_addr_channel;
  logic_vector w_write_data_in;
  logic_vector w_write_data_control;
  logic_vector w_read_data_channel;
  logic_vector w_write_data_out;


  int count_fout = 0;

  // Clock generation (10ns period)
  initial clk = 0;
  always #0.5 clk = ~clk;

  typedef enum {
    IDLE,
    START,
    RUN
  } state_type;

  state_type current_st, next_st;

  // DUT instantiation
  ChannelSum #(
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

    .p_start(p_start_channel),
    .p_end(p_end_channel),
    .p_sum(p_sum_channel),
    .p_input(p_input_channel),
    .p_output(p_output_channel),

    .p_read_en(w_read_en_channel),
    .p_read_addr(w_read_addr_channel),
    .p_read_data(w_write_data_out),
    .p_read_valid(w_write_valid)

    // .p_write_en(w_write_en),
    // .p_write_addr(w_write_addr)
  );

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
  ) control (
    .clk(clk),
    .reset(reset),

    .p_start(p_start),
    .p_end(p_end),
    .p_conv_start(p_conv_start),
    .p_conv_idle(p_conv_idle),
    .p_conv_end(p_conv_end_control),
    .p_start_channel(w_start_channel),
    .p_input(p_input),
    .p_weight(p_weight),
    .p_output(p_output_control),

    .p_read_en(w_read_en),
    .p_read_addr(w_read_addr),
    .p_read_valid(w_read_valid),
    .p_read_data(w_read_data_out),

    .p_write_en(w_write_en),
    .p_write_addr(w_write_addr_control),
    .p_write_data(w_write_data_in)
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
    .data_in(w_read_data_in),
    .data_out(w_read_data_out),
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
    .chip_en(w_chip_en),
    .wr_en(w_write_en),
    .address(w_write_addr),
    .data_in(w_write_data_in),
    .data_out(w_write_data_out),
    .data_valid(w_write_valid)
  );

  Conv #(
    .QUANT(QUANT),
    .NBITS(NBITS)
  ) conv (
    .clk(clk),
    .reset(reset),

    .p_start(p_conv_start),
    .p_idle(p_conv_idle),
    .p_end(p_conv_end),
    .p_input(p_input),
    .p_weight(p_weight),
    .p_output(p_output_conv)
  );


  // Sequential logic that advances the state machines
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      current_st  <= IDLE;
    end else begin
      current_st  <= next_st;
    end
  end


  // Combinational logic for the output (write) state machine
  always_comb begin
    next_st = current_st;
    unique case (current_st)
      // Waits for the convolution-complete signal
      IDLE: begin
        if (w_start_channel)
          next_st = START;
      end
      START:
        next_st = RUN;
      // Waits for the output data write to memory to complete and then returns to idle
      RUN: begin
        // if (w_end_fout)
        //   next_st = IDLE;
      end
    endcase
  end


  always_comb begin
    // Bias + kernel + first feature map
    if (current_st == IDLE) begin
      w_chip_en = w_write_en;
      w_write_addr = w_write_addr_control;

      p_start_channel = 0;
      p_conv_end_control = p_conv_end;
      p_sum_channel = 0;

      p_input_channel = '{default: '0};
      p_output_control = p_output_conv;
    end else if (current_st == START) begin
      w_chip_en = w_read_en_channel;
      // w_write_en = 0;
      w_write_addr = w_read_addr_channel;

      p_start_channel = 1;
      p_conv_end_control = p_end_channel;
      p_sum_channel = 0;

      p_input_channel = p_output_conv;
      p_output_control = p_output_channel;
    end else begin
      w_chip_en = w_read_en_channel;
      // w_write_en = 0;
      w_write_addr = w_read_addr_channel;

      p_start_channel = 1;
      p_conv_end_control = p_end_channel;
      p_sum_channel = p_conv_end;

      p_input_channel = p_output_conv;
      p_output_control = p_output_channel;
    end
  end

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
      wait(p_end_channel);
      @(posedge clk);
      for (int j = 0; j < FOUT2_SIZE; j++) begin
        @(posedge clk);
        wait(w_write_en);
        if ($signed(const_feat_out_batch[i][j]) != $signed(w_write_data_in)) begin
          $display("Time %0t | const_feat_out[%0d][%0d] = %0d | Output = %0d", $time, i, j, const_feat_out_batch[i][j], w_write_data_in);
          $display("=== ERROR - End simulation ====");
        end
      end
    end

    wait(p_end);
    
    // for (int i = 0; i < FOUT1_SIZE ; i++) begin
    //   for (int j = 0; j < FOUT2_SIZE; j++) begin
    //     @(posedge clk);
    //     w_chip_en = 1;
    //     w_write_en = 1;
    //     w_write_addr = i * FOUT1_SIZE + j;
    //     wait(w_write_valid);
    //     if ($signed(const_feat_out[i][j]) != $signed(w_write_data_out)) begin
    //       $display("Time %0t | const_feat_out[%0d][%0d] = %0d | Output = %0d", $time, i, j, const_feat_out[i][j], w_write_data_out);
    //       $display("=== ERROR - End simulation ====");
    //     end
    //   end
    // end

    $display("=== No errors - End simulation ===");
    $finish;
  end
endmodule
