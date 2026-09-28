stop -condition {#%d/tb_power/p_start == 1}
run
dumpsaif -scope tb_power.dut -internal -divider / -overwrite -output activity_dut.saif
stop -condition {#%d/tb_power/p_end == 1}
stop -time 90 us -execute {puts "P3F_TIMEOUT_BEFORE_P_END"; exit}
run
dumpsaif -end
run
quit
