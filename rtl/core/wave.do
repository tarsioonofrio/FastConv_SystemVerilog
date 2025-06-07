onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/dut/clk
add wave -noupdate /tb/dut/reset
add wave -noupdate /tb/dut/p_start
add wave -noupdate /tb/dut/p_end
add wave -noupdate /tb/dut/p_debug
add wave -noupdate /tb/dut/p_in_ce
add wave -noupdate /tb/dut/p_in_we
add wave -noupdate /tb/dut/p_in_valid
add wave -noupdate /tb/dut/p_wh_ce
add wave -noupdate /tb/dut/p_wh_we
add wave -noupdate /tb/dut/p_wh_valid
add wave -noupdate /tb/dut/p_out_ce
add wave -noupdate /tb/dut/p_out_we
add wave -noupdate /tb/dut/p_out_valid
add wave -noupdate /tb/dut/p_in_data
add wave -noupdate /tb/dut/p_out_data
add wave -noupdate /tb/dut/input_map
add wave -noupdate /tb/dut/output_map
add wave -noupdate -radix decimal /tb/dut/parallel_out
add wave -noupdate /tb/dut/output_valid
add wave -noupdate /tb/dut/register_weight
add wave -noupdate /tb/dut/registers_in
add wave -noupdate /tb/dut/registers_out
add wave -noupdate /tb/dut/out_ce
add wave -noupdate /tb/dut/out_we
add wave -noupdate /tb/dut/out_valid
add wave -noupdate /tb/dut/serial_valid_in
add wave -noupdate /tb/dut/parallel_valid_in
add wave -noupdate /tb/dut/serial_valid_out
add wave -noupdate /tb/dut/parallel_valid_out
add wave -noupdate /tb/dut/count_to_serial
add wave -noupdate /tb/dut/count_to_parallel
add wave -noupdate /tb/dut/feature_out
add wave -noupdate /tb/dut/weight_out
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {135 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 229
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {788 ns} {848 ns}
