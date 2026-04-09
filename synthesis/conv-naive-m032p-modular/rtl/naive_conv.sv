//-------------------------------------------------------------------------
// FERNANDO MORAES                                             October/2024
//-------------------------------------------------------------------------

//-------------------------------------------------------------------------
// NAIVE CONVOLUTION (MODULARIZED ALWAYS BLOCKS)
//-------------------------------------------------------------------------

typedef enum logic [1:0] {IDLE, MACS, MACE, END} state_type;

module ConvStateReg (
    input  logic      clk,
    input  logic      reset,
    input  state_type PE,
    output state_type EA
);
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            EA <= IDLE;
        end else begin
            EA <= PE;
        end
    end
endmodule

module ConvNextState (
    input  state_type EA,
    input  logic      start,
    input  logic      done_mac,
    input  logic [4:0] cont_conv,
    output state_type PE
);
    always_comb begin
        unique case (EA)
            IDLE:      PE = start ? MACS : IDLE;
            MACS:      PE = MACE;
            MACE:      PE = done_mac ? END : MACE;
            END:       PE = cont_conv == 5'd9 ? IDLE : MACS;
            default:   PE = IDLE;
        endcase
    end
endmodule

module ConvWindowCounters (
    input  logic      clk,
    input  logic      reset,
    input  state_type EA,
    output logic [4:0] row,
    output logic [4:0] col,
    output logic [4:0] cont_state
);
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            row <= 5'd0;
            col <= 5'd0;
            cont_state <= 5'd0;
        end else begin
            if (EA == IDLE || EA == END) begin
                cont_state <= 5'd0;
            end else begin
                cont_state <= cont_state + 5'd1;
            end

            if (EA == END) begin
                if (col < 5'd2) begin
                    col <= col + 5'd1;
                end else begin
                    col <= 5'd0;
                    if (row < 5'd2) begin
                        row <= row + 5'd1;
                    end else begin
                        row <= 5'd0;
                    end
                end
            end
        end
    end
endmodule

module ConvWindowSelect
    import packConv::*;
(
    input  type_input  inputMAP,
    input  logic [4:0] row,
    input  logic [4:0] col,
    output type_output inputs9
);
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
endmodule

module ConvOutputRegs
    import packConv::*;
(
    input  logic       clk,
    input  logic       reset,
    input  logic       done_mac,
    input  state_type  EA,
    input  logic_vector prod,
    output type_output outputMAP,
    output logic       data_valid,
    output logic [4:0] cont_conv
);
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            data_valid <= 1'b0;
            cont_conv <= 5'd0;
            outputMAP <= '{default: '0};
        end else begin
            if (done_mac) begin
                outputMAP[integer'(cont_conv)] <= prod;
                cont_conv <= cont_conv + 5'd1;
            end else if (EA == IDLE) begin
                cont_conv <= 5'd0;
            end

            if (cont_conv == 5'd9) begin
                data_valid <= 1'b1;
            end else begin
                data_valid <= 1'b0;
            end
        end
    end
endmodule

module Conv
    import packConv::*;
#(
    parameter int QUANT = 8
)
(
    input  logic      clk,
    input  logic      reset,
    input  logic      start,
    input  type_input inputMAP,
    input  type_weight weights,
    output type_output outputMAP,
    output logic      data_valid
);
    timeunit 1ns;
    timeprecision 1ps;

    type_output   inputs9;
    logic_vector  prod;
    logic [4:0]   cont_conv, row, col, cont_state;
    logic         start_mac, done_mac;
    state_type    EA, PE;

    ConvStateReg u_state_reg (
        .clk(clk),
        .reset(reset),
        .PE(PE),
        .EA(EA)
    );

    ConvNextState u_next_state (
        .EA(EA),
        .start(start),
        .done_mac(done_mac),
        .cont_conv(cont_conv),
        .PE(PE)
    );

    ConvWindowCounters u_window_counters (
        .clk(clk),
        .reset(reset),
        .EA(EA),
        .row(row),
        .col(col),
        .cont_state(cont_state)
    );

    ConvWindowSelect u_window_select (
        .inputMAP(inputMAP),
        .row(row),
        .col(col),
        .inputs9(inputs9)
    );

    ConvOutputRegs u_output_regs (
        .clk(clk),
        .reset(reset),
        .done_mac(done_mac),
        .EA(EA),
        .prod(prod),
        .outputMAP(outputMAP),
        .data_valid(data_valid),
        .cont_conv(cont_conv)
    );

    assign start_mac = (EA == MACS);

    macoperation macOp (
        .clk(clk),
        .reset(reset),
        .start(start_mac),
        .done(done_mac),
        .inputs9(inputs9),
        .weights9(weights),
        .P(prod)
    );
endmodule
