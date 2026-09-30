# Import routed functional-SAIF and report power at the matched operating corners.
# Usage: power_p3f.tcl <output-root> <algorithm> <dut-saif> <top-saif>
if {$argc != 4} { error "usage: power_p3f.tcl <output-root> <algorithm> <dut-saif> <top-saif>" }
set output_root [file normalize [lindex $argv 0]]
set algorithm [lindex $argv 1]
set dut_saif [file normalize [lindex $argv 2]]
set top_saif [file normalize [lindex $argv 3]]
set run_dir [file join $output_root $algorithm]
foreach corner {typical maximum} {
  open_checkpoint [file join $run_dir design_routed.dcp]
  reset_switching_activity -all
  read_saif -strip_path tb_power_stream_column/dut -out_file [file join $run_dir p3f_mapping_internal_${corner}.rpt] $dut_saif
  read_saif -strip_path tb_power_stream_column -out_file [file join $run_dir p3f_mapping_ports_${corner}.rpt] $top_saif
  reset_operating_conditions
  set_operating_conditions -process $corner -ambient_temp 25
  report_operating_conditions -file [file join $run_dir operating_conditions_p3f_${corner}.rpt]
  report_power -hier all -file [file join $run_dir power_p3f_${corner}.rpt]
  close_design
}
exit
