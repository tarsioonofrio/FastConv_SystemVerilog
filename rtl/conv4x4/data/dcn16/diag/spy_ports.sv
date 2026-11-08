module spy;
  integer f;
  initial f = $fopen("trace.txt", "w");
  always @(posedge tb_stream_column.clk)
    if (tb_stream_column.reset === 1'b0)
      $fwrite(f, "%0t %b %h %b %b %b %h %h\n", $time, tb_stream_column.p_input_en, tb_stream_column.p_input_addr,
              tb_stream_column.p_output_en, tb_stream_column.p_output_wr, tb_stream_column.p_end,
              tb_stream_column.p_output_addr, tb_stream_column.p_output_data_write);
endmodule
