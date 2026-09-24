set dcp [file normalize [lindex $argv 0]]
set netlist [file normalize [lindex $argv 1]]
set simlib_dir [file normalize [lindex $argv 2]]

open_checkpoint $dcp
write_verilog -force -mode funcsim $netlist
close_design

compile_simlib \
  -simulator xcelium \
  -family zynquplus \
  -language verilog \
  -library unisim \
  -directory $simlib_dir \
  -no_ip_compile \
  -force

exit
