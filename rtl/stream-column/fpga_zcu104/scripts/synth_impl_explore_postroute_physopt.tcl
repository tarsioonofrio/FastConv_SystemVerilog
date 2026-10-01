# Streaming-column implementation with the WPN16 performance-exploration strategy.
# Usage: synth_impl_explore_postroute_physopt.tcl <repo-root> <output-root> <algorithm> <manifest> <constraints>
if {$argc != 5} {
  error "usage: synth_impl_explore_postroute_physopt.tcl <repo-root> <output-root> <algorithm> <manifest> <constraints>"
}
set repo_root [file normalize [lindex $argv 0]]
set output_root [file normalize [lindex $argv 1]]
set algorithm [lindex $argv 2]
set manifest [file normalize [lindex $argv 3]]
set constraints [file normalize [lindex $argv 4]]
# The earlier IFN9 m06/m12 runs had positive post-route WNS, and Vivado's
# final Explore phys-opt reported that it would not modify either netlist.
set skip_postroute_phys_opt [expr {[lsearch -exact {ifn9 ifn9_m12} $algorithm] >= 0}]
if {$skip_postroute_phys_opt} {
  set implementation_strategy "Performance_ExplorePostPlacePhysOpt"
  set postroute_phys_opt_metadata "Skipped_timing_already_closed"
} else {
  set implementation_strategy "Performance_ExplorePostRoutePhysOpt"
  set postroute_phys_opt_metadata "Explore"
}
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
puts $fp "experiment=$implementation_strategy"
puts $fp "opt_design=Default"
puts $fp "place_design=Explore"
puts $fp "phys_opt_design_post_place=Explore"
puts $fp "phys_opt_design_post_route=$postroute_phys_opt_metadata"
puts $fp "route_design=Explore"
puts $fp "manifest=$manifest"
puts $fp "constraints=$constraints"
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

read_xdc $constraints
synth_design -top Conv -part xczu7ev-ffvc1156-2-e -generic {NADDR=12}
write_checkpoint -force [file join $run_dir design_synth.dcp]

# Keep synthesis/logic optimization default and explore the physical implementation.
opt_design
place_design -directive Explore
phys_opt_design -directive Explore
route_design -directive Explore
if {$skip_postroute_phys_opt} {
  puts "Skipping explicit post-route phys_opt_design -directive Explore for $algorithm: previous routed WNS was positive and Vivado made no netlist changes."
} else {
  phys_opt_design -directive Explore
}

write_checkpoint -force [file join $run_dir design_routed.dcp]
write_verilog -force -mode funcsim [file join $run_dir design_routed_funcsim.v]
report_utilization -hierarchical -file [file join $run_dir utilization.rpt]
report_timing_summary -delay_type max -report_unconstrained -check_timing_verbose \
  -max_paths 30 -file [file join $run_dir timing_summary.rpt]
report_timing -delay_type max -max_paths 30 -path_type full_clock_expanded \
  -file [file join $run_dir critical_paths.rpt]
report_clock_utilization -file [file join $run_dir clock_utilization.rpt]
report_io -file [file join $run_dir io.rpt]
report_drc -file [file join $run_dir drc.rpt]
puts "IMPLEMENTATION_COMPLETE algorithm=$algorithm strategy=$implementation_strategy"
exit
