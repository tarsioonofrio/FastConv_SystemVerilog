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
   
  always_comb begin
       if (EA == DONE) begin
           P = NBITS'(sum);  
           done = 1;  
       end else begin
           P = 0;  
           done = 0;
       end
   end



  always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            sum <= 0;
            i <= 0;
            EA <= IDLE;
        end else begin
            EA <= PE;

            if (EA==IDLE) begin
                    if (start) begin
                        sum <= 0;  
                        i <= 0;
                    end
             end 
             else if (EA==RUN) begin
                    sum <= sum + (NBITS*2-1)'($signed(inputs9[i] * weights9[i]));

                    if (i < 8) begin
                        i <= i + 1;
                    end
              end

        end
  end

   always_comb begin
        PE = EA;

        unique case (EA)
            IDLE: if (start)  PE = RUN;
            RUN:  if (i == 8)  PE = DONE;
            DONE: PE = IDLE; 
        endcase
    end

endmodule
