
# XM-Sim Command File
# TOOL:	xmsim(64)	23.03-s003
#
#
# You can restore this configuration with:
#
#      xrun -f file_list.f -input restore.tcl
#

set tcl_prompt1 {puts -nonewline "xcelium> "}
set tcl_prompt2 {puts -nonewline "> "}
set vlog_format %h
set vhdl_format %v
set real_precision 6
set display_unit auto
set time_unit module
set heap_garbage_size -200
set heap_garbage_time 0
set assert_report_level note
set assert_stop_level error
set autoscope yes
set assert_1164_warnings yes
set pack_assert_off {}
set severity_pack_assert_off {note warning}
set assert_output_stop_level failed
set tcl_debug_level 0
set relax_path_name 1
set vhdl_vcdmap XX01ZX01X
set intovf_severity_level ERROR
set probe_screen_format 0
set rangecnst_severity_level ERROR
set textio_severity_level ERROR
set vital_timing_checks_on 1
set vlog_code_show_force 0
set assert_count_attempts 1
set tcl_all64 false
set tcl_runerror_exit false
set assert_report_incompletes 0
set show_force 1
set force_reset_by_reinvoke 0
set tcl_relaxed_literal 0
set probe_exclude_patterns {}
set probe_packed_limit 4k
set probe_unpacked_limit 16k
set assert_internal_msg no
set svseed 1
set assert_reporting_mode 0
set vcd_compact_mode 0
alias . run
alias indago verisium
alias quit exit
database -open -vcd -into dump.vcd _dump.vcd1 -timescale fs
database -open -shm -into waves.shm waves -default
database -open -vcd -into verilog.dump _verilog.dump1 -timescale fs
probe -create -database waves tb.MAPS tb.clk tb.data_valid tb.inputMAP tb.outputMAP tb.reset tb.start tb.weight tb.weights
probe -create -database waves tb.convolucao.@{\registers[9] } tb.convolucao.@{\registers[10] } tb.convolucao.@{\registers[11] } tb.convolucao.@{\registers[12] } tb.convolucao.@{\registers[13] } tb.convolucao.@{\registers[14] } tb.convolucao.@{\registers[15] } tb.convolucao.@{\registers[16] } tb.convolucao.@{\registers[17] } tb.convolucao.@{\registers[18] } tb.convolucao.@{\registers[19] } tb.convolucao.@{\registers[20] } tb.convolucao.@{\registers[21] } tb.convolucao.@{\registers[22] } tb.convolucao.@{\registers[23] } tb.convolucao.@{\registers[24] } tb.convolucao.@{\registers[25] } tb.convolucao.@{\registers[26] } tb.convolucao.@{\registers[27] } tb.convolucao.@{\registers[28] } tb.convolucao.@{\registers[29] } tb.convolucao.@{\registers[30] } tb.convolucao.@{\registers[31] } tb.convolucao.@{\registers[32] } tb.convolucao.@{\registers[33] } tb.convolucao.@{\registers[34] } tb.convolucao.@{\registers[35] }
probe -create -database waves tb.convolucao.EA

simvision -input restore.tcl.svcf
