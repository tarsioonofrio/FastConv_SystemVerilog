module Memory
    import data::*;
    import pack_typedef::*;
    import pack_param::*;
 #(
    parameter int NADDR   = 12,
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

  logic_vector data[0:2**NADDR-1] = '{default: '0};

  int r_cycles_latency;

  always_ff @(posedge clk) begin
    if (reset)
      data <= '{default: '0};
    // else if (ROM == 0 && chip_en == 1'b1 && wr_en == 1'b1)
    else if (chip_en == 1'b1 && wr_en == 1'b1)
      data[address] <= data_in;
  end

  always_comb begin
    if (ROM == 0 && chip_en == 1'b1)
      data_out = data[address];
    else if (ROM == 1 && chip_en == 1'b1)
      data_out = $signed(const_data[address]);
    else
      data_out = '{default: '0};
  end

  always_ff @(posedge clk) begin
    if (reset || r_cycles_latency == 0)
      r_cycles_latency <= LATENCY - 1;
    else if (chip_en == 1'b1)
      r_cycles_latency <= r_cycles_latency - 1;
  end

  always_comb begin
    if (r_cycles_latency == 0 && chip_en == 1'b1)
      data_valid = 1'b1;
    else
      data_valid = 1'b0;
  end

endmodule
