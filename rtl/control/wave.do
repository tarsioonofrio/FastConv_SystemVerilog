onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/dut/clk
add wave -noupdate /tb/dut/reset
add wave -noupdate /tb/dut/p_start
add wave -noupdate /tb/dut/p_end
add wave -noupdate /tb/dut/p_start_conv
add wave -noupdate -expand /tb/dut/p_end_conv
add wave -noupdate /tb/dut/p_wh_en
add wave -noupdate /tb/dut/p_fin_en
add wave -noupdate /tb/dut/p_wh_valid
add wave -noupdate /tb/dut/p_fin_valid
add wave -noupdate /tb/dut/p_fout_en
add wave -noupdate /tb/dut/p_fout_valid
add wave -noupdate -radix decimal /tb/dut/p_out_data
add wave -noupdate -radix decimal /tb/dut/p_in_data
add wave -noupdate /tb/dut/current_st
add wave -noupdate /tb/dut/next_st
add wave -noupdate /tb/dut/r_start_conv
add wave -noupdate /tb/dut/r_wh_en
add wave -noupdate /tb/dut/r_fin_en
add wave -noupdate /tb/dut/r_addr_bias
add wave -noupdate /tb/dut/r_addr_wh
add wave -noupdate /tb/dut/r_addr_fin
add wave -noupdate /tb/dut/r_addr_fout
add wave -noupdate /tb/dut/r_count_window
add wave -noupdate -radix decimal /tb/dut/data_out
add wave -noupdate -radix decimal /tb/dut/data_in
add wave -noupdate /tb/dut/chip_en
add wave -noupdate /tb/dut/wr_en
add wave -noupdate /tb/dut/data_valid_out
add wave -noupdate -radix decimal /tb/dut/address
add wave -noupdate /tb/core/clk
add wave -noupdate /tb/core/reset
add wave -noupdate /tb/core/p_start
add wave -noupdate /tb/core/p_end
add wave -noupdate /tb/core/p_fin_en
add wave -noupdate /tb/core/p_fin_valid
add wave -noupdate /tb/core/p_wh_en
add wave -noupdate /tb/core/p_wh_valid
add wave -noupdate /tb/core/p_fout_en
add wave -noupdate /tb/core/p_fout_valid
add wave -noupdate -radix decimal /tb/core/p_in_data
add wave -noupdate -radix decimal /tb/core/p_out_data
add wave -noupdate /tb/core/current_st
add wave -noupdate /tb/core/next_st
add wave -noupdate /tb/core/r_fout_en
add wave -noupdate /tb/core/r_conv_end
add wave -noupdate /tb/core/r_end
add wave -noupdate /tb/core/r_fout_valid
add wave -noupdate -radix decimal /tb/core/r_mult_idx
add wave -noupdate /tb/core/product
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {725 ns} 0}
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
WaveRestoreZoom {628 ns} {742 ns}
