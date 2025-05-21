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
    input logic            clk, reset, chip_en, wr_en,
    input logic[NADDR-1:0] address,
    input logic_vector     data_in,
    output logic_vector    data_out,
    output logic           data_valid
  );

  timeunit 1ns;
  timeprecision 1ps;

  logic_vector data[2**NADDR-1:0] = '{default: '0};
  logic wire_valid, reg_valid;
  logic_vector  wire_out, reg_out;

  always_ff @(posedge clk) begin
    if (reset)
      data <= '{default: '0};
    else if (ROM == 0 && chip_en == 1'b1 && wr_en == 1'b1)
      data[address] <= data_in;
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      reg_valid <= '0;
      reg_out <= '{default: '0};
    end else begin
      reg_valid <= wire_valid;
      reg_out <= wire_out;
    end
  end

  assign data_out = reg_out;
  assign data_valid = reg_valid;

  always_comb begin
    if (ROM == 0) begin
      if (chip_en == 1'b1 && wr_en == 1'b0) begin
        wire_valid = '1;
        wire_out = data[address];
      end else begin
        wire_valid = '0;
        wire_out = '{default: '0};
      end
    end
      else if (ROM == 1 && chip_en == 1'b1) begin
      wire_out = $signed(const_weight[address / FIN1_SIZE][address % FIN1_SIZE]);
      wire_valid = '1;
    end
    else if (ROM == 2 && chip_en == 1'b1) begin
      wire_out = $signed(const_feat_in[address / W1_SIZE][address % W1_SIZE]);
      wire_valid = '1;
    end
    else begin
      wire_out = '{default: '0};
      wire_valid = '0;
    end
  end
endmodule
