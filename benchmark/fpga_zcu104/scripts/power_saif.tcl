# SAIF-based post-route power. The same routed checkpoint used for timing is
# reopened before each import. Usage:
# vivado -mode batch -source power_saif.tcl -tclargs <run> <saif> <strip_path>
set script_dir [file dirname [file normalize [info script]]]
set bench_dir [file normalize [file join $script_dir ..]]
if {$argc < 3} { puts stderr "usage: power_saif.tcl <run> <saif> <strip_path>"; exit 2 }
set run_name [lindex $argv 0]
set saif [file normalize [lindex $argv 1]]
set strip_path [lindex $argv 2]
set run_dir [file join $bench_dir reports $run_name]
foreach corner {typical maximum} {
  open_checkpoint [file join $run_dir design_routed.dcp]
  reset_switching_activity -all
  read_saif -strip_path $strip_path -out_file [file join $run_dir saif_mapping_${corner}.rpt] $saif
  set_operating_conditions -process $corner -ambient_temp 25
  report_power -hier all -file [file join $run_dir power_saif_${corner}.rpt]
  close_design
}
