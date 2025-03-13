//-------------------------------------------------------------------------
// FERNANDO MORAES                                          24/October/2024
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
    input  param36 weights,    
    output param9  outputMAP,
    output logic   data_valid   
 );

   timeunit 1ns;
   timeprecision 1ps;

    param36 registers, prodCSA1; 
    param9 prodCSA2; 

    logic signed [NBITS-1+QUANT:0] partial_product [0:5];   // QUANT more bits for the multipliers

    logic [5:0] m0, m1, m2, m3, m4, m5;

    // up to 16 states
    typedef enum logic [3:0] {IDLE, WR_IFMAP, WR_MC, MU1, MU2, MU3, MU4, MU5, MU6, WR_OUT} state_type;
    state_type EA, PE;

    //
    // Control FSM
    //
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            EA <= IDLE;
        end else begin
            if (start) begin      // START signal starts the FSM
                EA <= WR_IFMAP;
            end else begin
                EA <= PE;
            end
        end
    end

    always_comb begin    // 9 states + IDEL - IDLE is blocking!
        unique case (EA)
            WR_IFMAP:  PE = WR_MC;
            WR_MC:     PE = MU1;
            MU1:       PE = MU2;    
            MU2:       PE = MU3;
            MU3:       PE = MU4; 
            MU4:       PE = MU5;
            MU5:       PE = MU6;
            MU6:       PE = WR_OUT;
            WR_OUT:    PE = IDLE;
            default:   PE = IDLE;
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
                MU1: begin m0= 0; m1= 1; m2= 2;  m3= 3; m4= 4; m5= 5; end
                MU2: begin m0= 6; m1= 7; m2= 8;  m3= 9; m4=10; m5=11; end
                MU3: begin m0=12; m1=13; m2=14;  m3=15; m4=16; m5=17; end
                MU4: begin m0=18; m1=19; m2=20;  m3=21; m4=22; m5=23; end
                MU5: begin m0=24; m1=25; m2=26;  m3=27; m4=28; m5=29; end
                default: begin m0=30; m1=31; m2=32;  m3=33; m4=34; m5=35; end

         endcase

          partial_product[0] = (NBITS+QUANT)'($signed(registers[m0]) * $signed(weights[m0]) );
          partial_product[1] = (NBITS+QUANT)'($signed(registers[m1]) * $signed(weights[m1]) );
          partial_product[2] = (NBITS+QUANT)'($signed(registers[m2]) * $signed(weights[m2]) );
          partial_product[3] = (NBITS+QUANT)'($signed(registers[m3]) * $signed(weights[m3]) );
          partial_product[4] = (NBITS+QUANT)'($signed(registers[m4]) * $signed(weights[m4]) );
          partial_product[5] = (NBITS+QUANT)'($signed(registers[m5]) * $signed(weights[m5]) );
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
        data_valid <= 0;
    end 
    else begin
           data_valid <= 0;  // default
               unique case (EA)
                   WR_IFMAP:    for (int i = 0; i <25; i++) begin    /// store the IFMAP
                                    registers[i] <= inputMAP[i];
                                end

                   WR_MC:      registers <= prodCSA1;

                   MU1, MU2, MU3, MU4, MU5, MU6:  begin
                              registers[m0] <= (NBITS)'(partial_product[0][NBITS-1+QUANT:QUANT]);
                              registers[m1] <= (NBITS)'(partial_product[1][NBITS-1+QUANT:QUANT]);
                              registers[m2] <= (NBITS)'(partial_product[2][NBITS-1+QUANT:QUANT]);
                              registers[m3] <= (NBITS)'(partial_product[3][NBITS-1+QUANT:QUANT]);
                              registers[m4] <= (NBITS)'(partial_product[4][NBITS-1+QUANT:QUANT]); 
                              registers[m5] <= (NBITS)'(partial_product[5][NBITS-1+QUANT:QUANT]); 
                        end

                   WR_OUT: begin
                       data_valid <= 1;
                       for (int i = 0; i < 9; i++) 
                           registers[i] <= prodCSA2[i];
                       end

		          default: begin   // necessary - wrong behavior in logic simulation
                    registers <= registers;
                  end

               endcase
        end
     end

    // connect 9 first registers to the outputs
    always_comb
    begin
        for (int i = 0; i <9; i++) begin
            outputMAP[i] = registers[i];
        end
    end

endmodule

