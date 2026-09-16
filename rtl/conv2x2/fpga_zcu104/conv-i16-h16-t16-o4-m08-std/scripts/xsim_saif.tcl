# Run under xsim after Vivado generated the post-implementation timing netlist.
# No wave/VCD logging is enabled. The first 100 ns covers reset and warm-up;
# only the useful workload window is included in the SAIF file. This core is
# not re-entrant without reset, so one complete convolution is used and the
# job-level II is documented as equal to the measured latency.
run 100 ns
open_saif activity.saif
log_saif [get_objects -r /tb_power/dut/*]
run 250 us
close_saif
quit
