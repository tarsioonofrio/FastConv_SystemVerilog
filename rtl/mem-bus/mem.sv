module MemoryBus
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

  localparam int DATA_DEPTH      = (1 << NADDR);
  localparam int CONST_DATA_SIZE = $size(const_data);

  logic_vector data[0:2**NADDR-1];

  int r_cycles_latency;

  // Write one full column per beat (each lane is a row of the same column).
  always_ff @(posedge clk) begin
    if (reset) begin
      data <= '{default: '0};
    end else if (chip_en && wr_en && (ROM == 0)) begin
      for (int lane = 0; lane < COLUMN_LANES; lane++) begin
        int lane_addr;
        lane_addr = address + (lane * FEAT_SIZE);
        if (lane_addr < DATA_DEPTH)
          data[lane_addr] <= data_in[lane];
      end
    end
  end

  // Read back a full column in one cycle.
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
