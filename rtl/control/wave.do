onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/dut/clk
add wave -noupdate /tb/dut/reset
add wave -noupdate /tb/dut/p_start
add wave -noupdate /tb/dut/p_end
add wave -noupdate /tb/dut/p_start_conv
add wave -noupdate /tb/dut/p_reuse
add wave -noupdate -expand /tb/dut/p_end_conv
add wave -noupdate /tb/dut/p_wh_en
add wave -noupdate /tb/dut/p_wh_valid
add wave -noupdate /tb/dut/p_fin_en
add wave -noupdate /tb/dut/p_fin_valid
add wave -noupdate /tb/dut/p_fout_en
add wave -noupdate /tb/dut/p_fout_valid
add wave -noupdate -radix decimal /tb/dut/p_out_data
add wave -noupdate -radix decimal /tb/dut/p_in_data
add wave -noupdate /tb/dut/w_input_end
add wave -noupdate /tb/dut/w_conv_idle
add wave -noupdate /tb/dut/w_conv_end
add wave -noupdate /tb/dut/w_output_idle
add wave -noupdate /tb/dut/current_st_input
add wave -noupdate /tb/dut/next_st_input
add wave -noupdate /tb/dut/current_st_conv
add wave -noupdate /tb/dut/next_st_conv
add wave -noupdate /tb/dut/current_st_output
add wave -noupdate /tb/dut/next_st_output
add wave -noupdate /tb/dut/r_start_conv
add wave -noupdate /tb/dut/r_data_end
add wave -noupdate /tb/dut/r_conv_end
add wave -noupdate /tb/dut/r_wh_en
add wave -noupdate /tb/dut/r_fin_en
add wave -noupdate /tb/dut/r_end_wh
add wave -noupdate /tb/dut/r_end_fin
add wave -noupdate /tb/dut/r_reuse
add wave -noupdate /tb/dut/r_count_wh
add wave -noupdate /tb/dut/r_count_fin
add wave -noupdate /tb/dut/r_count_fout
add wave -noupdate /tb/dut/r_addr_bias
add wave -noupdate /tb/dut/r_addr_wh
add wave -noupdate /tb/dut/r_addr_fin_base
add wave -noupdate /tb/dut/r_addr_fin
add wave -noupdate /tb/dut/r_addr_fout_base
add wave -noupdate /tb/dut/r_addr_fout
add wave -noupdate /tb/dut/r_count_window
add wave -noupdate /tb/dut/r_count_horizontal
add wave -noupdate /tb/dut/r_count_vertical
add wave -noupdate -radix decimal /tb/dut/w_mrd_out
add wave -noupdate -radix decimal /tb/dut/w_mrd_in
add wave -noupdate -radix decimal /tb/dut/w_mwr_out
add wave -noupdate -radix decimal /tb/dut/w_mwr_in
add wave -noupdate /tb/dut/w_mrd_chip
add wave -noupdate /tb/dut/w_mrd_wr
add wave -noupdate /tb/dut/w_mrd_valid
add wave -noupdate -radix decimal /tb/dut/w_mrd_addr
add wave -noupdate /tb/dut/w_mwr_chip
add wave -noupdate /tb/dut/w_mwr_wr
add wave -noupdate /tb/dut/w_mwr_valid
add wave -noupdate -radix decimal /tb/dut/w_mwr_addr
add wave -noupdate /tb/dut/w_horizontal_end
add wave -noupdate /tb/dut/w_wh_end
add wave -noupdate /tb/dut/w_fin_end
add wave -noupdate /tb/core/clk
add wave -noupdate /tb/core/reset
add wave -noupdate /tb/core/p_start
add wave -noupdate /tb/core/p_reuse
add wave -noupdate /tb/core/p_end
add wave -noupdate /tb/core/p_fin_en
add wave -noupdate /tb/core/p_fin_valid
add wave -noupdate /tb/core/p_wh_en
add wave -noupdate /tb/core/p_wh_valid
add wave -noupdate /tb/core/p_fout_en
add wave -noupdate /tb/core/p_fout_valid
add wave -noupdate -radix decimal /tb/core/p_in_data
add wave -noupdate -radix decimal /tb/core/p_out_data
add wave -noupdate /tb/core/current_st_input
add wave -noupdate /tb/core/next_st_input
add wave -noupdate /tb/core/current_st_conv
add wave -noupdate /tb/core/next_st_conv
add wave -noupdate /tb/core/current_st_output
add wave -noupdate /tb/core/next_st_output
add wave -noupdate -radix decimal /tb/core/r_feat_in
add wave -noupdate -radix decimal /tb/core/r_weight
add wave -noupdate -radix decimal /tb/core/r_conv
add wave -noupdate -radix decimal /tb/core/r_feat_out
add wave -noupdate -radix decimal /tb/core/w_prod_c
add wave -noupdate -radix decimal /tb/core/w_prod_a
add wave -noupdate /tb/core/r_reuse
add wave -noupdate /tb/core/r_fout_en
add wave -noupdate /tb/core/r_end
add wave -noupdate /tb/core/r_fout_valid
add wave -noupdate /tb/core/w_end
add wave -noupdate /tb/core/r_count_wh
add wave -noupdate /tb/core/r_count_fin
add wave -noupdate /tb/core/r_count_fout
add wave -noupdate /tb/core/product
add wave -noupdate -radix decimal /tb/core/r_mult_idx
add wave -noupdate /tb/core/w_wh_fin_en
add wave -noupdate /tb/core/c_index
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1306 ns} 0}
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
WaveRestoreZoom {1889 ns} {2113 ns}
