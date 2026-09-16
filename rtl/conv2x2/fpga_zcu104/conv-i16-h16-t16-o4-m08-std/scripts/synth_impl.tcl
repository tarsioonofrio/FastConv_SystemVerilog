# Vivado 2023.2 batch implementation flow for the canonical Conv baseline.
# Usage: vivado -mode batch -source synth_impl.tcl -tclargs <run> <period_ns>

set script_dir [file dirname [file normalize [info script]]]
set bench_dir [file normalize [file join $script_dir ..]]
set repo_root [file normalize [file join $bench_dir ../../../../]]
if {$argc < 2} {
  puts stderr "usage: synth_impl.tcl <run-name> <period-ns>"
  exit 2
}
set run_name [lindex $argv 0]
set period_ns [lindex $argv 1]
set run_dir [file join $bench_dir reports $run_name]
file mkdir $run_dir

set vivado_version [version -short]
set fp [open [file join $run_dir metadata.txt] w]
puts $fp "vivado_version=$vivado_version"
puts $fp "part=xczu7ev-ffvc1156-2-e"
puts $fp "top=Conv"
puts $fp "target_period_ns=$period_ns"
puts $fp "target_frequency_mhz=[expr {1000.0 / $period_ns}]"
close $fp

set manifest [file join $bench_dir rtl_manifest.txt]
set sources [open $manifest r]
while {[gets $sources line] >= 0} {
  set line [string trim $line]
  if {$line eq "" || [string match "#*" $line]} { continue }
  set source [file normalize [file join $repo_root $line]]
  if {![file exists $source]} {
    error "RTL source does not exist: $source"
  }
  read_verilog -sv $source
}
close $sources

# The 317 MHz experiment uses the checked-in XDC. Fmax runs use the same
# command path with a generated period, so every run has an explicit clock.
if {$run_name eq "317mhz"} {
  read_xdc [file join $bench_dir constraints zcu104_317mhz.xdc]
}

synth_design -top Conv -part xczu7ev-ffvc1156-2-e
# Generated-period Fmax runs cannot query top-level ports until synthesis has
# opened the design. Apply their clock/reset constraints before placement.
if {$run_name ne "317mhz"} {
  create_clock -name clk -period $period_ns [get_ports clk]
  set_false_path -from [get_ports reset]
}
write_checkpoint -force [file join $run_dir design_synth.dcp]
opt_design
place_design
phys_opt_design
route_design
write_checkpoint -force [file join $run_dir design_routed.dcp]
# Keep post-route simulation artifacts beside the checkpoint. The default
# campaign consumes these with XSim for SAIF and does not emit a VCD.
write_verilog -mode timesim -sdf_anno true -force [file join $run_dir design_routed_timesim.v]
write_sdf -force [file join $run_dir design_routed.sdf]

report_utilization -hierarchical -file [file join $run_dir utilization.rpt]
report_timing_summary -delay_type max -report_unconstrained -check_timing_verbose -max_paths 20 -file [file join $run_dir timing_summary.rpt]
report_clock_utilization -file [file join $run_dir clock_utilization.rpt]
report_methodology -file [file join $run_dir methodology.rpt]
report_drc -file [file join $run_dir drc.rpt]
puts "IMPLEMENTATION_COMPLETE run=$run_name period_ns=$period_ns"
