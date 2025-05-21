module Memory
  import packConv::*;
  import data::*;
 #(
    parameter int NADDR   = 12,
    parameter int NBITS   = 20,
    parameter int LATENCY = 0,
    parameter int ROM     = 0
  )
  (
    input  logic           clk, reset, chip_en, wr_en,
    input logic[NADDR-1:0] address,
    input logic_vector     data_in,
    output logic_vector    data_out,
    output logic           data_valid
  );

  timeunit 1ns;
  timeprecision 1ps;

  logic_vector data[2**NADDR-1:0] = '{default: '0};

  always_ff @(posedge clk) begin
    if (reset) begin
      data <= '{default: '0};
    end else if (ROM == 0 && chip_en == 1'b1 && wr_en == 1'b1) begin
      data[address] <= data_in;
    end
  end

  always_comb begin
    if (ROM == 0) begin
      if (chip_en == 1'b1 && wr_en == 1'b0) begin
        data_valid = '1;
        data_out = data[address];
      end else begin
        data_out = '0;
        data_valid = '0;
      end
    // end else if (ROM == 1 && chip_en == 1'b1) begin
    //   data_out = const_weight[address];
    // end else if (ROM == 2 && chip_en == 1'b1) begin
    //   data_out = const_feat_in[address];
    end
  end
endmodule
