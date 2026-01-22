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

  logic_vector data[0:2**NADDR-1];

  localparam int EFFECTIVE_LATENCY = (LATENCY > 0) ? (LATENCY - 1) : 0;

  always_ff @(posedge clk) begin
    if (reset)
      data <= '{default: '0};
    // else if (ROM == 0 && chip_en == 1'b1 && wr_en == 1'b1)
    else if (chip_en == 1'b1 && wr_en == 1'b1 && ROM == 0)
      data[address] <= data_in;
  end

  generate
    if (EFFECTIVE_LATENCY == 0) begin : NO_LATENCY
      always_comb begin
        if (ROM == 0 && chip_en == 1'b1)
          data_out = data[address];
        else if (ROM == 1 && chip_en == 1'b1)
          data_out = $signed(const_data[address]);
        else
          data_out = '{default: '0};
      end

      always_comb begin
        if (chip_en == 1'b1 && wr_en == 1'b0)
          data_valid = 1'b1;
        else
          data_valid = 1'b0;
      end
    end else begin : PIPELINED_LATENCY
      logic_vector read_pipe[0:EFFECTIVE_LATENCY-1];
      logic read_valid_pipe[0:EFFECTIVE_LATENCY-1];

      integer i;

      always_ff @(posedge clk) begin
        if (reset) begin
          for (i = 0; i < EFFECTIVE_LATENCY; i++) begin
            read_pipe[i] <= '{default: '0};
            read_valid_pipe[i] <= 1'b0;
          end
        end else begin
          for (i = EFFECTIVE_LATENCY-1; i > 0; i--) begin
            read_pipe[i] <= read_pipe[i-1];
            read_valid_pipe[i] <= read_valid_pipe[i-1];
          end
          if (chip_en == 1'b1 && wr_en == 1'b0) begin
            if (ROM == 1)
              read_pipe[0] <= $signed(const_data[address]);
            else
              read_pipe[0] <= data[address];
            read_valid_pipe[0] <= 1'b1;
          end else begin
            read_valid_pipe[0] <= 1'b0;
          end
        end
      end

      always_comb begin
        data_out = read_pipe[EFFECTIVE_LATENCY-1];
        data_valid = read_valid_pipe[EFFECTIVE_LATENCY-1];
      end
    end
  endgenerate

endmodule
