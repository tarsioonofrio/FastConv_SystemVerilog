set dcp [file normalize [lindex $argv 0]]
set internal_saif [file normalize [lindex $argv 1]]
set top_saif [file normalize [lindex $argv 2]]
set out_dir [file normalize [lindex $argv 3]]

foreach corner {typical maximum} {
  open_checkpoint $dcp
  reset_switching_activity -all
  read_saif -strip_path tb_power/dut \
    -out_file [file join $out_dir mapping_internal_${corner}.rpt] $internal_saif
  read_saif -strip_path tb_power \
    -out_file [file join $out_dir mapping_ports_${corner}.rpt] $top_saif
  set_operating_conditions -process $corner -ambient_temp 25
  report_power -hier all \
    -file [file join $out_dir power_scoped_${corner}.rpt]
  close_design
}

exit
