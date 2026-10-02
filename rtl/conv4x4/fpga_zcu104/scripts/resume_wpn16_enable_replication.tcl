# Resume only the forced-replication branch from an existing post-placement DCP.
# Usage: resume_wpn16_enable_replication.tcl <A-B-output-directory>
if {$argc != 1} {
  error "usage: resume_wpn16_enable_replication.tcl <A-B-output-directory>"
}

set out_dir [file normalize [lindex $argv 0]]
set placed_checkpoint [file join $out_dir post_place_common.dcp]
if {![file exists $placed_checkpoint]} {
  error "missing common post-placement checkpoint: $placed_checkpoint"
}

open_checkpoint $placed_checkpoint
set named_nets [get_nets -hier -filter {NAME =~ *r_transform_partial*}]
set force_targets [list]
set target_log [open [file join $out_dir replication_targets.txt] w]
foreach net $named_nets {
  set driver_pins [get_pins -quiet -of_objects $net -filter {DIRECTION == OUT}]
  if {[llength $driver_pins] == 0} { continue }
  set endpoints [all_fanout -flat -endpoints_only -from $driver_pins]
  set endpoint_count [llength $endpoints]
  puts $target_log "[get_property NAME $net] fanout_endpoints=$endpoint_count drivers=$driver_pins"
  if {$endpoint_count >= 128} {
    lappend force_targets $net
  }
}
close $target_log
if {[llength $force_targets] == 0} {
  error "No high-fanout r_transform_partial enable nets found; see replication_targets.txt"
}
puts "FORCED_REPLICATION_NET_COUNT=[llength $force_targets]"

# Vivado 2023.2 forbids combining -directive with -force_replication_on_nets.
phys_opt_design -force_replication_on_nets $force_targets
route_design -directive Explore

set branch_dir [file join $out_dir forced_replication]
file mkdir $branch_dir
report_utilization -file [file join $branch_dir utilization.rpt]
report_utilization -hierarchical -file [file join $branch_dir utilization_hierarchical.rpt]
report_timing_summary -delay_type max -report_unconstrained -check_timing_verbose \
  -max_paths 50 -file [file join $branch_dir timing_summary.rpt]
report_timing -delay_type max -max_paths 100 -path_type full_clock_expanded \
  -file [file join $branch_dir critical_paths.rpt]
report_clock_utilization -file [file join $branch_dir clock_utilization.rpt]
report_drc -file [file join $branch_dir drc.rpt]

set paths [get_timing_paths -quiet -delay_type max -max_paths 1]
if {[llength $paths] > 0} {
  set wns [get_property SLACK [lindex $paths 0]]
  set closed [expr {$wns >= 0.0}]
} else {
  set wns "NA"
  set closed 0
}
set result [open [file join $branch_dir result.txt] w]
puts $result "branch=forced_replication"
puts $result "wns_ns=$wns"
puts $result "timing_closed_317mhz=$closed"
close $result
puts "ENABLE_REPLICATION_AB branch=forced_replication wns_ns=$wns timing_closed=$closed"
exit
