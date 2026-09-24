database -open waves -shm
probe -create -shm {tb_power.clk tb_power.reset tb_power.p_start tb_power.p_end tb_power.p_input_en tb_power.p_input_addr tb_power.p_input_data tb_power.p_input_valid tb_power.p_output_en tb_power.p_output_wr tb_power.p_output_addr tb_power.p_output_data_write tb_power.p_output_valid}
probe -create -shm [find -ports -scope tb_power.dut *]
probe -create -shm tb_power.dut.w_conv_end
set output_write_count 0
stop -condition {#%d/tb_power/p_output_wr == 1} -execute {incr output_write_count} -continue
stop -condition {#%d/tb_power/p_start == 1}
run
puts "P3F_PORT_CAPTURE_STARTED"
dumpsaif -scope tb_power -internal -divider / -overwrite -output activity_timesim_top_nomem.saif
stop -condition {#%d/tb_power/p_end == 1}
stop -time 90 us -execute {puts "P3F_PORT_TIMEOUT_BEFORE_P_END"; exit}
run
puts "P3F_PORT_CAPTURE_ENDED"
dumpsaif -end
puts "P3F_OUTPUT_WRITE_PULSES=$output_write_count"
run
quit
