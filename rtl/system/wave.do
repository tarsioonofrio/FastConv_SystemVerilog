onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/dut/clk
add wave -noupdate /tb/dut/reset
add wave -noupdate /tb/dut/p_start
add wave -noupdate /tb/dut/p_end
add wave -noupdate /tb/dut/clk
add wave -noupdate /tb/dut/reset
add wave -noupdate /tb/dut/p_start
add wave -noupdate /tb/dut/p_end
add wave -noupdate /tb/dut/w_conv_start
add wave -noupdate /tb/dut/w_conv_end
add wave -noupdate -radix unsigned /tb/dut/w_input
add wave -noupdate -radix unsigned /tb/dut/w_weight
add wave -noupdate -radix unsigned /tb/dut/w_output
add wave -noupdate /tb/dut/w_read_en
add wave -noupdate /tb/dut/w_read_wr
add wave -noupdate /tb/dut/w_read_valid
add wave -noupdate -radix unsigned /tb/dut/w_read_addr
add wave -noupdate -radix unsigned /tb/dut/w_read_in
add wave -noupdate -radix unsigned /tb/dut/w_read_data
add wave -noupdate /tb/dut/w_write_chip
add wave -noupdate /tb/dut/w_write_en
add wave -noupdate /tb/dut/w_write_valid
add wave -noupdate -radix unsigned /tb/dut/w_write_addr
add wave -noupdate -radix unsigned /tb/dut/w_write_data
add wave -noupdate -radix unsigned /tb/dut/w_write_out
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2295 ns} 0 Red default} {{Cursor 2} {2475 ns} 0}
quietly wave cursor active 2
configure wave -namecolwidth 300
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
WaveRestoreZoom {3535 ns} {7183 ns}
