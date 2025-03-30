// -------------------------------------------------------------------------
// FAST CONVOLUTION  TB
// -------------------------------------------------------------------------
module tb;

   timeunit 1ns;
   timeprecision 1ps;

    import packConv::*;

    logic_vector[0:16] weight, inputMAP;
    logic_vector[0:4] outputMAP;

    logic reset, start, data_valid;
    logic clk = 1'b0;

    // Quantized weights
    // typedef int window_t[0:15];  // Define the 'window' type as an array of integers

    // Constants for weights (normalized, multiplied by 256)
    const int weights[] = '{
      0, -384, -128, -512,
      -1152, 2304, 768, 1920,
      -384, 768, 256, 640,
      -1536, 2688, 896, 2048
    };

    // 3 input maps
    // typedef window_t maps_array_t[ ];  // Define the 'maps_array' type
    const int MAPS[][] = '{
        '{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15}
    };

    // Instantiate conv_rapida entity
    conv_rapida #(
        .QUANT(8)
    ) convolucao (
        .clk(clk),
        .reset(reset),
        .start(start),
        .inputMAP(inputMAP),
        .weights(weight),
        .outputMAP(outputMAP),
        .data_valid(data_valid)
    );

    // print the expected output
    always @(posedge clk) begin
        if (data_valid) begin
            // Loop para imprimir os valores de outputMAP
            $display("Time: %0t | Data Valid: %b", $time, data_valid);
            $display("OutputMAP Values:");
            for (int i = 0; i < 4; i = i + 1) begin
                $display("outputMAP[%0d] = %d", i, ($signed(outputMAP[i])) );
            end
        end
    end


    // Clock generation - 10 ns
    always #5 clk = ~clk;

    // Convert weights
    genvar i;
    generate
        for (i = 0; i < 16; i++) begin
            assign weight[i] = (NBITS)'($signed(weights[i]));
        end
    endgenerate;

    // Test process to iterate over the input maps
    initial begin
        integer j, k;

        // Configurações iniciais
        $dumpfile("dump.vcd");  // Arquivo VCD para waveform
        $dumpvars(0, tb);

        // Monitor para debug
        $monitor("Time: %0t | start: %b | data_valid: %b  j:%0d", $time, start, data_valid, j);

        //clk = 0;
        reset = 1;
        #5 reset = 0;  // Liberar o reset após 5 ns

        // Loop de simulação
        for (j = 0; j <=  MAPS.size()-1; j++) begin
            for (k = 0; k < 16; k++) begin
                 inputMAP[k] = (NBITS)'($signed(MAPS[j][k]));
            end

            start = 1'b1;
            #10 start = 1'b0;

            wait(data_valid);

            #100;  // Wait for 100 ns
        end

        // Finalizar a simulação 200 ns após o loop
        #200 $finish;
    end


endmodule
