// -------------------------------------------------------------------------
// FAST CONVOLUTION  TB
// -------------------------------------------------------------------------
module tb;

   timeunit 1ns;
   timeprecision 1ps;

    import packConv::*;

    param25 weight, inputMAP;   
    param9  outputMAP;

    logic reset, start, data_valid;
    logic clk = 1'b0;

    // Quantized weights
    typedef int window_t[0:24];  // Define the 'window' type as an array of integers

    // Constants for weights (normalized, multiplied by 256)
    const window_t weights = '{
        0, -192, -22, 213, 256, -576, 2304, 256, -1984, -1920, 
        -64, 256, 28, -221, -214, 640, -2368, -264, 1991, 1877,
        768, -2688, -299, 2218, 2048
    };

    // 3 input maps
    typedef window_t maps_array_t[ ];  // Define the 'maps_array' type
    const maps_array_t MAPS = '{
        '{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24},
        '{9, 77, 56, -32, 4, 5, 6, 75, 8, 9, 10, 11, -10, -8, 14, 15, -20, 17, 18, 19, -44, 21, 22, 23, 122},
        '{18, 23, -45, -77, 21, 12, 63, 33, 90, -34, 23, 43, -56, -78, -16, 345, 46, -243, 101, -17, -34, -32, 33, -41, 201},
        '{100, -200, 300, -400, 500, 600, -700, 800, -900, 1000, 1100, -1200, 1300, -1400, 1500, 1600, -1700, 1800, -1900, 2000, 2100, -2200, 2300, -2400, 2500}
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
            for (int i = 0; i < 9; i = i + 1) begin
                $display("outputMAP[%0d] = %d", i, ($signed(outputMAP[i])) );
            end
        end
    end


    // Clock generation - 10 ns
    always #5 clk = ~clk;

    // Convert weights 
    genvar i;
    generate
        for (i = 0; i <= 24; i++) begin 
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
            for (k = 0; k <= 24; k++) begin      
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

