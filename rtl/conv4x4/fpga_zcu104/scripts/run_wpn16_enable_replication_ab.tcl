# A/B diagnostic for the high-fanout r_transform_partial enable.
# Usage: run_wpn16_enable_replication_ab.tcl <repo-root> <out-dir> <xdc>
# Both implementations branch from the same post-placement checkpoint.
if {$argc != 3} {
  error "usage: run_wpn16_enable_replication_ab.tcl <repo-root> <out-dir> <xdc>"
}

set repo_root [file normalize [lindex $argv 0]]
set out_dir [file normalize [lindex $argv 1]]
set xdc [file normalize [lindex $argv 2]]
set manifest [file join $repo_root rtl/conv4x4/fpga_zcu104/manifests/wpn16_pipe.rtl]
set wrapper [file join $repo_root rtl/stream-column/fpga_zcu104/multicore/wpn16_pipe_replica_top.sv]
set top WPN16PipeReplicaTop
set n_cores 32
set nbits 16

file mkdir $out_dir
set metadata [open [file join $out_dir metadata.txt] w]
puts $metadata "vivado_version=[version -short]"
puts $metadata "part=xczu7ev-ffvc1156-2-e"
puts $metadata "implementation_mode=out_of_context"
puts $metadata "top=$top"
puts $metadata "algorithm=wpn16_pipe_both_nbits16"
puts $metadata "cores=$n_cores"
puts $metadata "NBITS=$nbits"
puts $metadata "target_frequency_mhz=317"
puts $metadata "comparison=baseline_vs_forced_replication_from_same_post_place_checkpoint"
puts $metadata "replication_target=high_fanout_nets_matching_r_transform_partial"
close $metadata

set sources [open $manifest r]
while {[gets $sources line] >= 0} {
  set line [string trim $line]
  if {$line eq "" || [string match "#*" $line]} { continue }
  set source [file normalize [file join $repo_root $line]]
  if {![file exists $source]} { error "RTL source does not exist: $source" }
  read_verilog -sv $source
}
close $sources
read_verilog -sv $wrapper
read_xdc $xdc
synth_design -mode out_of_context -top $top -part xczu7ev-ffvc1156-2-e \
  -generic [list N_CORES=$n_cores NADDR=12 NBITS=$nbits PIPE_WEIGHT_TRANSFORM=1]
report_utilization -file [file join $out_dir utilization_synth.rpt]
opt_design
place_design -directive Explore

set placed_checkpoint [file join $out_dir post_place_common.dcp]
write_checkpoint -force $placed_checkpoint

proc write_branch_reports {out_dir branch} {
  set branch_dir [file join $out_dir $branch]
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
  puts $result "branch=$branch"
  puts $result "wns_ns=$wns"
  puts $result "timing_closed_317mhz=$closed"
  close $result
  puts "ENABLE_REPLICATION_AB branch=$branch wns_ns=$wns timing_closed=$closed"
}

# Baseline branch: normal Explore physical optimization.
phys_opt_design -directive Explore
route_design -directive Explore
write_branch_reports $out_dir baseline

# Diagnostic branch: restart from identical placement, then force replication
# only on high-fanout nets whose names identify the registered-feature enable.
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
phys_opt_design -directive Explore -force_replication_on_nets $force_targets
route_design -directive Explore
write_branch_reports $out_dir forced_replication

exit
