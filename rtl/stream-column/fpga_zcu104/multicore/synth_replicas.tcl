# OOC multicore capacity experiment for IFN9 and WPN16.
# Usage: synth_replicas.tcl <repo-root> <out-dir> <algorithm> <cores> <xdc>
if {$argc != 5} {
  error "usage: synth_replicas.tcl <repo-root> <out-dir> <algorithm> <cores> <xdc>"
}
set repo_root [file normalize [lindex $argv 0]]
set out_dir [file normalize [lindex $argv 1]]
set algorithm [lindex $argv 2]
set n_cores [lindex $argv 3]
set xdc [file normalize [lindex $argv 4]]
if {![string is integer -strict $n_cores] || $n_cores < 1} {
  error "core count must be a positive integer: $n_cores"
}
if {$algorithm eq "ifn9"} {
  set top "IFN9ReplicaTop"
  set nbits 20
  set manifest [file join $repo_root rtl/conv3x3/fpga_zcu104/manifests/ifn9.rtl]
  set wrapper [file join $repo_root rtl/stream-column/fpga_zcu104/multicore/ifn9_replica_top.sv]
} elseif {$algorithm eq "ifn9_m18"} {
  set top "IFN9M18ReplicaTop"
  set nbits 16
  set manifest [file join $repo_root rtl/conv3x3/fpga_zcu104/manifests/ifn9_m18.rtl]
  set wrapper [file join $repo_root rtl/stream-column/fpga_zcu104/multicore/ifn9_m18_replica_top.sv]
} elseif {$algorithm eq "wpn16"} {
  set top "WPN16ReplicaTop"
  set nbits 20
  set manifest [file join $repo_root rtl/conv4x4/fpga_zcu104/manifests/wpn16.rtl]
  set wrapper [file join $repo_root rtl/stream-column/fpga_zcu104/multicore/wpn16_replica_top.sv]
} elseif {$algorithm eq "wpn16_nbits16"} {
  set top "WPN16ReplicaTop"
  set nbits 16
  set manifest [file join $repo_root rtl/conv4x4/fpga_zcu104/manifests/wpn16.rtl]
  set wrapper [file join $repo_root rtl/stream-column/fpga_zcu104/multicore/wpn16_replica_top.sv]
} else {
  error "unsupported algorithm: $algorithm (expected ifn9, ifn9_m18, wpn16, or wpn16_nbits16)"
}
file mkdir $out_dir

set metadata [open [file join $out_dir metadata.txt] w]
puts $metadata "vivado_version=[version -short]"
puts $metadata "part=xczu7ev-ffvc1156-2-e"
puts $metadata "implementation_mode=out_of_context"
puts $metadata "top=$top"
puts $metadata "algorithm=$algorithm"
puts $metadata "cores=$n_cores"
puts $metadata "NBITS=$nbits"
if {$algorithm eq "ifn9"} {
  puts $metadata "core_variant=IFN9_m06"
  puts $metadata "mac_lanes_per_core=6"
} elseif {$algorithm eq "ifn9_m18"} {
  puts $metadata "core_variant=IFN9_m18"
  puts $metadata "mac_lanes_per_core=18"
} elseif {$algorithm eq "wpn16" || $algorithm eq "wpn16_nbits16"} {
  puts $metadata "core_variant=WPN16_m08"
  puts $metadata "mac_lanes_per_core=8"
}
puts $metadata "target_period_ns=3.154574"
puts $metadata "target_frequency_mhz=317"
puts $metadata "NADDR=12"
puts $metadata "memory_model=independent_logical_boundary_per_core"
puts $metadata "package_io_buffers=disabled_by_ooc"
puts $metadata "implementation=opt_default_place_Explore_physopt_Explore_route_Explore"
puts $metadata "manifest=$manifest"
puts $metadata "wrapper=$wrapper"
puts $metadata "xdc=$xdc"
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
set generics [list N_CORES=$n_cores NADDR=12]
if {$algorithm eq "ifn9_m18" || $algorithm eq "wpn16" || $algorithm eq "wpn16_nbits16"} {
  lappend generics NBITS=$nbits
}
synth_design -mode out_of_context -top $top -part xczu7ev-ffvc1156-2-e -generic $generics
report_utilization -file [file join $out_dir utilization_synth.rpt]
report_utilization -hierarchical -file [file join $out_dir utilization_hierarchical_synth.rpt]
opt_design
place_design -directive Explore
phys_opt_design -directive Explore
route_design -directive Explore
report_utilization -file [file join $out_dir utilization.rpt]
report_utilization -hierarchical -file [file join $out_dir utilization_hierarchical.rpt]
report_timing_summary -delay_type max -report_unconstrained -check_timing_verbose \
  -max_paths 50 -file [file join $out_dir timing_summary.rpt]
report_timing -delay_type max -max_paths 100 -path_type full_clock_expanded \
  -file [file join $out_dir critical_paths.rpt]
report_clock_utilization -file [file join $out_dir clock_utilization.rpt]
report_drc -file [file join $out_dir drc.rpt]

set paths [get_timing_paths -quiet -delay_type max -max_paths 1]
if {[llength $paths] > 0} {
  set wns [get_property SLACK [lindex $paths 0]]
  set closed [expr {$wns >= 0.0}]
} else {
  set wns "NA"
  set closed 0
}
set summary [open [file join $out_dir result.txt] w]
puts $summary "algorithm=$algorithm"
puts $summary "cores=$n_cores"
puts $summary "NBITS=$nbits"
puts $summary "wns_ns=$wns"
puts $summary "timing_closed_317mhz=$closed"
puts $summary "implementation=OOC_Explore_postplace_physopt_and_route"
close $summary
puts "MULTICORE_CAPACITY_COMPLETE algorithm=$algorithm cores=$n_cores wns_ns=$wns timing_closed=$closed"
exit
