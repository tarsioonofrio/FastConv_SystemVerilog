onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/dut/clk
add wave -noupdate /tb/dut/reset
add wave -noupdate /tb/dut/p_start
add wave -noupdate /tb/dut/p_start_conv
add wave -noupdate /tb/dut/p_end
add wave -noupdate /tb/dut/p_fin_en
add wave -noupdate /tb/dut/p_fin_valid
add wave -noupdate /tb/dut/p_wh_en
add wave -noupdate /tb/dut/p_wh_valid
add wave -noupdate /tb/dut/p_fout_en
add wave -noupdate /tb/dut/p_fout_valid
add wave -noupdate -radix decimal /tb/dut/p_fin_data
add wave -noupdate -radix decimal /tb/dut/p_fout_data
add wave -noupdate /tb/dut/current_st
add wave -noupdate /tb/dut/next_st
add wave -noupdate /tb/dut/r_start_conv
add wave -noupdate /tb/dut/r_fout_en
add wave -noupdate /tb/dut/r_data_end
add wave -noupdate /tb/dut/r_conv_end
add wave -noupdate /tb/dut/r_count_wh
add wave -noupdate /tb/dut/r_count_fin
add wave -noupdate /tb/dut/r_count_fout
add wave -noupdate /tb/dut/r_addr_bias
add wave -noupdate /tb/dut/r_addr_wh
add wave -noupdate /tb/dut/r_addr_fin
add wave -noupdate /tb/dut/r_addr_fout
add wave -noupdate /tb/dut/r_count_window
add wave -noupdate -radix decimal /tb/dut/data_fin
add wave -noupdate -radix decimal /tb/dut/data_fout
add wave -noupdate /tb/dut/chip_en
add wave -noupdate /tb/dut/r_chip_en
add wave -noupdate /tb/dut/wr_en
add wave -noupdate /tb/dut/data_valid_fin
add wave -noupdate -radix decimal /tb/dut/address
add wave -noupdate /tb/dut/memory/clk
add wave -noupdate /tb/dut/memory/reset
add wave -noupdate /tb/dut/memory/chip_en
add wave -noupdate /tb/dut/memory/wr_en
add wave -noupdate -radix decimal /tb/dut/memory/address
add wave -noupdate -radix decimal /tb/dut/memory/data_in
add wave -noupdate -radix decimal /tb/dut/memory/data_out
add wave -noupdate /tb/dut/memory/data_valid
add wave -noupdate /tb/dut/memory/r_cycles_latency
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {988 ns} 0}
quietly wave cursor active 1
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
WaveRestoreZoom {0 ns} {231 ns}
