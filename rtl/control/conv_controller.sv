/*
   CONVOLUTION CONTROLLER  - (V0 - FERNANDO MORAES)  - 24/ABRIL
*/
`timescale 1ns/1ps

module conv_controller #(
    parameter int unsigned NB_IFMAP        =  2,
    parameter int unsigned NB_OFMAP        =  3,
    parameter int unsigned SZ_KERNEL       =  5,
    parameter int unsigned NB_LINES        =  17,
    parameter int unsigned NB_COLUMNS      =  8,
    parameter int unsigned ADDR_W          =  18,   // bits to address the memory
    parameter int unsigned NB_MULTIPS      =  6     // multiplication steps
 )(
    input  logic clk,
    input  logic rst,
    input  logic start,  
    output logic end_all_convolutions,

    output logic [ADDR_W-1:0] address,
    input  logic [19:0] Din
);
    logic [19:0] Vrd[0:24];                      // register bank 
    logic [19:0] convReg[0:24];                  // convolution reg bank
    logic [19:0] nextVrd[0:24];                  // wires to shift the register bank
    logic [24:0] ce;                             // chip enable for each register  
    logic end_conv, last_line, lastIFMAP, lastOFMAP; 
    logic [3:0] contRd, contWr;  
    logic [ADDR_W-1:0] internal_address, horizontal_step, weight_address;

    localparam BITS_IF = $clog2(NB_IFMAP) + 1;  
    logic [BITS_IF-1:0] current_IFchannel;

    localparam BITS_OF = $clog2(NB_OFMAP) + 1;  
    logic [BITS_OF-1:0] current_OFchannel;

    localparam CONVOLUTIONS_PER_LINE =  NB_LINES / 3;            // assuming output 3x3  
    localparam CONVOLUTIONS_PER_COLUMN =  NB_COLUMNS / 3;         
    localparam CONVOLUTIONS_PER_CHANNEL =  CONVOLUTIONS_PER_LINE * CONVOLUTIONS_PER_COLUMN;

    localparam BITS_CONV = $clog2(CONVOLUTIONS_PER_LINE*CONVOLUTIONS_PER_COLUMN);  
    logic [BITS_CONV-1:0] cnt_convolutions;

    localparam BITS_LINE = $clog2(CONVOLUTIONS_PER_LINE) + 1;  
    logic [BITS_LINE-1:0] cnt_horiz_convs;

    localparam BITS_COL = $clog2(CONVOLUTIONS_PER_COLUMN) + 1;  
    logic [BITS_COL-1:0] base_VRd, cnt_col;

    // REGISTER BANK FOR THE WEIGHTS ////////////////////////////////////////////
    localparam int WEIGHT_CYCLES = SZ_KERNEL * SZ_KERNEL;
    localparam int WEIGHT_W      = $clog2(WEIGHT_CYCLES);
    logic [19:0] weightReg[0:WEIGHT_CYCLES-1];                
    logic [WEIGHT_CYCLES-1:0] ce_w;   
    logic [WEIGHT_W-1:0]      cnt_weight;
    logic                     weight_done, end_write_results;

    // -------------------------------------------------------------------------
    // FSM STATES DECLARION
    // ------------------------------------------------------------------------- 
    typedef enum logic [3:0] { WAIT, AP,  READ_WEIGHTS, R10A, R10B, R15A, R15B, R15C, WAIT_WR, XFER, CHANGE_LINE} state_r_t;
    state_r_t EA_R, PE_R;

    typedef enum logic [1:0] { W_CONV, T1,  HAD, T2  } state_c_t;
    state_c_t EA_C, PE_C;  

    typedef enum logic [2:0] { W_WRITE,  ZERA9,  READ9, WRITE9 } state_w_t;
    state_w_t EA_W, PE_W;  

    // ----------------------------------------------------------------------------------------------------
    // -------  PART 1 - ADDRESS TO ACCESS THE IFMAP AND WEIGHT MEMORY ------------------------------------
    // ----------------------------------------------------------------------------------------------------
    assign address = (EA_R==READ_WEIGHTS) ? weight_address : internal_address + ADDR_W'(cnt_col);   // address mux

    always_ff @(posedge clk or posedge rst) begin  
        if (rst) begin
            internal_address <= '0;
            horizontal_step <= 3;
        end
        else if ((EA_R==R10A && PE_R==R10B) || (EA_R==R10B && PE_R==R15A) || (EA_R==R15A && PE_R==R15B) || (EA_R==R15B && PE_R==R15C) || EA_R==XFER)
            internal_address <= internal_address + ADDR_W'(NB_COLUMNS);    // change internal address in the state transition or in the XFER state (CAUTION: PE) 
    
        else if (EA_R==CHANGE_LINE  &&  !lastIFMAP) begin     // when change the line, the read pointer moves 'horizontal_step'
            internal_address <= horizontal_step + ADDR_W'(current_IFchannel*NB_LINES*NB_COLUMNS);   // restart for the first line
            horizontal_step  <= horizontal_step  + 3;
        end

        else if (EA_R==AP && lastIFMAP ) begin            
            internal_address <= internal_address - ADDR_W'(NB_COLUMNS) + ADDR_W'(SZ_KERNEL);   // adjust the pointer to the next IFMAP
            horizontal_step <= 3;
 
            if (current_IFchannel == BITS_IF'(NB_IFMAP-1) ) begin               // change the IFMAP
`ifdef SIMULATION
                $display("RESETANDO PARA O CANAL 0 - DEU A VOLTA NOS IFMAPS time=%0t %d (%0d) EA_R = %s", $time, current_IFchannel, NB_IFMAP, EA_R.name());

`endif
                internal_address <= 0;
            end
       end
    end

    always_ff @(posedge clk or posedge rst) begin  
        if (rst) begin
            weight_address <= 0;
        end
        else if (EA_R == WAIT && PE_R == AP)    // initializes only ONCE the weight address (after the IFMAPs in the memory) (CAUTION: PE)   
                weight_address <=  ADDR_W'(NB_IFMAP * NB_LINES * NB_COLUMNS);  
        else if (EA_R == READ_WEIGHTS)
                weight_address <= weight_address + 1;   // next weight
    end

    // ----------------------------------------------------------------------------------------------------
    // -------  PART 2 - READ FSM AND REGISTERS -----------------------------------------------------------
    // ----------------------------------------------------------------------------------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            EA_R <= WAIT;
        else
            EA_R <= PE_R;
    end

    always_comb begin
        PE_R = EA_R;
        priority case (EA_R)
            WAIT:         if (start)           PE_R = AP;
            AP:                                PE_R = READ_WEIGHTS;
            READ_WEIGHTS:  if (weight_done)    PE_R = R10A;
                           else if (lastOFMAP) PE_R = WAIT;        //end processing             
            R10A:        if (cnt_col == 4)     PE_R = R10B;        // read 5*5 values 
            R10B:        if (cnt_col == 4)     PE_R = R15A;
            R15A:        if (cnt_col == 4)     PE_R = R15B;
            R15B:        if (cnt_col == 4)     PE_R = R15C;
            R15C:        if (cnt_col == 4)     PE_R = XFER;
            XFER:        PE_R = WAIT_WR;                     // start the convolution        
            WAIT_WR:     if (last_line && end_write_results)  PE_R = CHANGE_LINE;
                         else  if (end_write_results)         PE_R = R15A;
                         else                                 PE_R = WAIT_WR;
            CHANGE_LINE: if (lastIFMAP) PE_R = AP;
                            else        PE_R = R10A;
            default:    PE_R = WAIT;
        endcase
    end

    assign weight_done       = (cnt_weight == WEIGHT_W'(WEIGHT_CYCLES-1));
    assign end_write_results = contWr==0 || contWr==8;        // compare to zero for the first write test or the last value (8) in the next convolutions
    assign last_line         = (cnt_horiz_convs == BITS_LINE'(CONVOLUTIONS_PER_LINE));
    assign lastIFMAP         = (cnt_convolutions == BITS_CONV'(CONVOLUTIONS_PER_CHANNEL)); 
    assign lastOFMAP         = (current_OFchannel == BITS_OF'(NB_OFMAP));
    
    assign end_all_convolutions = ((PE_W == W_WRITE && lastOFMAP));  // output to signalize the end of the convolution process 

    // -------------------------------------------------------------------------
    // READING REGISTERS
    // ------------------------------------------------------------------------- 

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_col <= 0;
        end else begin
            if (EA_R == READ_WEIGHTS) begin
                cnt_col <= 0;
            end
            else if (EA_R inside {R10A, R10B, R15A, R15B, R15C}) begin
                if (cnt_col == 4)
                    cnt_col <= 0;
                else
                    cnt_col <= cnt_col + 1;
            end
        end
    end

     assign base_VRd = (EA_R == R10A) ? 0 :
                       (EA_R == R10B) ? 1 :
                       (EA_R == R15A) ? 2 :
                       (EA_R == R15B) ? 3 :
                       (EA_R == R15C) ? 4 :  0;

   
    // SET OF FIVE CONTROL REGISTERS:
    // current_IFchannel: number of the current IFMAP channel being read
    // current_OFchannel: number of the current OFMAP channel being processed
    // cnt_convolutions:  number of convolutions in a given IFMAP channel
    // cnt_horiz_convs :  number of horizontal convolutions in a given IFMAP channel - detect the last line
    // cnt_weight:        number of weights read from memory
    always_ff @(posedge clk or posedge rst) begin   
        if (rst) begin
            current_IFchannel  <= '1;  // start with all bits in '1' - IFchannel must be {0,1,2}
            current_OFchannel  <= 0;
            cnt_convolutions   <= 0;
            cnt_horiz_convs    <= 0;
            cnt_weight         <= 0;
        end else begin
            if (EA_R == AP) begin
                
                if (current_IFchannel == BITS_IF'(NB_IFMAP-1)) begin
                    current_IFchannel <= '0;
                    current_OFchannel <= current_OFchannel + 1;
                end
                else begin
                    current_IFchannel <= current_IFchannel + 1;
                end
                cnt_convolutions <= 0;    // reset counters
                cnt_horiz_convs  <= 0;
                cnt_weight       <= 0;
            end 

            if (EA_R == CHANGE_LINE) begin
                cnt_horiz_convs <= 0;
            end

            if (EA_R == XFER) begin
                cnt_convolutions <= cnt_convolutions + 1;
                cnt_horiz_convs <= cnt_horiz_convs + 1;
            end 

            if (EA_R == READ_WEIGHTS)  begin 
                 cnt_weight <= cnt_weight + 1;
            end
        end
    end

    // -------------------------------------------------------------------------
    // READING REGISTER BANK
    // ------------------------------------------------------------------------- 
    always_comb begin                       
        for (int unsigned i = 0; i < 25; i++)     // connection between register outputs to register inputs
            nextVrd[i] = Din;
    
        nextVrd[0]  = (EA_R == R10A) ? Din : Vrd[3];     // makes the shifts - minimize muxes
        nextVrd[1]  = (EA_R == R10B) ? Din : Vrd[4];
        nextVrd[5]  = (EA_R == R10A) ? Din : Vrd[8];
        nextVrd[6]  = (EA_R == R10B) ? Din : Vrd[9];
        nextVrd[10] = (EA_R == R10A) ? Din : Vrd[13];
        nextVrd[11] = (EA_R == R10B) ? Din : Vrd[14];
        nextVrd[15] = (EA_R == R10A) ? Din : Vrd[18];
        nextVrd[16] = (EA_R == R10B) ? Din : Vrd[19];
        nextVrd[20] = (EA_R == R10A) ? Din : Vrd[23];
        nextVrd[21] = (EA_R == R10B) ? Din : Vrd[24];
    end
    
    always_comb begin     // 'ce' to write into the register bank Vrd
        ce = '0;
        case (EA_R)
            R10A, R10B, R15A, R15B, R15C:   ce[base_VRd + cnt_col * 5] = 1'b1;   
            XFER:     ce = 25'b0001100011000110001100011;   // make the shift
            default:  ce = '0;
        endcase
    end
    
    always_ff @(posedge clk or posedge rst) begin    // initializes and write into the register bank and convolution register bank
        if (rst) 
            for (int unsigned i = 0; i < 25; i++)
                Vrd[i] <= '0;
        else 
            for (int unsigned i = 0; i < 25; i++) 
                if (ce[i])  Vrd[i] <= nextVrd[i];
    end

    // weigh register bank - with the idea of CE (chip enable)
    always_comb begin
        ce_w = '0;
        if (EA_R == READ_WEIGHTS)
            ce_w[cnt_weight] = 1'b1; 
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int unsigned i = 0; i < WEIGHT_CYCLES; i++)
                weightReg[i] <= '0;
        end else begin
            for (int unsigned i = 0; i < WEIGHT_CYCLES; i++)
                if (ce_w[i]) weightReg[i] <= Din;
        end
    end 

    // ----------------------------------------------------------------------------------------------------
    // -------  PART 3 - CONVOLUTION CONTROL AND CONVOLUTION MODULES --------------------------------------
    // ----------------------------------------------------------------------------------------------------
    localparam BITSM = $clog2(NB_MULTIPS) + 1;  
    logic [BITSM-1:0] cnt_multip;

    always_ff @(posedge clk or posedge rst) begin  
        if (rst)
            EA_C <= W_CONV;
        else
            EA_C <= PE_C;
    end

    always_comb begin
        PE_C = EA_C;    // default
        priority case (EA_C)
            W_CONV: if (EA_R == XFER)                     PE_C = T1;     // starts the convolution after moving date to the convolution register bank
            T1:                                           PE_C = HAD;
            HAD:    if (cnt_multip==BITSM'(NB_MULTIPS-1)) PE_C = T2;
            T2:                                           PE_C = W_CONV;
            default:                                      PE_C = W_CONV;
        endcase
    end

    // -------------------------------------------------------------------------
    // CONVOLUTION REGISTER BANK AND CONVOLUTION REGISTERS:  end_conv  -- cnt_multip
    // ------------------------------------------------------------------------- 
`ifdef SIMULATION
     time prev_time, curr_time;  // debug
`endif

     always_ff @(posedge clk or posedge rst) begin    // register bank for the convolution
        if (rst) 
            for (int unsigned i = 0; i < 25; i++) 
                convReg[i] <= '0;
        else begin
            if (EA_R == XFER) begin              // fill the convolution register bank
                   for (int unsigned i = 0; i < 25; i++) 
                        convReg[i] <= Vrd[i];        
`ifdef SIMULATION
                   curr_time = $time;     // debug            
                   $display("current time = %0t | previous time = %0t | diff = %0t", curr_time, prev_time, (curr_time - prev_time));
                   prev_time <= curr_time;  
`endif        
            end                
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) 
            end_conv <= 0;
        else begin
            if (PE_C == T2)            // *** CAUTION: PE
                end_conv <=  1;
            else if (EA_W == WRITE9)
                end_conv <= 0;
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) 
            cnt_multip <= 0;
        else begin
            if (EA_C == T1)           
                cnt_multip <= 0;
            else if (EA_C== HAD)
                cnt_multip <=  cnt_multip + 1;
        end
    end
    
    // ----------------------------------------------------------------------------------------------------
    // -------  PART 4 - WRITE FSM AND READ/WRITE COUNTER -------------------------------------------------
    // ----------------------------------------------------------------------------------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            EA_W <= W_WRITE;
        else
            EA_W <= PE_W;
    end

    always_comb begin
        PE_W = EA_W;    // default

        priority case (EA_W)
            W_WRITE: if (EA_R==AP)                                    PE_W = ZERA9;     // wait start reading the IFMAPs to start writing the results
                        else                                          PE_W = W_WRITE;
            ZERA9:   if (end_conv && contRd==8)                       PE_W = WRITE9;
            READ9:   if (end_conv && contRd==8)                       PE_W = WRITE9;
            WRITE9:  if (current_IFchannel==0 && contWr==8)           PE_W = ZERA9;  
                         else if (current_IFchannel>0  && contWr==8)  PE_W = READ9 ; 
                         else if (lastOFMAP)                          PE_W = W_WRITE;  //end processing
                         else  PE_W = WRITE9;        
            default: PE_W = W_WRITE;
        endcase
    end

    // ------------------------------------------------------------------------- 
    // WRITE REGISTERS - contRd e contWr
    // ------------------------------------------------------------------------- 
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            contRd <= 0;      
            contWr <= 0;
        end
        else begin
            if (EA_W==WRITE9) begin
                contRd <= 0;
                if (contWr < 8)
                    contWr <= contWr + 1;
                else
                    contWr <= 8; 
            end
            else if (EA_W==ZERA9 || EA_W==READ9) begin  
                contWr <= 0;
                if (contRd < 8)
                    contRd <= contRd + 1;
                else
                    contRd <= 8;           
            end
        end
    end

endmodule