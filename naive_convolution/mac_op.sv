module macoperation
     import packConv::*;
(
    input param9 inputs9,  
    input param9 weights9, 
    output regC  P,            
    input logic clk,  
    input logic reset,
    input logic start,
    output logic done 
);
  timeunit 1ns;
  timeprecision 1ps;
  
  logic signed [NBITS*2-1:0] sum ;    

  integer i;          

  typedef enum {IDLE, RUN, DONE} state;
  state EA, PE;

  always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            sum <= 0;
            done <= 1'b0;
            i <= 0;
            EA <= IDLE;
            P <= 0;
        end else begin
            EA <= PE;

            case (EA)
                IDLE: begin
                    if (start) begin
                        sum <= 0;  
                        i <= 0;
                    end
                end

                RUN: begin
                    sum <= sum + (NBITS*2-1)'($signed(inputs9[i] * weights9[i]));

                    if (i < 8) begin
                        i <= i + 1;
                    end
                end

                DONE: begin
                      P <= NBITS'(sum);  
                      done <= 1;  
                end

            endcase
        end
  end

    always_comb begin
        PE = EA;

        case (EA)
            IDLE: begin
                if (start) begin
                    PE = RUN;
                end
            end

            RUN: begin
                if (i == 8) begin 
                    PE = DONE;
                end
            end

            DONE: begin
                PE = IDLE; 
            end
        endcase
    end

endmodule
