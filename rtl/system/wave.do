onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/dut/w_conv_start
add wave -noupdate /tb/dut/w_conv_end
add wave -noupdate /tb/memory_write/clk
add wave -noupdate /tb/memory_write/reset
add wave -noupdate /tb/memory_write/chip_en
add wave -noupdate /tb/memory_write/wr_en
add wave -noupdate -radix unsigned /tb/memory_write/address
add wave -noupdate -radix unsigned /tb/memory_write/data_in
add wave -noupdate -radix unsigned /tb/memory_write/data_out
add wave -noupdate /tb/memory_write/data_valid
add wave -noupdate /tb/memory_write/r_cycles_latency
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {129000 ps} 1 Red default} {{Cursor 2} {73500 ps} 0}
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
WaveRestoreZoom {1729123 ps} {1757941 ps}
