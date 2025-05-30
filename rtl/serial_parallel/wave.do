onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/dut/clk
add wave -noupdate /tb/dut/reset
add wave -noupdate /tb/dut/serial_valid
add wave -noupdate /tb/dut/parallel_valid
add wave -noupdate -radix decimal /tb/dut/serial_in
add wave -noupdate -radix decimal /tb/dut/parallel_in
add wave -noupdate -radix decimal /tb/dut/parallel_out
add wave -noupdate -radix decimal /tb/dut/serial_out
add wave -noupdate /tb/dut/current_st_parallel
add wave -noupdate /tb/dut/next_st_parallel
add wave -noupdate /tb/dut/current_st_serial
add wave -noupdate /tb/dut/next_st_serial
add wave -noupdate /tb/dut/count_parallel
add wave -noupdate /tb/dut/count_serial
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
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
WaveRestoreZoom {0 ns} {121 ns}
