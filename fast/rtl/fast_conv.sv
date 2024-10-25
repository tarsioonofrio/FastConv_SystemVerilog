//-------------------------------------------------------------------------
// FERNANDO MORAES                                             October/2024
//-------------------------------------------------------------------------

//-------------------------------------------------------------------------
// FAST CONVOLUTION 
//-------------------------------------------------------------------------
module conv_rapida
     import packConv::*;
 #(
    parameter int QUANT = 8 
  ) 
  ( input  logic   clk, reset, start,
    input  param25 inputMAP,   
    input  param25 weights,    
    output param9  outputMAP,
    output logic   data_valid   
 );

   timeunit 1ns;
   timeprecision 1ps;

    param25 registers, prodCSA1, produto; 
    param9 prodCSA2; 

    typedef enum {IDLE, WR_IFMAP, WR_MC, MALBL, MALBH, MAHBL, MAHBH, WR_MU, WR_OUT} state_type;
    state_type EA, PE;

    mul_states mulState;

    logic wen;

    //
    // Control FSM
    //
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            EA <= IDLE;
        end else begin
            EA <= PE;
        end
    end

    always_comb begin
        unique case (EA)
            IDLE:      PE = start ? WR_IFMAP : IDLE;
            WR_IFMAP:  PE = WR_MC;
            WR_MC:     PE = MALBL;

            // four state multiplier           
            MALBL:     PE = MALBH;    
            MALBH:     PE = MAHBL;
            MAHBL:     PE = MAHBH; 
            MAHBH:     PE = WR_MU;

            // store de multiplication resulta
            WR_MU:     PE = WR_OUT;

            //MMMA:      PE = WR_OUT; 
            WR_OUT:    PE = IDLE;
        endcase
    end

    //
    // Data path
    //

    // Instance of matrix multiplier "C"
    MatrixC mult_matrix_C(
        .P(registers), 
        .soma(prodCSA1)
    );



   // 25 multipliers : NBITS (quantized weights) x NBITS (features) (in fact 25 multipliers of NBITS/2)
    generate
      genvar m;
      for (m=0; m<=24; m=m+1) begin
         mult_iterate  #(
        .QUANT(QUANT)  
        )  mult (
            .clk(clk), 
            .reset(reset),
            .state(mulState), 
            .A(registers[m]), 
            .B(weights[m]),
            .P(produto[m])
        );
      end
   endgenerate


    // Instance of matrix multiplier "A"
    MatrixA mult_matrix_A (
        .P(registers), 
        .soma(prodCSA2)
    );


    // signal to write in the register bank
    assign wen = EA inside {WR_IFMAP, WR_MC, WR_MU, WR_OUT} ? 1 : 0;

    // Internal register bank to store intermediate results
    always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        registers <= '{default: '0};
        data_valid <= 0;
    end 
    else begin
           data_valid <= 0;  // default
           if (wen) begin
               unique case (EA)
                   WR_IFMAP:   registers <= inputMAP;
                   WR_MC:      registers <= prodCSA1;
                   WR_MU:      registers <= produto;
                   WR_OUT: begin
                       data_valid <= 1;
                       for (int i = 0; i < 9; i++) 
                           registers[i] <= prodCSA2[i];
                       end
               endcase
           end
        end
     end

    // states for the 'n'  multipliers
    always_comb 
    begin
          unique case (EA)
              MALBL: mulState = ALBL;
              MALBH: mulState = ALBH;
              MAHBL: mulState = AHBL;
              MAHBH: mulState = AHBH;
              default: mulState = ALBL;
          endcase
    end

    // connect 9 first registers to the outputs
    always_comb
    begin
        for (int i = 0; i <9; i++) begin
            outputMAP[i] = registers[i];
        end
    end

endmodule

