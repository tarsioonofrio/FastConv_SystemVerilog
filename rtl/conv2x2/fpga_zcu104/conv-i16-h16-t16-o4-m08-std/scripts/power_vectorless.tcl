# Vectorless power on an implemented checkpoint.
# Usage: vivado -mode batch -source power_vectorless.tcl -tclargs <run-name>
set script_dir [file dirname [file normalize [info script]]]
set bench_dir [file normalize [file join $script_dir ..]]
if {$argc < 1} { puts stderr "usage: power_vectorless.tcl <run-name>"; exit 2 }
set run_name [lindex $argv 0]
set run_dir [file join $bench_dir reports $run_name]
open_checkpoint [file join $run_dir design_routed.dcp]
reset_switching_activity -all

foreach corner {typical maximum} {
  reset_operating_conditions
  set_operating_conditions -process $corner -ambient_temp 25
  report_operating_conditions -file [file join $run_dir operating_conditions_vectorless_${corner}.rpt]
  report_power -hier all -file [file join $run_dir power_vectorless_${corner}.rpt]
}
close_design
