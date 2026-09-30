# Export the routed functional netlist and compile matching Xilinx UNISIM models.
# Usage: prepare_funcsim.tcl <routed-dcp> <netlist.v> <simlib-dir>
if {$argc != 3} { error "usage: prepare_funcsim.tcl <routed-dcp> <netlist.v> <simlib-dir>" }
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
