`timescale 1ns/1ps

module tb_fpga_wrapper_funcsim;
  localparam realtime CLK_PERIOD_NS = 3.154574;

  logic clk = 1'b0;
  logic reset = 1'b1;
  logic start = 1'b0;
  logic done;
  logic result_valid;
  logic result_ok;
  logic capture_done = 1'b0;
  integer cycles = 0;
  integer launch_cycle = 0;
  integer core_latency_cycles = 0;

  always #(CLK_PERIOD_NS / 2.0) clk = ~clk;

  fpga_benchmark_top dut (
    .clk(clk),
    .reset(reset),
    .start(start),
    .done(done),
    .result_valid(result_valid),
    .result_ok(result_ok)
  );

  always_ff @(posedge clk) begin
    if (reset) begin
      cycles <= 0;
      launch_cycle <= 0;
      core_latency_cycles <= 0;
      capture_done <= 1'b0;
    end else begin
      cycles <= cycles + 1;
      if (start)
        launch_cycle <= cycles;
      if (done) begin
        core_latency_cycles <= cycles - launch_cycle;
        capture_done <= 1'b1;
      end
    end
  end

  initial begin
    repeat (70) @(negedge clk); // Wait beyond the FPGA GSR startup interval.
    reset = 1'b0;
    repeat (2) @(negedge clk);
    start = 1'b1;
    @(negedge clk);
    start = 1'b0;

    fork
      begin
        wait (result_valid === 1'b1);
        #1ps;
        if (result_ok !== 1'b1)
          $fatal(1, "post-implementation checker reported result_ok=%b", result_ok);
        $display("FPGA_FUNCsim_RESULT core_latency_cycles=%0d result_valid=%b result_ok=%b",
                 core_latency_cycles, result_valid, result_ok);
        $finish;
      end
      begin
        repeat (100000) @(posedge clk);
        $fatal(1, "post-implementation functional simulation watchdog expired");
      end
    join_any
    disable fork;
  end
endmodule
