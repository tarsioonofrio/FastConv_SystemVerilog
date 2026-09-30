# Synthesize and route one scalar/column Conv variant at the common 317 MHz point.
# Usage: vivado -mode batch -source synth_impl.tcl -tclargs <bench-dir> <repo-root> <run> <manifest> ?<parameter=value>?
if {$argc < 4 || $argc > 5} { error "usage: synth_impl.tcl <bench-dir> <repo-root> <run> <manifest> ?<parameter=value>?" }
set bench_dir [file normalize [lindex $argv 0]]
set repo_root [file normalize [lindex $argv 1]]
set run_name [lindex $argv 2]
set manifest [file normalize [lindex $argv 3]]
set generic_override ""
if {$argc == 5} { set generic_override [lindex $argv 4] }
set run_dir [file join $bench_dir reports $run_name]
file mkdir $run_dir

set fp [open [file join $run_dir metadata.txt] w]
puts $fp "vivado_version=[version -short]"
puts $fp "part=xczu7ev-ffvc1156-2-e"
puts $fp "top=Conv"
puts $fp "target_period_ns=3.154574"
puts $fp "target_frequency_mhz=317"
puts $fp "manifest=$manifest"
if {$generic_override ne ""} { puts $fp "generic_override=$generic_override" }
close $fp

set sources [open $manifest r]
while {[gets $sources line] >= 0} {
  set line [string trim $line]
  if {$line eq "" || [string match "#*" $line]} { continue }
  set source [file normalize [file join $repo_root $line]]
  if {![file exists $source]} { error "RTL source does not exist: $source" }
  read_verilog -sv $source
}
close $sources

read_xdc [file join $bench_dir constraints zcu104_317mhz.xdc]
if {$generic_override eq ""} {
  synth_design -top Conv -part xczu7ev-ffvc1156-2-e
} else {
  synth_design -top Conv -part xczu7ev-ffvc1156-2-e -generic $generic_override
}
write_checkpoint -force [file join $run_dir design_synth.dcp]
opt_design
place_design
phys_opt_design
route_design
write_checkpoint -force [file join $run_dir design_routed.dcp]
write_verilog -force -mode funcsim [file join $run_dir design_routed_funcsim.v]
report_utilization -hierarchical -file [file join $run_dir utilization.rpt]
report_timing_summary -delay_type max -report_unconstrained -check_timing_verbose -max_paths 30 -file [file join $run_dir timing_summary.rpt]
report_clock_utilization -file [file join $run_dir clock_utilization.rpt]
report_io -file [file join $run_dir io.rpt]
report_drc -file [file join $run_dir drc.rpt]
puts "IMPLEMENTATION_COMPLETE run=$run_name"
exit
