# OOC post-route functional SAIF power, loaded onto the same routed OOC DCP.
# Usage: vivado -mode batch -source power_saif.tcl -tclargs <run-name>
set script_dir [file dirname [file normalize [info script]]]
set ooc_dir [file normalize [file join $script_dir ..]]
if {$argc != 1} { puts stderr "usage: power_saif.tcl <run-name>"; exit 2 }
set run_name [lindex $argv 0]
set run_dir [file join $ooc_dir reports $run_name]
set dcp [file join $run_dir design_routed_ooc.dcp]
set internal_saif [file join $run_dir funcsim_internal activity_internal.saif]
set ports_saif [file join $run_dir funcsim_ports activity_ports.saif]
foreach artifact [list $dcp $internal_saif $ports_saif] {
  if {![file exists $artifact]} { error "missing OOC P3F artifact: $artifact" }
}

foreach corner {typical maximum} {
  open_checkpoint $dcp
  reset_switching_activity -all
  read_saif -strip_path tb_power/dut \
    -out_file [file join $run_dir saif_mapping_internal_${corner}.rpt] $internal_saif
  read_saif -strip_path tb_power \
    -out_file [file join $run_dir saif_mapping_ports_${corner}.rpt] $ports_saif
  set_operating_conditions -process $corner -ambient_temp 25
  report_power -hier all -file [file join $run_dir power_ooc_p3f_${corner}.rpt]
  close_design
}
exit
