if {[file isdirectory work]} { vdel -all -lib work }
vlib work
vmap work work

set GIT_ROOT [exec git rev-parse --show-toplevel]

# if {[info exists ::env(DATA)]} {
#     set DATA_SV $::env(DATA)
# } else {
#     set DATA_SV "${GIT_ROOT}/data/ifn9/data.sv"
# }
# vlog -work work  -svinputport=relaxed $DATA_SV

# Read key=value defines from define.txt and build the +define+key=value flags
set defines_file "../list-def.txt"
set define_flags ""

if {[file exists $defines_file]} {
    set fp_def [open $defines_file r]
    while {[gets $fp_def line] >= 0} {
        set line_trim [string trim $line]
        set line_trim [string range $line_trim 8 end]
        if { $line_trim ne "" && [string first "=" $line_trim] > 0 } {
            set define_flags "$define_flags+define+$line_trim "
        }
    }
    close $fp_def
}

# vlog -work work -svinputport=relaxed ./data-sim.sv

# Read the file_list.txt file and execute vlog commands for each line, passing defines
set file_list "../list-file.txt"
set fp [open $file_list r]
while {[gets $fp line] >= 0} {
    if {[string trim $line] ne ""} {
        vlog -work work $define_flags -svinputport=relaxed ${GIT_ROOT}/$line
    }
}
close $fp

vlog -work work $define_flags -svinputport=relaxed /pdk/tsmc/PDK28/PDK_TSMC28_bv/tcbn28hpcplusbwp30p140_190a/TSMCHOME/digital/Front_End/verilog/tcbn28hpcplusbwp30p140_110a/tcbn28hpcplusbwp30p140.v
vlog -work work $define_flags -svinputport=relaxed ../logical/results/gate_level/system_logic_mapped.v
vlog -work work $define_flags -svinputport=relaxed ${GIT_ROOT}/rtl/system/testbench-netlist.sv
# to show FSM
# vsim -voptargs=+acc -t ns -fsmdebug -coverage -debugDB work.tb
vsim -voptargs=+acc -t ns work.tb
set StdArithNoWarnings 1
set StdVitalGlitchNoWarnings 1
do wave.do

# all blocks
#run 50000ns
# run 2000ns
# 4 blocks
#run 4000ns
# one line
# run 7000ns
run -all

# coverage report -output report.txt -srcfile=* -assert -directive -cvg -codeAll
