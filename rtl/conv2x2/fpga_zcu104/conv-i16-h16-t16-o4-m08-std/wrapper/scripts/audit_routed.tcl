# Read-only audit of an existing post-route wrapper checkpoint.
if {$argc != 2} {
  puts stderr "usage: audit_routed.tcl <dcp> <output-dir>"
  exit 2
}
set dcp [file normalize [lindex $argv 0]]
set out_dir [file normalize [lindex $argv 1]]
file mkdir $out_dir
open_checkpoint $dcp

report_utilization -file [file join $out_dir utilization_flat.rpt]
report_utilization -hierarchical -file [file join $out_dir utilization_hierarchical.rpt]
report_timing_summary -delay_type max -report_unconstrained -check_timing_verbose \
  -max_paths 40 -file [file join $out_dir timing_summary.rpt]
report_clocks -file [file join $out_dir clocks.rpt]
report_io -file [file join $out_dir io.rpt]

set counts [open [file join $out_dir cell_counts.txt] w]
puts $counts "design=[get_property NAME [current_design]]"
set port_names {}
foreach port [get_ports *] {
  lappend port_names [get_property NAME $port]
}
puts $counts "ports=[lsort $port_names]"
foreach ref {RAMB18E2 RAMB36E2 DSP48E2 URAM288} {
  set cells [get_cells -hier -filter "REF_NAME == $ref"]
  puts $counts "$ref=[llength $cells]"
}
foreach ref {LUT1 LUT2 LUT3 LUT4 LUT5 LUT6 FDCE FDPE FDRE FDSE} {
  set cells [get_cells -hier -filter "REF_NAME == $ref"]
  puts $counts "$ref=[llength $cells]"
}
close $counts

set rams [get_cells -hier -filter {REF_NAME =~ RAMB*}]
set seqs [get_cells -hier -filter {REF_NAME =~ FD*}]
if {[llength $rams] > 0 && [llength $seqs] > 0} {
  set timing_status [catch {
    report_timing -from $rams -to $seqs -delay_type max -max_paths 40 \
      -path_type full -file [file join $out_dir bram_to_core_timing.rpt]
  } timing_error]
  if {$timing_status != 0} {
    set f [open [file join $out_dir bram_to_core_timing_error.txt] w]
    puts $f $timing_error
    close $f
  }
}
puts "ROUTED_AUDIT_COMPLETE dcp=$dcp"
close_design
exit
