// -------------------------------------------------------------------------
// CONVOLUTION  TB
// -------------------------------------------------------------------------
module tb;
  import pack_data::*;
  import pack_def::*;
  import pack_typedef::*;

  timeunit 1ns;
  timeprecision 1ps;

  parameter int SIZE1 = FIN1_SIZE;
  parameter int SIZE2 = FIN2_SIZE;
  parameter int NADDR = $clog2(SIZE1 * SIZE2);
  parameter int ROM = 0;
  parameter int DATA = 0;
  parameter int DEBUG = 0;
  parameter int LATENCY = 3;

  function automatic int data_test(int row, int col);
    case (DATA)
      0:  return const_feat_in[row][col];
      1:  return const_weight[row][col];
      default:  return 0;
    endcase
  endfunction
  // type_weight data_test;
  // type_output data_test;


  // function automatic int fn(ref int a);
  //   a = a + 5;
  //   return a * 10;
  // endfunction


  // function void convert2signed(logic_vector in_put, logic_vector output, int row, int col);
  //   for (int r = 0; r < row; r++) begin
  //     for (int c = 0; c < col; c++) begin
  //       output[c] = (NBITS)'($signed(in_put[r][c]));
  //     end
  //   end
  // endfunction


  logic reset, start, data_valid;
  logic[NADDR-1:0] address;
  logic_vector  data_in, data_out;
  logic chip_en, wr_en;
  int row, col;

  logic clk = 1'b0;

  // Instantiate conv_rapida entity
  Memory #(
    .NADDR(NADDR),
    .NBITS(NBITS),
    .LATENCY(LATENCY),
    .ROM(ROM)
  ) memory (
    .clk(clk),
    .reset(reset),
    .chip_en(chip_en),
    .wr_en(wr_en),
    .address(address),
    .data_in(data_in),
    .data_out(data_out),
    .data_valid(data_valid)
  );


  // Clock generation - 10 ns
  always #1 clk = ~clk;

  // Test process to iterate over the input maps
  initial begin

    // Configurações iniciais
    $dumpfile("dump.vcd");  // Arquivo VCD para waveform
    $dumpvars(0, tb);

    // Monitor para debug
    // $monitor("** Time: %0t | start: %b | data_valid: %b", $time, start, data_valid);


    //clk = 0;
    start = 0;
    reset = 1;
    chip_en = 0;
    wr_en = 0;
    #5
    reset = 0;  // Liberar o reset após 5 ns

    // Loop de simulação
    if (ROM == 0) begin
      chip_en = 1;
      wr_en = 1;
      for (row = 0; row < FIN1_SIZE; row++) begin
        for (col = 0; col < FIN2_SIZE; col++) begin
          address = row*FIN1_SIZE + col;
          data_in = (NBITS)'($signed(const_feat_in[row][col]));
          #2;
        end
      end
    end

    wr_en = 0;
    for (row = 0; row < FIN1_SIZE; row++) begin
      for (col = 0; col < FIN2_SIZE; col++) begin
        chip_en = 1;
        address = row*FIN1_SIZE + col;
        #2;
        wait(data_valid);
        #2;
      end
    end

    // Finalizar a simulação 200 ns após o loop
    #10 $finish;
  end


  always @(posedge clk) begin
    if (data_valid) begin
      // #1; // espera propagação de sinal
      // To avoid error:
      // %Warning-WIDTHEXPAND: ../../testbench/tb_conv.sv:79:36: Operator NEQ expects 32 bits on the LHS, but LHS's SIGNED generates 20 bits.
      /* verilator lint_off WIDTHEXPAND */
      if ($signed(data_out) != $signed(data_test(row, col))) begin
        /* verilator lint_off WIDTHEXPAND */
        // $display("Time: %0t | Data Valid: %b", $time, data_valid);
        $display(
          "Values Error: Time %0t | Data Valid: %b | data_test[%0d][%0d] = %d != %d",
          $time, data_valid,
          row, col, $signed(data_test(row, col)), $signed(data_out)
        );
      end
      if (DEBUG == 1) begin
        /* verilator lint_off WIDTHEXPAND */
        // $display("Time: %0t | Data Valid: %b", $time, data_valid);
        $display(
          "Values: Time %0t | Data Valid: %b | data_test[%0d][%0d]  %d | outputMAP = %d",
          $time, data_valid,
          row, col, $signed(data_test(row, col)), $signed(data_out)
        );
      end
    end
  end


endmodule
