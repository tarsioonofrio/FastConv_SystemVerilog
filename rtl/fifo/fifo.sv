module sync_fifo #(
  parameter SIZE  = 8,
  parameter NBITS = 16
) (
  input        reset,    // Active low reset
  input        clock,    // Clock
  input        wr_en,    // Write enable
  input        rd_en,    // Read enable
  input  [NBITS-1:0] data_in,   // Data written into FIFO
  output logic [NBITS-1:0] data_out,  // Data read from FIFO
  output       empty,    // FIFO is empty when high
  output       full      // FIFO is full when high
);

  logic [$clog2(SIZE)-1:0] write_addr;
  logic [$clog2(SIZE)-1:0] read_addr;

  logic [NBITS-1:0] fifo [SIZE];

  always @(posedge clock) begin
    if (reset) begin
      write_addr <= 0;
    end else begin
      if (wr_en & !full) begin
        fifo[write_addr] <= data_in;
        write_addr       <= write_addr + 1;
      end
    end
  end

  always @(posedge clock) begin
    if (reset) begin
      read_addr <= 0;
    end else begin
      if (rd_en & !empty) begin
        data_out <= fifo[read_addr];
        read_addr <= read_addr + 1;
      end
    end
  end

  assign full  = (write_addr + 1) == read_addr;
  assign empty = write_addr == read_addr;
endmodule
