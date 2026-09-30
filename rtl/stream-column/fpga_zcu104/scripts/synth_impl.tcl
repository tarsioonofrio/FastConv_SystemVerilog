# Synthesize and route a streaming-column core at the shared 317 MHz point.
# Usage: synth_impl.tcl <repo-root> <output-root> <algorithm> <manifest>
if {$argc != 4} { error "usage: synth_impl.tcl <repo-root> <output-root> <algorithm> <manifest>" }
set repo_root [file normalize [lindex $argv 0]]
set output_root [file normalize [lindex $argv 1]]
set algorithm [lindex $argv 2]
set manifest [file normalize [lindex $argv 3]]
set run_dir [file join $output_root $algorithm]
file mkdir $run_dir

set fp [open [file join $run_dir metadata.txt] w]
puts $fp "vivado_version=[version -short]"
puts $fp "part=xczu7ev-ffvc1156-2-e"
puts $fp "top=Conv"
puts $fp "algorithm=$algorithm"
puts $fp "target_period_ns=3.154574"
puts $fp "target_frequency_mhz=317"
puts $fp "NADDR=12"
puts $fp "manifest=$manifest"
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

read_xdc [file join $repo_root rtl stream-column fpga_zcu104 constraints zcu104_317mhz.xdc]
synth_design -top Conv -part xczu7ev-ffvc1156-2-e -generic {NADDR=12}
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
puts "IMPLEMENTATION_COMPLETE algorithm=$algorithm"
exit
