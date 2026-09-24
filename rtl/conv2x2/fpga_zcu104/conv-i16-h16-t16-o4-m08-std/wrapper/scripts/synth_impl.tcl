# Non-project Vivado implementation for the common BRAM wrapper pilot.
set script_dir [file dirname [file normalize [info script]]]
set wrapper_dir [file normalize [file join $script_dir ..]]
set bench_dir [file normalize [file join $wrapper_dir ..]]
set repo_root [file normalize [file join $bench_dir ../../../../]]
set memory_dir [file join $wrapper_dir data]

if {$argc != 1} {
  puts stderr "usage: vivado -mode batch -source synth_impl.tcl -tclargs <run-name>"
  exit 2
}
set run_name [lindex $argv 0]
set run_dir [file join $wrapper_dir reports $run_name]
file mkdir $run_dir

set metadata [open [file join $run_dir metadata.txt] w]
puts $metadata "vivado_version=[version -short]"
puts $metadata "part=xczu7ev-ffvc1156-2-e"
puts $metadata "top=fpga_benchmark_top"
puts $metadata "target_period_ns=3.154574"
puts $metadata "target_frequency_mhz=317.000"
close $metadata

set manifest [open [file join $bench_dir rtl_manifest.txt] r]
while {[gets $manifest line] >= 0} {
  set line [string trim $line]
  if {$line eq "" || [string match "#*" $line]} { continue }
  set source [file normalize [file join $repo_root $line]]
  if {![file exists $source]} { error "missing core source: $source" }
  read_verilog -sv $source
}
close $manifest

read_verilog -sv [file join $wrapper_dir rtl fpga_benchmark_top.sv]
read_xdc [file join $wrapper_dir constraints zcu104_317mhz.xdc]

# XPM_MEMORY_INIT_FILE is intentionally a basename. Elaborate and synthesize
# from the directory containing the deterministic .mem images.
cd $memory_dir
synth_design -top fpga_benchmark_top -part xczu7ev-ffvc1156-2-e
write_checkpoint -force [file join $run_dir design_synth.dcp]
opt_design
place_design
phys_opt_design
route_design
write_checkpoint -force [file join $run_dir design_routed.dcp]
write_verilog -mode funcsim -force [file join $run_dir design_routed_funcsim.v]

report_utilization -hierarchical -file [file join $run_dir utilization.rpt]
report_timing_summary -delay_type max -report_unconstrained -check_timing_verbose -max_paths 30 -file [file join $run_dir timing_summary.rpt]
report_clocks -file [file join $run_dir clocks.rpt]
report_clock_utilization -file [file join $run_dir clock_utilization.rpt]
report_io -file [file join $run_dir io.rpt]
report_methodology -file [file join $run_dir methodology.rpt]
report_drc -file [file join $run_dir drc.rpt]
puts "WRAPPER_IMPLEMENTATION_COMPLETE run=$run_name"
