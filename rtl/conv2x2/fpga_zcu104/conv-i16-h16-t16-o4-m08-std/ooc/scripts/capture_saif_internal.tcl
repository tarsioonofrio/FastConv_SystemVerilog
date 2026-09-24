stop -condition {#%d/tb_power/p_start == 1}
run
puts "OOC_P3F_INTERNAL_CAPTURE_STARTED"
dumpsaif -scope tb_power.dut -internal -memories -divider / -overwrite -output activity_internal.saif
stop -condition {#%d/tb_power/p_end == 1}
stop -time 90 us -execute {puts "OOC_P3F_INTERNAL_TIMEOUT_BEFORE_P_END"; exit}
run
puts "OOC_P3F_INTERNAL_CAPTURE_ENDED"
dumpsaif -end
run
quit
