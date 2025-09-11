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
set defines_file "define.txt"
set define_flags ""

if {[file exists $defines_file]} {
    set fp_def [open $defines_file r]
    while {[gets $fp_def line] >= 0} {
        set line_trim [string trim $line]
        if { $line_trim ne "" && [string first "=" $line_trim] > 0 } {
            set define_flags "$define_flags+define+$line_trim "
        }
    }
    close $fp_def
}

vlog -work work -svinputport=relaxed ./data-sim.sv
# Read the file_list.txt file and execute vlog commands for each line, passing defines
set file_list "file_list.txt"
set fp [open $file_list r]
while {[gets $fp line] >= 0} {
    if {[string trim $line] ne ""} {
        vlog -work work $define_flags -svinputport=relaxed ${GIT_ROOT}/$line
    }
}
close $fp

# vlog -work work $define_flags -svinputport=relaxed ${GIT_ROOT}/rtl/pack_param/ifn9/pack_param.sv
# vlog -work work $define_flags -svinputport=relaxed ${GIT_ROOT}/rtl/pack_typedef/pack_typedef.sv
# vlog -work work $define_flags -svinputport=relaxed ${GIT_ROOT}/rtl/csa/csa_lib.sv
# vlog -work work $define_flags -svinputport=relaxed ${GIT_ROOT}/rtl/mux-mult/ifn9/mux_mult_06.sv
# vlog -work work $define_flags -svinputport=relaxed ${GIT_ROOT}/rtl/mult-matrices/ifn9/mult_matrices_simplified.sv
# vlog -work work $define_flags -svinputport=relaxed ${GIT_ROOT}/rtl/core-mux/core.sv
# vlog -work work $define_flags -svinputport=relaxed ${GIT_ROOT}/rtl/mem/mem.sv

vlog -work work $define_flags -svinputport=relaxed ./control.sv
vlog -work work $define_flags -svinputport=relaxed ./tb_control.sv
# vsim -voptargs=+acc -coverage -t ns work.tb
vsim -voptargs=+acc -t ns work.tb
set StdArithNoWarnings 1
set StdVitalGlitchNoWarnings 1
do wave.do
do mem.do

# all blocks
#run 50000ns
# 4 blocks
#run 4000ns
# one line
run 7000ns
#run -all

# coverage report -output report.txt -srcfile=* -assert -directive -cvg -codeAll
