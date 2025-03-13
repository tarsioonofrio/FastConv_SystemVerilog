// -------------------------------------------------------------------------
// FAST CONVOLUTION  TB
// -------------------------------------------------------------------------
module tb;

   timeunit 1ns;
   timeprecision 1ps;

    import packConv::*;

    param36  weight;   
    param25 inputMAP;   
    param9  outputMAP;

    logic reset, start, data_valid;
    logic clk = 1'b0;

    // Quantized weights
    typedef int window_t[0:35];  // Define the 'window' type as an array of integers

    const window_t weights = '{
        0,  1,  2,   1,  2,   3, 
        3,  4,  5,   7,  8,   9,
        6,  7,  8,  13, 14,  15,
        3,  5,  7,   8, 10,  12,
        6,  8, 10,  14, 16,  18,
        9, 11, 13,  20, 22,  24
    };

    // 3 input maps
    typedef int window_IF[0:24];  // Define the 'window' type as an array of integers
    typedef window_IF maps_array_t[ ];  // Define the 'maps_array' type
    const maps_array_t MAPS = '{
        '{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24},
        '{9, 77, 56, -32, 4, 5, 6, 75, 8, 9, 10, 11, -10, -8, 14, 15, -20, 17, 18, 19, -44, 21, 22, 23, 122},
        '{18, 23, -45, -77, 21, 12, 63, 33, 90, -34, 23, 43, -56, -78, -16, 345, 46, -243, 101, -17, -34, -32, 33, -41, 201},
        '{100, -200, 300, -400, 500, 600, -700, 800, -900, 1000, 1100, -1200, 1300, -1400, 1500, 1600, -1700, 1800, -1900, 2000, 2100, -2200, 2300, -2400, 2500}
    };

`ifdef USE_NETLIST
               // Instância da entidade conv_rapida conforme o netlist
               conv_rapida convolucao (
                   .clk(clk),
                   .reset(reset),
                   .start(start),
                   .\inputMAP[24] (inputMAP[24]),
                   .\inputMAP[23] (inputMAP[23]),
                   .\inputMAP[22] (inputMAP[22]),
                   .\inputMAP[21] (inputMAP[21]),
                   .\inputMAP[20] (inputMAP[20]),
                   .\inputMAP[19] (inputMAP[19]),
                   .\inputMAP[18] (inputMAP[18]),
                   .\inputMAP[17] (inputMAP[17]),
                   .\inputMAP[16] (inputMAP[16]),
                   .\inputMAP[15] (inputMAP[15]),
                   .\inputMAP[14] (inputMAP[14]),
                   .\inputMAP[13] (inputMAP[13]),
                   .\inputMAP[12] (inputMAP[12]),
                   .\inputMAP[11] (inputMAP[11]),
                   .\inputMAP[10] (inputMAP[10]),
                   .\inputMAP[9]  (inputMAP[9]),
                   .\inputMAP[8]  (inputMAP[8]),
                   .\inputMAP[7]  (inputMAP[7]),
                   .\inputMAP[6]  (inputMAP[6]),
                   .\inputMAP[5]  (inputMAP[5]),
                   .\inputMAP[4]  (inputMAP[4]),
                   .\inputMAP[3]  (inputMAP[3]),
                   .\inputMAP[2]  (inputMAP[2]),
                   .\inputMAP[1]  (inputMAP[1]),
                   .\inputMAP[0]  (inputMAP[0]),
                   .\weights[35]  (weight[35]),
                   .\weights[34]  (weight[34]),
                   .\weights[33]  (weight[33]),
                   .\weights[32]  (weight[32]),
                   .\weights[31]  (weight[31]),
                   .\weights[30]  (weight[30]),
                   .\weights[29]  (weight[29]),
                   .\weights[28]  (weight[28]),
                   .\weights[27]  (weight[27]),
                   .\weights[26]  (weight[26]),
                   .\weights[25]  (weight[25]),
                   .\weights[24]  (weight[24]),
                   .\weights[23]  (weight[23]),
                   .\weights[22]  (weight[22]),
                   .\weights[21]  (weight[21]),
                   .\weights[20]  (weight[20]),
                   .\weights[19]  (weight[19]),
                   .\weights[18]  (weight[18]),
                   .\weights[17]  (weight[17]),
                   .\weights[16]  (weight[16]),
                   .\weights[15]  (weight[15]),
                   .\weights[14]  (weight[14]),
                   .\weights[13]  (weight[13]),
                   .\weights[12]  (weight[12]),
                   .\weights[11]  (weight[11]),
                   .\weights[10]  (weight[10]),
                   .\weights[9]   (weight[9]),
                   .\weights[8]   (weight[8]),
                   .\weights[7]   (weight[7]),
                   .\weights[6]   (weight[6]),
                   .\weights[5]   (weight[5]),
                   .\weights[4]   (weight[4]),
                   .\weights[3]   (weight[3]),
                   .\weights[2]   (weight[2]),
                   .\weights[1]   (weight[1]),
                   .\weights[0]   (weight[0]),
                   .\outputMAP[8] (outputMAP[8]),
                   .\outputMAP[7] (outputMAP[7]),
                   .\outputMAP[6] (outputMAP[6]),
                   .\outputMAP[5] (outputMAP[5]),
                   .\outputMAP[4] (outputMAP[4]),
                   .\outputMAP[3] (outputMAP[3]),
                   .\outputMAP[2] (outputMAP[2]),
                   .\outputMAP[1] (outputMAP[1]),
                   .\outputMAP[0] (outputMAP[0]),
                   .data_valid(data_valid)
               );
`else
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
`endif

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


    // Clock generation - 2 ns - 500 MHz
    always #1 clk = ~clk;

    // Convert weights 
    genvar i;
    generate
        for (i = 0; i < 36; i++) begin 
            assign weight[i] = (NBITS)'($signed(weights[i] *  256));   // quantizando.....  
            //assign weight[i] = (NBITS)'($signed(weights[i] ));   // quantizando.....  
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

