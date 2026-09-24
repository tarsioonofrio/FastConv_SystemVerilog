# Import two functionally identical post-route SAIF scopes into the routed DCP.
set script_dir [file dirname [file normalize [info script]]]
set wrapper_dir [file normalize [file join $script_dir ..]]
if {$argc != 1} { puts stderr "usage: power_funcsim_saif.tcl <run-name>"; exit 2 }
set run_name [lindex $argv 0]
set run_dir [file join $wrapper_dir reports $run_name]
set internal_saif [file join $run_dir funcsim_internal activity_internal.saif]
set ports_saif [file join $run_dir funcsim_ports activity_ports.saif]
foreach artifact [list [file join $run_dir design_routed.dcp] $internal_saif $ports_saif] {
  if {![file exists $artifact]} { error "missing P3F artifact: $artifact" }
}

foreach corner {typical maximum} {
  open_checkpoint [file join $run_dir design_routed.dcp]
  reset_switching_activity -all
  read_saif -strip_path tb_fpga_wrapper_funcsim/dut \
    -out_file [file join $run_dir mapping_internal_${corner}.rpt] $internal_saif
  read_saif -strip_path tb_fpga_wrapper_funcsim \
    -out_file [file join $run_dir mapping_ports_${corner}.rpt] $ports_saif
  set_operating_conditions -process $corner -ambient_temp 25
  report_operating_conditions -file [file join $run_dir operating_conditions_${corner}.rpt]
  report_power -hier all -file [file join $run_dir power_funcsim_saif_${corner}.rpt]
  close_design
}
puts "WRAPPER_P3F_POWER_COMPLETE run=$run_name"
