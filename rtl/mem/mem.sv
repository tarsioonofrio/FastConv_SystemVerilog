module Memory
    import pack_def::*;
    import pack_data::*;
    import pack_typedef::*;
#(
    parameter int NADDR   = 16,
    parameter int NBITS   = 20,
    parameter int LATENCY = 1,
    parameter int ROM     = 0
  )
  (
    input  logic            clk, reset, chip_en, wr_en,
    input  logic[NADDR-1:0] address,
    input  logic_vector     data_in,
    output logic_vector     data_out,
    output logic            data_valid
  );

  timeunit 1ns;
  timeprecision 1ps;

  // Internal storage for RAM-backed mode
  logic_vector data[0:2**NADDR-1];

  // Simple latency counter used to generate data_valid every LATENCY
  // cycles while reads are enabled.
  int r_cycles_latency;

  // Write port (synchronous)
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      data <= '{default: '0};
    end else if (chip_en && wr_en && (ROM == 0)) begin
      data[address] <= data_in;
    end
  end

  always_comb begin
    if (ROM == 0 && chip_en == 1'b1)
      data_out = data[address];
    else if (ROM == 1 && chip_en == 1'b1)
      data_out = $signed(const_data[address]);
    else
      data_out = '{default: '0};
  end

  // Read latency counter and valid generation
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      r_cycles_latency <= LATENCY - 1;
    end else begin
      if (r_cycles_latency == 0)
        r_cycles_latency <= LATENCY - 1;
      else if (chip_en && !wr_en)
        r_cycles_latency <= r_cycles_latency - 1;
    end
  end

  always_comb begin
    if ((r_cycles_latency == 0) && chip_en && !wr_en)
      data_valid = 1'b1;
    else
      data_valid = 1'b0;
  end

endmodule
