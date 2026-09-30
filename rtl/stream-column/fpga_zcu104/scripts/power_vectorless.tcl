# Post-route vectorless typical and maximum power references.
# Usage: power_vectorless.tcl <output-root> <algorithm>
if {$argc != 2} { error "usage: power_vectorless.tcl <output-root> <algorithm>" }
set output_root [file normalize [lindex $argv 0]]
set algorithm [lindex $argv 1]
set run_dir [file join $output_root $algorithm]
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
