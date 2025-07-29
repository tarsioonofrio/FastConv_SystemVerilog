onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/dut/clk
add wave -noupdate /tb/dut/reset
add wave -noupdate /tb/dut/p_start
add wave -noupdate /tb/dut/p_end
add wave -noupdate /tb/dut/p_debug
add wave -noupdate /tb/dut/p_fin_en
add wave -noupdate /tb/dut/p_fin_valid
add wave -noupdate /tb/dut/p_wh_en
add wave -noupdate /tb/dut/p_wh_valid
add wave -noupdate /tb/dut/p_fout_en
add wave -noupdate /tb/dut/p_fout_valid
add wave -noupdate -radix decimal /tb/dut/p_in_data
add wave -noupdate -radix decimal /tb/dut/p_out_data
add wave -noupdate /tb/dut/current_st
add wave -noupdate /tb/dut/next_st
add wave -noupdate /tb/dut/r_fout_en
add wave -noupdate /tb/dut/r_conv_end
add wave -noupdate /tb/dut/r_end
add wave -noupdate /tb/dut/r_fout_valid
add wave -noupdate /tb/dut/r_count
add wave -noupdate -radix decimal /tb/dut/r_mult_idx
add wave -noupdate /tb/dut/product
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1061 ns} 0}
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
WaveRestoreZoom {966 ns} {1197 ns}
