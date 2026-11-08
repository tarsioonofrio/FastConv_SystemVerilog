module spy;
  integer f;
  initial f = $fopen("trace.txt", "w");
  always @(posedge tb_stream_column.clk)
    if (tb_stream_column.reset === 1'b0) begin
      $fwrite(f, "%0t", $time);
      $fwrite(f, " %h", tb_stream_column.dut.r_weight_spatial[0]);
      $fwrite(f, " %h", tb_stream_column.dut.r_weight_spatial[1]);
      $fwrite(f, " %h", tb_stream_column.dut.r_weight_spatial[2]);
      $fwrite(f, " %h", tb_stream_column.dut.r_weight_spatial[3]);
      $fwrite(f, " %h", tb_stream_column.dut.r_weight_spatial[4]);
      $fwrite(f, " %h", tb_stream_column.dut.r_weight_spatial[5]);
      $fwrite(f, " %h", tb_stream_column.dut.r_weight_spatial[6]);
      $fwrite(f, " %h", tb_stream_column.dut.r_weight_spatial[7]);
      $fwrite(f, " %h", tb_stream_column.dut.r_weight_spatial[8]);
      $fwrite(f, " %h", tb_stream_column.dut.r_input_weight[0]);
      $fwrite(f, " %h", tb_stream_column.dut.r_input_weight[1]);
      $fwrite(f, " %h", tb_stream_column.dut.r_input_weight[2]);
      $fwrite(f, " %h", tb_stream_column.dut.r_input_weight[12]);
      $fwrite(f, " %h", tb_stream_column.dut.r_input_weight[13]);
      $fwrite(f, " %h", tb_stream_column.dut.r_input_weight[14]);
      $fwrite(f, " %h", tb_stream_column.dut.r_input_weight[24]);
      $fwrite(f, " %h", tb_stream_column.dut.r_input_weight[25]);
      $fwrite(f, " %h", tb_stream_column.dut.r_input_weight[26]);
      $fwrite(f, "\n");
    end
endmodule
