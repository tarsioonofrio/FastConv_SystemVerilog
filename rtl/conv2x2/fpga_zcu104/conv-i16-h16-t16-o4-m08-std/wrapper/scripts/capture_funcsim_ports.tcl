database -open waves -shm
probe -create -shm {tb_fpga_wrapper_funcsim.clk tb_fpga_wrapper_funcsim.reset tb_fpga_wrapper_funcsim.start tb_fpga_wrapper_funcsim.done tb_fpga_wrapper_funcsim.result_valid tb_fpga_wrapper_funcsim.result_ok}
probe -create -shm [find -ports -scope tb_fpga_wrapper_funcsim.dut *]
stop -condition {#%d/tb_fpga_wrapper_funcsim/start == 1'b1}
run
puts "WRAPPER_P3F_PORT_CAPTURE_STARTED"
dumpsaif -scope tb_fpga_wrapper_funcsim -internal -divider / -overwrite -output activity_ports.saif
stop -condition {#%d/tb_fpga_wrapper_funcsim/capture_done == 1'b1}
stop -time 90 us -execute {puts "WRAPPER_P3F_PORT_TIMEOUT"; exit}
run
puts "WRAPPER_P3F_PORT_CAPTURE_ENDED"
dumpsaif -end
run
quit
