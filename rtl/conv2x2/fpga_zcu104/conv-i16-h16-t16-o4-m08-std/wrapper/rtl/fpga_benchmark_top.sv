`timescale 1ns/1ps

module fpga_benchmark_top (
  input  logic clk,
  input  logic reset,
  input  logic start,
  output logic done
);
  import pack_data::*;
  import pack_param::*;

  localparam int unsigned NBITS = 20;
  localparam int unsigned NADDR = 16;
  localparam int unsigned INPUT_WORDS = FEAT_INPUT_SIZE * FEAT_INPUT_SIZE * N_CHANNEL_IN;
  localparam int unsigned WEIGHT_WORDS = HADAMARD_SIZE * HADAMARD_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT;
  localparam int unsigned WEIGHT_BASE = INPUT_WORDS;
  localparam int unsigned OUTPUT_WORDS = FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE * N_CHANNEL_OUT;
  localparam int unsigned OUTPUT_ADDR_WIDTH = $clog2(OUTPUT_WORDS);

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
  logic output_write_en;
  logic [OUTPUT_ADDR_WIDTH-1:0] output_addr_narrow;
  logic core_done;

  // BRAM reads occur on the falling edge. Their data is stable for half a
  // cycle before the unchanged core consumes it on the rising edge.
  wire clk_read = ~clk;

  assign feature_read_en = core_input_en && (core_input_addr < NADDR'(WEIGHT_BASE));
  assign weight_read_en = core_input_en && (core_input_addr >= NADDR'(WEIGHT_BASE));
  assign core_input_data = weight_read_en ? weight_data : feature_data;
  assign core_input_valid = core_input_en;

  assign output_read_en = core_output_en && !core_output_wr;
  assign output_write_en = core_output_en && core_output_wr;
  assign output_addr_narrow = OUTPUT_ADDR_WIDTH'(core_output_addr);
  assign core_output_data_read = output_data_read;
  assign core_output_valid = output_read_en;
  assign done = core_done;

  // Preserve the architectural core hierarchy for audit/debug without
  // changing the core RTL or adding benchmark I/O ports.
  (* KEEP_HIERARCHY = "yes" *)
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
    .p_start(start),
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
    .ena(feature_read_en),
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
    .ena(weight_read_en),
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
