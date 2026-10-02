# OOC implementation of the WPN16 design with a register barrier between
# InverseRow and InverseRowAccumulate.
# Usage: run_wpn16_inverse_acc_pipe.tcl <repo-root> <out-dir> <xdc>
if {$argc != 3} {
  error "usage: run_wpn16_inverse_acc_pipe.tcl <repo-root> <out-dir> <xdc>"
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
puts $metadata "algorithm=wpn16_dual_transform_dsp_inverse_accumulator_pipeline_nbits16"
puts $metadata "cores=$n_cores"
puts $metadata "NBITS=$nbits"
puts $metadata "target_frequency_mhz=317"
puts $metadata "pipeline_stages=transform_axes,dsp_mreg_preg,inverse_to_accumulator"
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
  -generic [list N_CORES=$n_cores NADDR=12 NBITS=$nbits \
    PIPE_WEIGHT_TRANSFORM=1 PIPE_DSP_MULTIPLIER=1 PIPE_INVERSE_ACCUMULATE=1]
report_utilization -file [file join $out_dir utilization_synth.rpt]
opt_design
place_design -directive Explore
phys_opt_design -directive Explore
route_design -directive Explore

write_checkpoint -force [file join $out_dir routed.dcp]
report_utilization -file [file join $out_dir utilization.rpt]
report_utilization -hierarchical -file [file join $out_dir utilization_hierarchical.rpt]
report_timing_summary -delay_type max -report_unconstrained -check_timing_verbose \
  -max_paths 50 -file [file join $out_dir timing_summary.rpt]
report_timing -delay_type max -max_paths 100 -path_type full_clock_expanded \
  -file [file join $out_dir critical_paths.rpt]
report_clock_utilization -file [file join $out_dir clock_utilization.rpt]
report_drc -file [file join $out_dir drc.rpt]

set dsp_report [open [file join $out_dir dsp_registers.txt] w]
set dsp_cells [get_cells -hier -quiet -filter {REF_NAME == DSP48E2}]
puts $dsp_report "dsp48e2_count=[llength $dsp_cells]"
foreach cell $dsp_cells {
  puts $dsp_report "[get_property NAME $cell] MREG=[get_property MREG $cell] PREG=[get_property PREG $cell] AREG=[get_property AREG $cell] BREG=[get_property BREG $cell]"
}
close $dsp_report

set paths [get_timing_paths -quiet -delay_type max -max_paths 1]
if {[llength $paths] > 0} {
  set wns [get_property SLACK [lindex $paths 0]]
  set closed [expr {$wns >= 0.0}]
} else {
  set wns "NA"
  set closed 0
}
set result [open [file join $out_dir result.txt] w]
puts $result "wns_ns=$wns"
puts $result "timing_closed_317mhz=$closed"
puts $result "dsp48e2_count=[llength $dsp_cells]"
close $result
puts "WPN16_INVERSE_ACC_PIPE wns_ns=$wns timing_closed=$closed dsp48e2=[llength $dsp_cells]"
exit
