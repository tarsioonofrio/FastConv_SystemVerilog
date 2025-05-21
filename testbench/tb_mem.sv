// -------------------------------------------------------------------------
// CONVOLUTION  TB
// -------------------------------------------------------------------------
module tb;
  parameter int NADDR = 8;
  logic DEBUG = 0;

  timeunit 1ns;
  timeprecision 1ps;

  import packConv::*;
  import data::*;


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

  type_weight weight;
  type_input inputMAP;
  type_output outputMAP;

  logic reset, start, data_valid;
  logic[2**NADDR-1:0] address;
  logic_vector  data_in, data_out;
  logic chip_en_ram, wr_en_ram;
  logic chip_en_rom_feat, wr_en_rom_feat;
  logic chip_en_rom_wght, wr_en_rom_wght;

  logic clk = 1'b0;
  int fi;

  // Instantiate conv_rapida entity
  Memory #(
    .NADDR(NADDR),
    .NBITS(NBITS),
    .LATENCY(0),
    .ROM(0)
  ) ram (
    .clk(clk),
    .reset(reset),
    .chip_en(chip_en_ram),
    .wr_en(wr_en_ram),
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
    chip_en_ram = 0;
    wr_en_ram = 0;
    #5
    reset = 0;  // Liberar o reset após 5 ns

    // // Convert const_weight
    // for (int wi = 0; wi < W1_SIZE; wi++) begin
    //   for (int wj = 0; wj < W2_SIZE; wj++) begin
    //     weight[wj] = (NBITS)'($signed(const_weight[wi][wj]));
    //   end

    // Loop de simulação
    chip_en_ram = 1;
    wr_en_ram = 1;
    for (fi = 0; fi < FIN1_SIZE; fi++) begin
      for (int fj = 0; fj < FIN2_SIZE; fj++) begin
        address = fi*FIN1_SIZE + fj;
        data_in = (NBITS)'($signed(const_feat_in[fi][fj]));
        #10;
      end
    end

    // Finalizar a simulação 200 ns após o loop
    #10 $finish;
  end


  always @(posedge clk) begin
    if (data_valid) begin
      // #1; // espera propagação de sinal
      for (int fj = 0; fj < FOUT2_SIZE; fj++) begin
        // To avoid error:
        // %Warning-WIDTHEXPAND: ../../testbench/tb_conv.sv:79:36: Operator NEQ expects 32 bits on the LHS, but LHS's SIGNED generates 20 bits.
        /* verilator lint_off WIDTHEXPAND */
        if ($signed(outputMAP[fj]) != $signed(const_feat_out[fi][fj])) begin
          /* verilator lint_off WIDTHEXPAND */
          // $display("Time: %0t | Data Valid: %b", $time, data_valid);
          $display(
            "Values Error: Time %0t | Data Valid: %b | const_feat_out[%0d][%0d] = %d != %d",
            $time, data_valid,
            fi, fj, $signed(const_feat_out[fi][fj]), $signed(outputMAP[fj])
          );
        end
        if (DEBUG == 1) begin
          /* verilator lint_off WIDTHEXPAND */
          // $display("Time: %0t | Data Valid: %b", $time, data_valid);
          $display(
            "Values: Time %0t | Data Valid: %b | const_feat_out[%0d][%0d]  %d | outputMAP = %d",
            $time, data_valid,
            fi, fj, $signed(const_feat_out[fi][fj]), $signed(outputMAP[fj])
          );
        end

      end
    end
  end


endmodule
