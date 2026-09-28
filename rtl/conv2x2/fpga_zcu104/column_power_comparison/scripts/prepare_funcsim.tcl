# Export a post-route functional netlist and compile the matching UNISIM library.
# Usage: vivado -mode batch -source prepare_funcsim.tcl -tclargs <dcp> <netlist> <simlib-dir>
if {$argc != 3} { error "usage: prepare_funcsim.tcl <dcp> <netlist> <simlib-dir>" }
set dcp [file normalize [lindex $argv 0]]
set netlist [file normalize [lindex $argv 1]]
set simlib_dir [file normalize [lindex $argv 2]]
open_checkpoint $dcp
write_verilog -force -mode funcsim $netlist
close_design
if {![file exists [file join $simlib_dir cds.lib]]} {
  compile_simlib -simulator xcelium -family zynquplus -language verilog -library unisim -directory $simlib_dir -no_ip_compile -force
} else {
  puts "Reusing compiled Xcelium UNISIM library: $simlib_dir"
}
exit
