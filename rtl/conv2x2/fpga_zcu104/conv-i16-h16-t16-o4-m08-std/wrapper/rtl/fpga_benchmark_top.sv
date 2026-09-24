`timescale 1ns/1ps

module fpga_benchmark_top #(
  parameter bit CHECKER_FAULT_INJECT = 1'b0
) (
  input  logic clk,
  input  logic reset,
  input  logic start,
  output logic done,
  output logic result_valid,
  output logic result_ok
);
  import pack_data::*;
  import pack_param::*;
  import output_signature_pkg::*;

  localparam int unsigned NBITS = 20;
  localparam int unsigned NADDR = 16;
  localparam int unsigned INPUT_WORDS = FEAT_INPUT_SIZE * FEAT_INPUT_SIZE * N_CHANNEL_IN;
  localparam int unsigned WEIGHT_WORDS = HADAMARD_SIZE * HADAMARD_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT;
  localparam int unsigned WEIGHT_BASE = INPUT_WORDS;
  localparam int unsigned OUTPUT_WORDS = FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE * N_CHANNEL_OUT;
  localparam int unsigned OUTPUT_ADDR_WIDTH = $clog2(OUTPUT_WORDS);
  localparam logic [31:0] CRC32_MPEG2_POLY = 32'h04c11db7;

  typedef enum logic {CHECK_IDLE, CHECK_SCAN} check_state_t;
  check_state_t check_state;

  logic core_input_en;
  logic [NADDR-1:0] core_input_addr;
  logic [NBITS-1:0] core_input_data;
  logic core_input_valid;
  logic core_output_en;
  logic core_output_wr;
  logic [NADDR-1:0] core_output_addr;
  logic [NBITS-1:0] core_output_data_write;
  logic [NBITS-1:0] core_output_data_read;
  logic core_output_valid;

  logic feature_read_en;
  logic weight_read_en;
  logic [NBITS-1:0] feature_data;
  logic [NBITS-1:0] weight_data;
  logic [NBITS-1:0] output_data_read;
  logic output_read_en;
  logic checker_read_en;
  logic checker_read_valid;
  logic output_write_en;
  logic [OUTPUT_ADDR_WIDTH-1:0] output_addr_narrow;
  logic [OUTPUT_ADDR_WIDTH-1:0] checker_addr;
  logic [OUTPUT_ADDR_WIDTH:0] checker_issue_count;
  logic [OUTPUT_ADDR_WIDTH:0] checker_consumed_count;
  logic checker_done;
  logic [31:0] result_signature;
  logic [31:0] result_signature_next;
  logic [NBITS-1:0] checker_word;
  logic core_done;
  logic core_start;
  logic job_started;

  // BRAM reads occur on the falling edge. Their data is stable for half a
  // cycle before the unchanged core consumes it on the rising edge.
  wire clk_read = ~clk;

  assign feature_read_en = core_input_en && (core_input_addr < NADDR'(WEIGHT_BASE));
  assign weight_read_en = core_input_en && (core_input_addr >= NADDR'(WEIGHT_BASE));
  assign core_input_data = weight_read_en ? weight_data : feature_data;
  assign core_input_valid = core_input_en;

  assign checker_read_en = (check_state == CHECK_SCAN) && (checker_issue_count < (OUTPUT_ADDR_WIDTH+1)'(OUTPUT_WORDS));
  assign output_read_en = (core_output_en && !core_output_wr) || checker_read_en;
  assign output_write_en = core_output_en && core_output_wr;
  assign output_addr_narrow = checker_read_en ? checker_addr : OUTPUT_ADDR_WIDTH'(core_output_addr);
  assign core_output_data_read = output_data_read;
  assign core_output_valid = core_output_en && !core_output_wr;
  assign done = core_done;
  assign core_start = start && !job_started;

  function automatic logic [31:0] crc32_mpeg2_word(
    input logic [31:0] crc,
    input logic [NBITS-1:0] word
  );
    logic [31:0] value;
    logic feedback;
    begin
      value = crc;
      for (int bit_index = NBITS - 1; bit_index >= 0; bit_index--) begin
        feedback = value[31] ^ word[bit_index];
        value = {value[30:0], 1'b0};
        if (feedback)
          value = value ^ CRC32_MPEG2_POLY;
      end
      return value;
    end
  endfunction

  assign checker_word = (CHECKER_FAULT_INJECT && checker_consumed_count == '0)
                      ? (output_data_read ^ {{(NBITS-1){1'b0}}, 1'b1})
                      : output_data_read;
  assign result_signature_next = crc32_mpeg2_word(result_signature, checker_word);

  // Read back the output BRAM only after the core's active job has completed.
  // This makes the computed result functionally observable without adding
  // checker fanout to the datapath during the measured job.
  always_ff @(posedge clk) begin
    if (reset) begin
      job_started <= 1'b0;
      check_state <= CHECK_IDLE;
    end else begin
      if (core_start)
        job_started <= 1'b1;

      case (check_state)
        CHECK_IDLE: begin
          if (core_done)
            check_state <= CHECK_SCAN;
        end

        CHECK_SCAN: begin
          if (checker_done)
            check_state <= CHECK_IDLE;
        end

        default: begin
          check_state <= CHECK_IDLE;
        end
      endcase
    end
  end

  // Pipeline checker reads for one full rising-edge clock period. This keeps
  // the BRAM output-to-CRC path out of the half-cycle timing budget.
  always_ff @(posedge clk) begin
    if (reset) begin
      checker_read_valid <= 1'b0;
      checker_addr <= '0;
      checker_issue_count <= '0;
      checker_consumed_count <= '0;
      checker_done <= 1'b0;
      result_signature <= 32'hffffffff;
      result_valid <= 1'b0;
      result_ok <= 1'b0;
    end else begin
      checker_read_valid <= checker_read_en;
      if (checker_read_en) begin
        checker_addr <= checker_addr + 1'b1;
        checker_issue_count <= checker_issue_count + 1'b1;
      end
      if (checker_read_valid) begin
        result_signature <= result_signature_next;
        checker_consumed_count <= checker_consumed_count + 1'b1;
        if (checker_consumed_count == (OUTPUT_ADDR_WIDTH+1)'(OUTPUT_WORDS - 1)) begin
          result_valid <= 1'b1;
          result_ok <= (result_signature_next == EXPECTED_OUTPUT_CRC32);
          checker_done <= 1'b1;
        end
      end
    end
  end

  Conv #(
    .N_CHANNEL_IN(N_CHANNEL_IN),
    .N_CHANNEL_OUT(N_CHANNEL_OUT),
    .FEAT_INPUT_SIZE(FEAT_INPUT_SIZE),
    .FEAT_INPUT_WIDTH(FEAT_INPUT_SIZE),
    .NADDR(NADDR),
    .NBITS(NBITS),
    .QUANT(QUANT_BITS),
    .CONV_OUTPUT_SIZE(CONV_OUTPUT_SIZE),
    .CONV_INPUT_SIZE(CONV_INPUT_SIZE),
    .HADAMARD_SIZE(HADAMARD_SIZE),
    .NUM_MULT(8)
  ) accelerator_core (
      .clk(clk),
      .reset(reset),
    .p_start(core_start),
    .p_end(core_done),
    .p_input_en(core_input_en),
    .p_input_addr(core_input_addr),
    .p_input_data(core_input_data),
    .p_input_valid(core_input_valid),
    .p_output_en(core_output_en),
    .p_output_wr(core_output_wr),
    .p_output_addr(core_output_addr),
    .p_output_data_write(core_output_data_write),
    .p_output_data_read(core_output_data_read),
    .p_output_valid(core_output_valid)
  );

  xpm_memory_sprom #(
    .ADDR_WIDTH_A(12),
    .AUTO_SLEEP_TIME(0),
    .CASCADE_HEIGHT(0),
    .ECC_MODE("no_ecc"),
    .MEMORY_INIT_FILE("input_features.mem"),
    .MEMORY_INIT_PARAM(""),
    .MEMORY_PRIMITIVE("block"),
    .MEMORY_SIZE(INPUT_WORDS * NBITS),
    .READ_DATA_WIDTH_A(NBITS),
    .READ_LATENCY_A(1),
    .READ_RESET_VALUE_A("00000"),
    .RST_MODE_A("SYNC"),
    .SIM_ASSERT_CHK(1),
    .USE_MEM_INIT(1)
  ) input_memory (
    .addra(core_input_addr[11:0]),
    .clka(clk_read),
    .dbiterra(),
    .douta(feature_data),
    // Keep the physical BRAM read enable static; the core ignores its data
    // outside feature-read cycles. This removes a half-cycle enable path.
    .ena(1'b1),
    .injectdbiterra(1'b0),
    .injectsbiterra(1'b0),
    .regcea(1'b1),
    .rsta(reset),
    .sbiterra(),
    .sleep(1'b0)
  );

  xpm_memory_sprom #(
    .ADDR_WIDTH_A(8),
    .AUTO_SLEEP_TIME(0),
    .CASCADE_HEIGHT(0),
    .ECC_MODE("no_ecc"),
    .MEMORY_INIT_FILE("transformed_weights.mem"),
    .MEMORY_INIT_PARAM(""),
    .MEMORY_PRIMITIVE("block"),
    .MEMORY_SIZE(WEIGHT_WORDS * NBITS),
    .READ_DATA_WIDTH_A(NBITS),
    .READ_LATENCY_A(1),
    .READ_RESET_VALUE_A("00000"),
    .RST_MODE_A("SYNC"),
    .SIM_ASSERT_CHK(1),
    .USE_MEM_INIT(1)
  ) weight_memory (
    .addra(8'(core_input_addr - NADDR'(WEIGHT_BASE))),
    .clka(clk_read),
    .dbiterra(),
    .douta(weight_data),
    .ena(1'b1),
    .injectdbiterra(1'b0),
    .injectsbiterra(1'b0),
    .regcea(1'b1),
    .rsta(reset),
    .sbiterra(),
    .sleep(1'b0)
  );

  xpm_memory_sdpram #(
    .ADDR_WIDTH_A(OUTPUT_ADDR_WIDTH),
    .ADDR_WIDTH_B(OUTPUT_ADDR_WIDTH),
    .AUTO_SLEEP_TIME(0),
    .BYTE_WRITE_WIDTH_A(NBITS),
    .CASCADE_HEIGHT(0),
    .CLOCKING_MODE("independent_clock"),
    .ECC_MODE("no_ecc"),
    .MEMORY_INIT_FILE("output_zero.mem"),
    .MEMORY_INIT_PARAM(""),
    .MEMORY_PRIMITIVE("block"),
    .MEMORY_SIZE(OUTPUT_WORDS * NBITS),
    .READ_DATA_WIDTH_B(NBITS),
    .READ_LATENCY_B(1),
    .READ_RESET_VALUE_B("00000"),
    .RST_MODE_B("SYNC"),
    .SIM_ASSERT_CHK(1),
    .USE_MEM_INIT(1),
    .WRITE_DATA_WIDTH_A(NBITS),
    .WRITE_MODE_B("read_first")
  ) output_memory (
    .addra(output_addr_narrow),
    .addrb(output_addr_narrow),
    .clka(clk),
    .clkb(clk_read),
    .dbiterrb(),
    .dina(core_output_data_write),
    .doutb(output_data_read),
    .ena(output_write_en),
    .enb(output_read_en),
    .injectdbiterra(1'b0),
    .injectsbiterra(1'b0),
    .regceb(1'b1),
    .rstb(reset),
    .sbiterrb(),
    .sleep(1'b0),
    .wea(1'b1)
  );
endmodule
