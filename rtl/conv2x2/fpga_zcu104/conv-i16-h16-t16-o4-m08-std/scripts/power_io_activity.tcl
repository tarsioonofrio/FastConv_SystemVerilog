# Apply workload-derived primary-input/control activity to the routed checkpoint.
# The supplied Tcl should be primary_input_activity.tcl: clock activity comes
# from the XDC and output ports are observations, not injected stimuli.
# Usage: vivado -mode batch -source power_io_activity.tcl \
#   -tclargs <run> <activity.tcl>
set script_dir [file dirname [file normalize [info script]]]
set bench_dir [file normalize [file join $script_dir ..]]
if {$argc < 2} {
  puts stderr "usage: power_io_activity.tcl <run> <activity.tcl>"
  exit 2
}
set run_name [lindex $argv 0]
set activity_tcl [file normalize [lindex $argv 1]]
set run_dir [file join $bench_dir reports $run_name]
foreach corner {typical maximum} {
  open_checkpoint [file join $run_dir design_routed.dcp]
  reset_switching_activity -all
  source $activity_tcl
  reset_operating_conditions
  set_operating_conditions -process $corner -ambient_temp 25
  report_operating_conditions -file [file join $run_dir operating_conditions_io_activity_${corner}.rpt]
  report_power -hier all -file [file join $run_dir power_io_activity_${corner}.rpt]
  close_design
}
