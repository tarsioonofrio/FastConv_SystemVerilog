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
    input  param16 inputMAP,   
    input  param16 weights,    
    output param4  outputMAP,
    output logic   data_valid   
 );

   timeunit 1ns;
   timeprecision 1ps;

    param16 registers, prodCSA1; 
    param8 prodCSA2; 

    logic signed [NBITS-1+QUANT:0] partial_product [0:4];   // QUANT more bits for the multipliers

    logic [4:0] m0, m1, m2, m3;

    typedef enum {IDLE, WR_IFMAP, WR_MC, MU1, MU2, MU3, MU4, WR_OUT} state_type;

    state_type EA, PE;

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
            WR_MC:     PE = MU1;

            // five state multiplier           
            MU1:     PE = MU2;    
            MU2:     PE = MU3;
            MU3:     PE = MU4; 
            MU4:     PE = WR_OUT;

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


   // 5 multipliers inside this block
    always_comb begin

          unique case (EA)
                MU1: begin m0=  0; m1=  1; m2= 2;  m3= 3; end
                MU2: begin m0=  4; m1=  5; m2= 6;  m3= 7; end
                MU3: begin m0=  8; m1=  9; m2= 10; m3=11; end
                MU4: begin m0= 12; m1= 13; m2=14;  m3=15; end
         endcase

          partial_product[0] = (NBITS+QUANT)'($signed(registers[m0]) * $signed(weights[m0]) );
          partial_product[1] = (NBITS+QUANT)'($signed(registers[m1]) * $signed(weights[m1]) );
          partial_product[2] = (NBITS+QUANT)'($signed(registers[m2]) * $signed(weights[m2]) );
          partial_product[3] = (NBITS+QUANT)'($signed(registers[m3]) * $signed(weights[m3]) );

    end


    // Instance of matrix multiplier "A"
    MatrixA mult_matrix_A (
        .P(registers), 
        .soma(prodCSA2)
    );


    // Internal register bank to store intermediate results
    always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        registers <= '{default: '0};
        //outputMAP <= '{default: '0};
        data_valid <= 0;
    end 
    else begin
           data_valid <= 0;  // default
               unique case (EA)
                   WR_IFMAP:   registers <= inputMAP;

                   WR_MC:      registers <= prodCSA1;

                   MU1, MU2, MU3, MU4:  begin
                              registers[m0] <= (NBITS)'(partial_product[0][NBITS-1+QUANT:QUANT]);
                              registers[m1] <= (NBITS)'(partial_product[1][NBITS-1+QUANT:QUANT]);
                              registers[m2] <= (NBITS)'(partial_product[2][NBITS-1+QUANT:QUANT]);
                              registers[m3] <= (NBITS)'(partial_product[3][NBITS-1+QUANT:QUANT]);
                        end

                   WR_OUT: //begin
                       data_valid <= 1;
                    //  for (int i = 0; i < 9; i++) 
                    //      outputMAP[i] <= prodCSA2[i];   /// saída registrada
                    //  end
               endcase
        end
     end

    always_latch begin
      if (EA==WR_OUT) begin
           for (int i = 0; i < 9; i++) 
                 outputMAP[i] = prodCSA2[i];   /// saída em latch
          end
    end

endmodule

