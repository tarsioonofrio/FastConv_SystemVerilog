# Post-route vectorless typical/maximum power reference.
# Usage: vivado -mode batch -source power_vectorless.tcl -tclargs <bench-dir> <run>
if {$argc != 2} { error "usage: power_vectorless.tcl <bench-dir> <run>" }
set bench_dir [file normalize [lindex $argv 0]]
set run_name [lindex $argv 1]
set run_dir [file join $bench_dir reports $run_name]
foreach corner {typical maximum} {
  open_checkpoint [file join $run_dir design_routed.dcp]
  reset_switching_activity -all
  reset_operating_conditions
  set_operating_conditions -process $corner -ambient_temp 25
  report_operating_conditions -file [file join $run_dir operating_conditions_vectorless_${corner}.rpt]
  report_power -hier all -file [file join $run_dir power_vectorless_${corner}.rpt]
  close_design
}
exit
