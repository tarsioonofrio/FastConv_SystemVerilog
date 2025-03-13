//-------------------------------------------------------------------------
// FERNANDO MORAES                                             October/2024
//-------------------------------------------------------------------------

//-------------------------------------------------------------------------
// NAIVE CONVOLUTION 
//-------------------------------------------------------------------------
module conv_standard
     import packConv::*;
  ( input  logic   clk, reset, start,
    input  param25 inputMAP,   
    input  param9  weights,    
    output param9  outputMAP,
    output logic   data_valid   
 );

   timeunit 1ns;
   timeprecision 1ps;

    param9  inputs9; 
    regC prod;
    logic [4:0] cont_conv, row, col, cont_state;   // 5 bits is enough
    logic start_mac, done_mac;

    typedef enum {IDLE, MACS, MACE, END} state_type;
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
            IDLE:      PE = start ? MACS : IDLE;
            MACS:      PE = MACE;
            MACE:      PE = done_mac ? END : MACE;
            END:       PE = cont_conv==9 ? IDLE : MACS;
        endcase
    end

    //
    // Data path
    //

   // 3x3 MAC operation
    macoperation macOp (
            .clk(clk), 
            .reset(reset),
            .start(start_mac),
            .done(done_mac),
            .inputs9(inputs9),
            .weights9(weights),
            .P(prod)
        );


    // sliding window to obtain a 3x3 window from the input windows and weights

    assign start_mac = (EA==MACS);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            row <= 5'd0;
            col <= 5'd0;
            cont_state <= 5'd0;

        end else begin

            if (EA==IDLE || EA==END) begin
                cont_state <= 5'd0;
            end else begin
                cont_state <= cont_state + 1;
            end

            if (EA==END) begin
                // update the sliding widow pointers
                if (col < 2) begin
                    col <= col + 1;  
                end else begin
                    col <= 0;       
                    if (row < 2) begin
                        row <= row + 1;  
                    end else begin
                        row <= 0;       
                    end
                end
             end
        end
    end
    
    // sliding window as a function of the row and col indices
    always_comb begin
        inputs9[0] = inputMAP[row * 5 + col];
        inputs9[1] = inputMAP[row * 5 + (col + 1)];
        inputs9[2] = inputMAP[row * 5 + (col + 2)];
        inputs9[3] = inputMAP[(row + 1) * 5 + col];
        inputs9[4] = inputMAP[(row + 1) * 5 + (col + 1)];
        inputs9[5] = inputMAP[(row + 1) * 5 + (col + 2)];
        inputs9[6] = inputMAP[(row + 2) * 5 + col];
        inputs9[7] = inputMAP[(row + 2) * 5 + (col + 1)];
        inputs9[8] = inputMAP[(row + 2) * 5 + (col + 2)];
    end


    // register outputMAP and valid
    always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        data_valid <= 0;
        cont_conv  <= 0;
        outputMAP <= '{default: '0};
    end else begin

        if (done_mac) begin
               outputMAP[integer'(cont_conv)] <= prod; 
               cont_conv <= cont_conv + 1;
        end else if (EA==IDLE) begin
               cont_conv <= 0;
        end 

        if (cont_conv==9) begin
            data_valid <= 1;
        end else begin
            data_valid <= 0;
        end

    end

end

endmodule

