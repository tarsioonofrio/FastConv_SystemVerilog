# Capture RTL/behavioral switching activity for import into the routed DCP.
# The capture window starts immediately before p_start and ends after the
# complete one-job workload. No VCD or waveform database is enabled.
run 80 ns
open_saif activity_rtl.saif
log_saif [get_objects -r /tb_power/dut/*]
run 240 us
close_saif
quit
