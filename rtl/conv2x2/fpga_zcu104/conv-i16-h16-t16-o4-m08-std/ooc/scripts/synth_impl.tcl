# Vivado non-project OOC synthesis and implementation of the frozen Conv IP.
# Usage: vivado -mode batch -source synth_impl.tcl -tclargs <run-name>
set script_dir [file dirname [file normalize [info script]]]
set ooc_dir [file normalize [file join $script_dir ..]]
set bench_dir [file normalize [file join $ooc_dir ..]]
set repo_root [file normalize [file join $bench_dir ../../../../]]
if {$argc != 1} {
  puts stderr "usage: synth_impl.tcl <run-name>"
  exit 2
}
set run_name [lindex $argv 0]
if {![regexp {^[A-Za-z0-9._-]+$} $run_name]} {
  error "invalid run name: $run_name"
}
set run_dir [file join $ooc_dir reports $run_name]
file mkdir $run_dir

set fp [open [file join $run_dir metadata.txt] w]
puts $fp "vivado_version=[version -short]"
puts $fp "part=xczu7ev-ffvc1156-2-e"
puts $fp "top=Conv"
puts $fp "synthesis_mode=out_of_context"
puts $fp "target_period_ns=3.154574"
puts $fp "target_frequency_mhz=317.000"
puts $fp "boundary_assumption=0 ns external input/output delay"
puts $fp "reset_exception=asynchronous reset paths excluded from synchronous data-path closure"
close $fp

set manifest [file join $bench_dir rtl_manifest.txt]
set sources [open $manifest r]
while {[gets $sources line] >= 0} {
  set line [string trim $line]
  if {$line eq "" || [string match "#*" $line]} { continue }
  set source [file normalize [file join $repo_root $line]]
  if {![file exists $source]} { error "RTL source does not exist: $source" }
  read_verilog -sv $source
}
close $sources

read_xdc -mode out_of_context [file join $ooc_dir constraints ooc_317mhz.xdc]
synth_design -mode out_of_context -top Conv -part xczu7ev-ffvc1156-2-e
write_checkpoint -force [file join $run_dir design_synth_ooc.dcp]
opt_design
place_design
phys_opt_design
route_design
write_checkpoint -force [file join $run_dir design_routed_ooc.dcp]
write_verilog -mode funcsim -force [file join $run_dir design_routed_ooc_funcsim.v]

set iobuf_cells [get_cells -hier -quiet -filter {REF_NAME =~ IBUF* || REF_NAME =~ OBUF* || REF_NAME =~ IOBUF*}]
set iobuf_count [llength $iobuf_cells]
set fp [open [file join $run_dir io_buffer_audit.txt] w]
puts $fp "iobuf_count=$iobuf_count"
foreach cell $iobuf_cells { puts $fp "cell=$cell ref_name=[get_property REF_NAME $cell]" }
close $fp
if {$iobuf_count != 0} { error "OOC flow unexpectedly inserted I/O buffers: $iobuf_count" }

report_utilization -hierarchical -file [file join $run_dir utilization.rpt]
report_io -file [file join $run_dir io.rpt]
report_timing_summary -delay_type max -report_unconstrained -check_timing_verbose -max_paths 30 -file [file join $run_dir timing_summary.rpt]
set reg_cells [all_registers -clock [get_clocks clk]]
report_timing -from $reg_cells -to $reg_cells -max_paths 30 -path_type full_clock_expanded -file [file join $run_dir timing_reg_to_reg.rpt]
report_timing -from [get_ports {p_start p_input_data[*] p_input_valid p_output_data_read[*] p_output_valid}] -to $reg_cells -max_paths 30 -path_type full_clock_expanded -file [file join $run_dir timing_input_boundary.rpt]
report_timing -from $reg_cells -to [get_ports {p_end p_input_en p_input_addr[*] p_output_en p_output_wr p_output_addr[*] p_output_data_write[*]}] -max_paths 30 -path_type full_clock_expanded -file [file join $run_dir timing_output_boundary.rpt]
report_clock_utilization -file [file join $run_dir clock_utilization.rpt]
report_drc -file [file join $run_dir drc.rpt]
puts "OOC_IMPLEMENTATION_COMPLETE run=$run_name iobuf_count=$iobuf_count"
