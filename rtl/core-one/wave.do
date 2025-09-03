onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/dut/clk
add wave -noupdate /tb/dut/reset
add wave -noupdate /tb/dut/p_start
add wave -noupdate /tb/dut/p_reuse
add wave -noupdate /tb/dut/p_end
add wave -noupdate /tb/dut/p_fin_en
add wave -noupdate /tb/dut/p_fin_valid
add wave -noupdate /tb/dut/p_wh_en
add wave -noupdate /tb/dut/p_wh_valid
add wave -noupdate /tb/dut/p_fout_en
add wave -noupdate /tb/dut/p_fout_valid
add wave -noupdate -radix decimal /tb/dut/p_in_data
add wave -noupdate -radix decimal /tb/dut/p_out_data
add wave -noupdate /tb/dut/w_wh_fin_en
add wave -noupdate /tb/dut/current_st_input
add wave -noupdate /tb/dut/next_st_input
add wave -noupdate /tb/dut/current_st_conv
add wave -noupdate /tb/dut/next_st_conv
add wave -noupdate /tb/dut/current_st_output
add wave -noupdate /tb/dut/next_st_output
add wave -noupdate -radix decimal /tb/dut/r_feat_in
add wave -noupdate -radix decimal /tb/dut/r_weight
add wave -noupdate -radix decimal /tb/dut/r_temp
add wave -noupdate -radix decimal /tb/dut/r_feat_out
add wave -noupdate -radix decimal /tb/dut/w_prod_c
add wave -noupdate -radix decimal /tb/dut/w_prod_a
add wave -noupdate /tb/dut/r_reuse
add wave -noupdate /tb/dut/r_fout_en
add wave -noupdate /tb/dut/r_conv_end
add wave -noupdate /tb/dut/r_end
add wave -noupdate /tb/dut/r_fout_valid
add wave -noupdate /tb/dut/w_end
add wave -noupdate /tb/dut/w_end_conv
add wave -noupdate /tb/dut/r_count_wh
add wave -noupdate /tb/dut/r_count_fin
add wave -noupdate /tb/dut/r_count_fout
add wave -noupdate -radix decimal /tb/dut/r_mult_idx
add wave -noupdate -radix decimal /tb/dut/product
add wave -noupdate /tb/dut/w_wh_fin_en
add wave -noupdate /tb/dut/c_index
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {705 ns} 0}
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
WaveRestoreZoom {77 ns} {301 ns}
