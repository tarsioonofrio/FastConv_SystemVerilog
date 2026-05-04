/*
   CONVOLUTION CONTROLLER  - (V0 - FERNANDO MORAES)  - 24/ABRIL
*/
`timescale 1ns/1ps

module Control #(
    parameter int unsigned N_CHANNEL_IN        =  2,
    parameter int unsigned N_CHANNEL_OUT        =  3,
    parameter int unsigned KERNEL_SIZE       =  5,
    parameter int unsigned FEAT_INPUT_SIZE        =  17,
    parameter int unsigned FEAT_INPUT_WIDTH      =  8,
    parameter int unsigned NADDR          =  18,   // bits to p_input_addr the memory
    parameter int unsigned CONV_MULTIPLY_STEPS      =  6     // multiplication steps
 )(
    input  logic clk,
    input  logic reset,
    input  logic p_start,
    output logic p_end,

    output logic [NADDR-1:0] p_input_addr,
    input  logic [19:0] p_input_data
);
    logic [19:0] r_feat_input[0:24];        // input feature register bank
    logic [19:0] r_conv_input[0:24];        // convolution input register bank
    logic [19:0] w_next_feat_input[0:24];   // next values for feature shift bank
    logic [24:0] w_feat_input_write_en;     // write-enable per feature register
    logic w_conv_end, last_line, last_input, last_output;
    logic [3:0] r_output_read_count, r_output_write_count;
    logic [NADDR-1:0] r_addr_pointer_input, r_window_row_step, r_addr_pointer_kernel;

    localparam CHANNEL_INPUT_COUNTER_WIDTH = $clog2(N_CHANNEL_IN) + 1;
    logic [CHANNEL_INPUT_COUNTER_WIDTH-1:0] r_channel_counter_input;

    localparam CHANNEL_OUTPUT_COUNTER_WIDTH = $clog2(N_CHANNEL_OUT) + 1;
    logic [CHANNEL_OUTPUT_COUNTER_WIDTH-1:0] r_channel_counter_output;

    localparam WINDOW_COUNT_PER_LINE =  FEAT_INPUT_SIZE / 3;            // assuming output 3x3
    localparam WINDOW_COUNT_PER_COLUMN =  FEAT_INPUT_WIDTH / 3;
    localparam WINDOW_COUNT_PER_CHANNEL =  WINDOW_COUNT_PER_LINE * WINDOW_COUNT_PER_COLUMN;

    localparam WINDOW_COUNTER_WIDTH = $clog2(WINDOW_COUNT_PER_LINE*WINDOW_COUNT_PER_COLUMN);
    logic [WINDOW_COUNTER_WIDTH-1:0] r_window_counter_input;

    localparam WINDOW_ROW_COUNTER_WIDTH = $clog2(WINDOW_COUNT_PER_LINE) + 1;
    logic [WINDOW_ROW_COUNTER_WIDTH-1:0] r_window_counter_row;

    localparam ADDR_INPUT_COUNTER_WIDTH = $clog2(WINDOW_COUNT_PER_COLUMN) + 1;
    logic [ADDR_INPUT_COUNTER_WIDTH-1:0] w_base_feat_input, r_addr_count_input;

    // REGISTER BANK FOR THE WEIGHTS ////////////////////////////////////////////
    localparam int WEIGHT_CYCLES = KERNEL_SIZE * KERNEL_SIZE;
    localparam int WEIGHT_WIDTH      = $clog2(WEIGHT_CYCLES);
    logic [19:0] weight_reg[0:WEIGHT_CYCLES-1];
    logic [WEIGHT_CYCLES-1:0] w_weight_write_en;
    logic [WEIGHT_WIDTH-1:0] r_addr_count_kernel;
    logic w_weight_done, w_write_done;

    // -------------------------------------------------------------------------
    // FSM STATES DECLARION
    // -------------------------------------------------------------------------
    typedef enum logic [3:0] { WAIT, AP,  READ_WEIGHTS, READ_IN_10A, READ_IN_10B, READ_IN_15A, READ_IN_15B, READ_IN_15C, HOLD_WRITE, TRANSFER, NEXT_ROW} state_read_t;
    state_read_t r_state_read_curr, r_state_read_next;

    typedef enum logic [1:0] { WAIT_CONV, TRANSFORM,  HADAMARD, INVERSE  } state_conv_t;
    state_conv_t r_state_conv_curr, r_state_conv_next;

    typedef enum logic [2:0] { WAIT_WRITE,  RESET9,  READ_OUTPUT, WRITE_OUTPUT } state_write_t;
    state_write_t r_state_write_curr, r_state_write_next;

    // ----------------------------------------------------------------------------------------------------
    // -------  PART 1 - ADDRESS TO ACCESS THE IFMAP AND WEIGHT MEMORY ------------------------------------
    // ----------------------------------------------------------------------------------------------------
    assign p_input_addr = (r_state_read_curr==READ_WEIGHTS) ? r_addr_pointer_kernel : r_addr_pointer_input + NADDR'(r_addr_count_input);   // p_input_addr mux

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            r_addr_pointer_input <= '0;
            r_window_row_step <= 3;
        end
        else if ((r_state_read_curr==READ_IN_10A && r_state_read_next==READ_IN_10B) || (r_state_read_curr==READ_IN_10B && r_state_read_next==READ_IN_15A) || (r_state_read_curr==READ_IN_15A && r_state_read_next==READ_IN_15B) || (r_state_read_curr==READ_IN_15B && r_state_read_next==READ_IN_15C) || r_state_read_curr==TRANSFER)
            r_addr_pointer_input <= r_addr_pointer_input + NADDR'(FEAT_INPUT_WIDTH);    // change internal p_input_addr in the state transition or in the TRANSFER state (CAUTION: PE)

        else if (r_state_read_curr==NEXT_ROW  &&  !last_input) begin     // when change the line, the read pointer moves 'r_window_row_step'
            r_addr_pointer_input <= r_window_row_step + NADDR'(r_channel_counter_input*FEAT_INPUT_SIZE*FEAT_INPUT_WIDTH);   // restart for the first line
            r_window_row_step  <= r_window_row_step  + 3;
        end

        else if (r_state_read_curr==AP && last_input ) begin
            r_addr_pointer_input <= r_addr_pointer_input - NADDR'(FEAT_INPUT_WIDTH) + NADDR'(KERNEL_SIZE);   // adjust the pointer to the next IFMAP
            r_window_row_step <= 3;

            if (r_channel_counter_input == CHANNEL_INPUT_COUNTER_WIDTH'(N_CHANNEL_IN-1) ) begin               // change the IFMAP
`ifdef SIMULATION
                $display("RESETANDO PARA O CANAL 0 - DEU A VOLTA NOS IFMAPS time=%0t %d (%0d) r_state_read_curr = %s", $time, r_channel_counter_input, N_CHANNEL_IN, r_state_read_curr.name());

`endif
                r_addr_pointer_input <= 0;
            end
       end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            r_addr_pointer_kernel <= 0;
        end
        else if (r_state_read_curr == WAIT && r_state_read_next == AP)    // initializes only ONCE the weight p_input_addr (after the IFMAPs in the memory) (CAUTION: PE)
                r_addr_pointer_kernel <=  NADDR'(N_CHANNEL_IN * FEAT_INPUT_SIZE * FEAT_INPUT_WIDTH);
        else if (r_state_read_curr == READ_WEIGHTS)
                r_addr_pointer_kernel <= r_addr_pointer_kernel + 1;   // next weight
    end

    // ----------------------------------------------------------------------------------------------------
    // -------  PART 2 - READ FSM AND REGISTERS -----------------------------------------------------------
    // ----------------------------------------------------------------------------------------------------
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            r_state_read_curr <= WAIT;
        else
            r_state_read_curr <= r_state_read_next;
    end

    always_comb begin
        r_state_read_next = r_state_read_curr;
        priority case (r_state_read_curr)
            WAIT:         if (p_start)           r_state_read_next = AP;
            AP:                                r_state_read_next = READ_WEIGHTS;
            READ_WEIGHTS:  if (w_weight_done)    r_state_read_next = READ_IN_10A;
                           else if (last_output) r_state_read_next = WAIT;        //end processing
            READ_IN_10A:        if (r_addr_count_input == 4)     r_state_read_next = READ_IN_10B;        // read 5*5 values
            READ_IN_10B:        if (r_addr_count_input == 4)     r_state_read_next = READ_IN_15A;
            READ_IN_15A:        if (r_addr_count_input == 4)     r_state_read_next = READ_IN_15B;
            READ_IN_15B:        if (r_addr_count_input == 4)     r_state_read_next = READ_IN_15C;
            READ_IN_15C:        if (r_addr_count_input == 4)     r_state_read_next = TRANSFER;
            TRANSFER:        r_state_read_next = HOLD_WRITE;                     // p_start the convolution
            HOLD_WRITE:     if (last_line && w_write_done)  r_state_read_next = NEXT_ROW;
                         else  if (w_write_done)         r_state_read_next = READ_IN_15A;
                         else                                 r_state_read_next = HOLD_WRITE;
            NEXT_ROW: if (last_input) r_state_read_next = AP;
                            else        r_state_read_next = READ_IN_10A;
            default:    r_state_read_next = WAIT;
        endcase
    end

    assign w_weight_done       = (r_addr_count_kernel == WEIGHT_WIDTH'(WEIGHT_CYCLES-1));
    assign w_write_done = r_output_write_count==0 || r_output_write_count==8;        // compare to zero for the first write test or the last value (8) in the next convolutions
    assign last_line         = (r_window_counter_row == WINDOW_ROW_COUNTER_WIDTH'(WINDOW_COUNT_PER_LINE));
    assign last_input         = (r_window_counter_input == WINDOW_COUNTER_WIDTH'(WINDOW_COUNT_PER_CHANNEL));
    assign last_output         = (r_channel_counter_output == CHANNEL_OUTPUT_COUNTER_WIDTH'(N_CHANNEL_OUT));

    assign p_end = ((r_state_write_next == WAIT_WRITE && last_output));  // output to signalize the end of the convolution process

    // -------------------------------------------------------------------------
    // READING REGISTERS
    // -------------------------------------------------------------------------

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            r_addr_count_input <= 0;
        end else begin
            if (r_state_read_curr == READ_WEIGHTS) begin
                r_addr_count_input <= 0;
            end
            else if (r_state_read_curr inside {READ_IN_10A, READ_IN_10B, READ_IN_15A, READ_IN_15B, READ_IN_15C}) begin
                if (r_addr_count_input == 4)
                    r_addr_count_input <= 0;
                else
                    r_addr_count_input <= r_addr_count_input + 1;
            end
        end
    end

     assign w_base_feat_input = (r_state_read_curr == READ_IN_10A) ? 0 :
                       (r_state_read_curr == READ_IN_10B) ? 1 :
                       (r_state_read_curr == READ_IN_15A) ? 2 :
                       (r_state_read_curr == READ_IN_15B) ? 3 :
                       (r_state_read_curr == READ_IN_15C) ? 4 :  0;


    // SET OF FIVE CONTROL REGISTERS:
    // r_channel_counter_input: number of the current IFMAP channel being read
    // r_channel_counter_output: number of the current OFMAP channel being processed
    // r_window_counter_input:  number of convolutions in a given IFMAP channel
    // r_window_counter_row :  number of horizontal convolutions in a given IFMAP channel - detect the last line
    // r_addr_count_kernel:        number of weights read from memory
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            r_channel_counter_input  <= '1;  // p_start with all bits in '1' - IFchannel must be {0,1,2}
            r_channel_counter_output  <= 0;
            r_window_counter_input   <= 0;
            r_window_counter_row    <= 0;
            r_addr_count_kernel         <= 0;
        end else begin
            if (r_state_read_curr == AP) begin

                if (r_channel_counter_input == CHANNEL_INPUT_COUNTER_WIDTH'(N_CHANNEL_IN-1)) begin
                    r_channel_counter_input <= '0;
                    r_channel_counter_output <= r_channel_counter_output + 1;
                end
                else begin
                    r_channel_counter_input <= r_channel_counter_input + 1;
                end
                r_window_counter_input <= 0;    // reset counters
                r_window_counter_row  <= 0;
                r_addr_count_kernel       <= 0;
            end

            if (r_state_read_curr == NEXT_ROW) begin
                r_window_counter_row <= 0;
            end

            if (r_state_read_curr == TRANSFER) begin
                r_window_counter_input <= r_window_counter_input + 1;
                r_window_counter_row <= r_window_counter_row + 1;
            end

            if (r_state_read_curr == READ_WEIGHTS)  begin
                 r_addr_count_kernel <= r_addr_count_kernel + 1;
            end
        end
    end

    // -------------------------------------------------------------------------
    // READING REGISTER BANK
    // -------------------------------------------------------------------------
    always_comb begin
        for (int unsigned i = 0; i < 25; i++)     // connection between register outputs to register inputs
            w_next_feat_input[i] = p_input_data;

        w_next_feat_input[0]  = (r_state_read_curr == READ_IN_10A) ? p_input_data : r_feat_input[3];     // makes the shifts - minimize muxes
        w_next_feat_input[1]  = (r_state_read_curr == READ_IN_10B) ? p_input_data : r_feat_input[4];
        w_next_feat_input[5]  = (r_state_read_curr == READ_IN_10A) ? p_input_data : r_feat_input[8];
        w_next_feat_input[6]  = (r_state_read_curr == READ_IN_10B) ? p_input_data : r_feat_input[9];
        w_next_feat_input[10] = (r_state_read_curr == READ_IN_10A) ? p_input_data : r_feat_input[13];
        w_next_feat_input[11] = (r_state_read_curr == READ_IN_10B) ? p_input_data : r_feat_input[14];
        w_next_feat_input[15] = (r_state_read_curr == READ_IN_10A) ? p_input_data : r_feat_input[18];
        w_next_feat_input[16] = (r_state_read_curr == READ_IN_10B) ? p_input_data : r_feat_input[19];
        w_next_feat_input[20] = (r_state_read_curr == READ_IN_10A) ? p_input_data : r_feat_input[23];
        w_next_feat_input[21] = (r_state_read_curr == READ_IN_10B) ? p_input_data : r_feat_input[24];
    end

    always_comb begin     // 'w_feat_input_write_en' to write into the register bank r_feat_input
        w_feat_input_write_en = '0;
        case (r_state_read_curr)
            READ_IN_10A, READ_IN_10B, READ_IN_15A, READ_IN_15B, READ_IN_15C:   w_feat_input_write_en[w_base_feat_input + r_addr_count_input * 5] = 1'b1;
            TRANSFER:     w_feat_input_write_en = 25'b0001100011000110001100011;   // make the shift
            default:  w_feat_input_write_en = '0;
        endcase
    end

    always_ff @(posedge clk or posedge reset) begin    // initializes and write into the register bank and convolution register bank
        if (reset)
            for (int unsigned i = 0; i < 25; i++)
                r_feat_input[i] <= '0;
        else
            for (int unsigned i = 0; i < 25; i++)
                if (w_feat_input_write_en[i])  r_feat_input[i] <= w_next_feat_input[i];
    end

    // Weight register bank with per-entry write-enable.
    always_comb begin
        w_weight_write_en = '0;
        if (r_state_read_curr == READ_WEIGHTS)
            w_weight_write_en[r_addr_count_kernel] = 1'b1;
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (int unsigned i = 0; i < WEIGHT_CYCLES; i++)
                weight_reg[i] <= '0;
        end else begin
            for (int unsigned i = 0; i < WEIGHT_CYCLES; i++)
                if (w_weight_write_en[i]) weight_reg[i] <= p_input_data;
        end
    end

    // ----------------------------------------------------------------------------------------------------
    // -------  PART 3 - CONVOLUTION CONTROL AND CONVOLUTION MODULES --------------------------------------
    // ----------------------------------------------------------------------------------------------------
    localparam CONV_MULTIPLY_COUNTER_WIDTH = $clog2(CONV_MULTIPLY_STEPS) + 1;
    logic [CONV_MULTIPLY_COUNTER_WIDTH-1:0] r_conv_multiply_count;

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            r_state_conv_curr <= WAIT_CONV;
        else
            r_state_conv_curr <= r_state_conv_next;
    end

    always_comb begin
        r_state_conv_next = r_state_conv_curr;    // default
        priority case (r_state_conv_curr)
            WAIT_CONV: if (r_state_read_curr == TRANSFER)                     r_state_conv_next = TRANSFORM;     // starts the convolution after moving date to the convolution register bank
            TRANSFORM:                                           r_state_conv_next = HADAMARD;
            HADAMARD:    if (r_conv_multiply_count==CONV_MULTIPLY_COUNTER_WIDTH'(CONV_MULTIPLY_STEPS-1)) r_state_conv_next = INVERSE;
            INVERSE:                                           r_state_conv_next = WAIT_CONV;
            default:                                      r_state_conv_next = WAIT_CONV;
        endcase
    end

    // -------------------------------------------------------------------------
    // CONVOLUTION REGISTER BANK AND CONVOLUTION REGISTERS:  w_conv_end  -- r_conv_multiply_count
    // -------------------------------------------------------------------------
`ifdef SIMULATION
     time prev_time, curr_time;  // debug
`endif

     always_ff @(posedge clk or posedge reset) begin    // register bank for the convolution
        if (reset)
            for (int unsigned i = 0; i < 25; i++)
                r_conv_input[i] <= '0;
        else begin
            if (r_state_read_curr == TRANSFER) begin              // fill the convolution register bank
                   for (int unsigned i = 0; i < 25; i++)
                        r_conv_input[i] <= r_feat_input[i];
`ifdef SIMULATION
                   curr_time = $time;     // debug
                   $display("current time = %0t | previous time = %0t | diff = %0t", curr_time, prev_time, (curr_time - prev_time));
                   prev_time <= curr_time;
`endif
            end
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            w_conv_end <= 0;
        else begin
            if (r_state_conv_next == INVERSE)            // *** CAUTION: PE
                w_conv_end <=  1;
            else if (r_state_write_curr == WRITE_OUTPUT)
                w_conv_end <= 0;
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            r_conv_multiply_count <= 0;
        else begin
            if (r_state_conv_curr == TRANSFORM)
                r_conv_multiply_count <= 0;
            else if (r_state_conv_curr== HADAMARD)
                r_conv_multiply_count <=  r_conv_multiply_count + 1;
        end
    end

    // ----------------------------------------------------------------------------------------------------
    // -------  PART 4 - WRITE FSM AND READ/WRITE COUNTER -------------------------------------------------
    // ----------------------------------------------------------------------------------------------------
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            r_state_write_curr <= WAIT_WRITE;
        else
            r_state_write_curr <= r_state_write_next;
    end

    always_comb begin
        r_state_write_next = r_state_write_curr;    // default

        priority case (r_state_write_curr)
            WAIT_WRITE: if (r_state_read_curr==AP)                                    r_state_write_next = RESET9;     // wait p_start reading the IFMAPs to p_start writing the results
                        else                                          r_state_write_next = WAIT_WRITE;
            RESET9:   if (w_conv_end && r_output_read_count==8)                       r_state_write_next = WRITE_OUTPUT;
            READ_OUTPUT:   if (w_conv_end && r_output_read_count==8)                       r_state_write_next = WRITE_OUTPUT;
            WRITE_OUTPUT:  if (r_channel_counter_input==0 && r_output_write_count==8)           r_state_write_next = RESET9;
                         else if (r_channel_counter_input>0  && r_output_write_count==8)  r_state_write_next = READ_OUTPUT ;
                         else if (last_output)                          r_state_write_next = WAIT_WRITE;  //end processing
                         else  r_state_write_next = WRITE_OUTPUT;
            default: r_state_write_next = WAIT_WRITE;
        endcase
    end

    // -------------------------------------------------------------------------
    // WRITE REGISTERS - r_output_read_count e r_output_write_count
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            r_output_read_count <= 0;
            r_output_write_count <= 0;
        end
        else begin
            if (r_state_write_curr==WRITE_OUTPUT) begin
                r_output_read_count <= 0;
                if (r_output_write_count < 8)
                    r_output_write_count <= r_output_write_count + 1;
                else
                    r_output_write_count <= 8;
            end
            else if (r_state_write_curr==RESET9 || r_state_write_curr==READ_OUTPUT) begin
                r_output_write_count <= 0;
                if (r_output_read_count < 8)
                    r_output_read_count <= r_output_read_count + 1;
                else
                    r_output_read_count <= 8;
            end
        end
    end

endmodule
