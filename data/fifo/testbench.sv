module tb;

  logic        clock;
  logic [15:0] data_in;
  logic [15:0] data_out;
  logic [15:0] rdata;
  logic        empty;
  logic        rd_en;
  logic        wr_en;
  logic        full;
  logic        reset;
  logic        stop;

  sync_fifo u_sync_fifo (
    .reset    (reset),
    .wr_en    (wr_en),
    .rd_en    (rd_en),
    .clock    (clock),
    .data_in  (data_in),
    .data_out (data_out),
    .empty    (empty),
    .full     (full)
  );

  always #10 clock <= ~clock;

  initial begin
    clock <= 0;
    reset <= 1;
    wr_en <= 0;
    rd_en <= 0;
    stop  <= 0;

    #50 reset <= 0;
  end

  initial begin
    @(posedge clock);

    for (int i = 0; i < 20; i = i + 1) begin
      // Wait until there is space in fifo
      while (full) begin
        @(posedge clock);
        $display("[%0t] FIFO is full, wait for reads to happen", $time);
      end

      // Drive new values into FIFO
      wr_en   <= $random;
      data_in <= $random;
      $display("[%0t] clock i=%0d wr_en=%0d data_in=0x%0h ", $time, i, wr_en, data_in);

      // Wait for next clock edge
      @(posedge clock);
    end

    stop = 1;
  end

  initial begin
    @(posedge clock);

    while (!stop) begin
      // Wait until there is data in fifo
      while (empty) begin
        rd_en <= 0;
        $display("[%0t] FIFO is empty, wait for writes to happen", $time);
        @(posedge clock);
      end

      // Sample new values from FIFO at random pace
      rd_en <= $random;
      @(posedge clock);
      rdata <= data_out;
      $display("[%0t] clock rd_en=%0d rdata=0x%0h ", $time, rd_en, rdata);
    end

    #500 $finish;
  end
endmodule
