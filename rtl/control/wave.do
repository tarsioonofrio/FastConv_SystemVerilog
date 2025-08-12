onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix decimal /tb/dut/clk
add wave -noupdate -radix decimal /tb/dut/reset
add wave -noupdate -radix decimal /tb/dut/p_start
add wave -noupdate -radix decimal /tb/dut/p_end
add wave -noupdate -radix decimal /tb/dut/p_reuse
add wave -noupdate -radix decimal /tb/dut/p_start_conv
add wave -noupdate -radix decimal /tb/dut/p_end_conv
add wave -noupdate -radix decimal /tb/dut/p_start_conv
add wave -noupdate -radix decimal /tb/dut/p_wh_en
add wave -noupdate -radix decimal /tb/dut/p_fin_en
add wave -noupdate -radix decimal /tb/dut/p_wh_valid
add wave -noupdate -radix decimal /tb/dut/p_fin_valid
add wave -noupdate -radix decimal /tb/dut/p_fout_en
add wave -noupdate -radix decimal /tb/dut/p_fout_valid
add wave -noupdate -radix decimal /tb/dut/p_out_data
add wave -noupdate -radix decimal /tb/dut/p_in_data
add wave -noupdate /tb/dut/r_reuse
add wave -noupdate /tb/dut/current_st
add wave -noupdate /tb/dut/next_st
add wave -noupdate /tb/dut/r_reuse
add wave -noupdate /tb/dut/r_start_conv
add wave -noupdate /tb/dut/r_wh_en
add wave -noupdate /tb/dut/r_fin_en
add wave -noupdate /tb/dut/r_count_wh
add wave -noupdate /tb/dut/r_count_fin
add wave -noupdate /tb/dut/r_count_fout
add wave -noupdate /tb/dut/r_addr_bias
add wave -noupdate /tb/dut/r_addr_wh
add wave -noupdate -radix decimal -childformat {{{/tb/dut/r_addr_fin_base[31]} -radix decimal} {{/tb/dut/r_addr_fin_base[30]} -radix decimal} {{/tb/dut/r_addr_fin_base[29]} -radix decimal} {{/tb/dut/r_addr_fin_base[28]} -radix decimal} {{/tb/dut/r_addr_fin_base[27]} -radix decimal} {{/tb/dut/r_addr_fin_base[26]} -radix decimal} {{/tb/dut/r_addr_fin_base[25]} -radix decimal} {{/tb/dut/r_addr_fin_base[24]} -radix decimal} {{/tb/dut/r_addr_fin_base[23]} -radix decimal} {{/tb/dut/r_addr_fin_base[22]} -radix decimal} {{/tb/dut/r_addr_fin_base[21]} -radix decimal} {{/tb/dut/r_addr_fin_base[20]} -radix decimal} {{/tb/dut/r_addr_fin_base[19]} -radix decimal} {{/tb/dut/r_addr_fin_base[18]} -radix decimal} {{/tb/dut/r_addr_fin_base[17]} -radix decimal} {{/tb/dut/r_addr_fin_base[16]} -radix decimal} {{/tb/dut/r_addr_fin_base[15]} -radix decimal} {{/tb/dut/r_addr_fin_base[14]} -radix decimal} {{/tb/dut/r_addr_fin_base[13]} -radix decimal} {{/tb/dut/r_addr_fin_base[12]} -radix decimal} {{/tb/dut/r_addr_fin_base[11]} -radix decimal} {{/tb/dut/r_addr_fin_base[10]} -radix decimal} {{/tb/dut/r_addr_fin_base[9]} -radix decimal} {{/tb/dut/r_addr_fin_base[8]} -radix decimal} {{/tb/dut/r_addr_fin_base[7]} -radix decimal} {{/tb/dut/r_addr_fin_base[6]} -radix decimal} {{/tb/dut/r_addr_fin_base[5]} -radix decimal} {{/tb/dut/r_addr_fin_base[4]} -radix decimal} {{/tb/dut/r_addr_fin_base[3]} -radix decimal} {{/tb/dut/r_addr_fin_base[2]} -radix decimal} {{/tb/dut/r_addr_fin_base[1]} -radix decimal} {{/tb/dut/r_addr_fin_base[0]} -radix decimal}} -subitemconfig {{/tb/dut/r_addr_fin_base[31]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin_base[30]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin_base[29]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin_base[28]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin_base[27]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin_base[26]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin_base[25]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin_base[24]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin_base[23]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin_base[22]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin_base[21]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin_base[20]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin_base[19]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin_base[18]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin_base[17]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin_base[16]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin_base[15]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin_base[14]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin_base[13]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin_base[12]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin_base[11]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin_base[10]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin_base[9]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin_base[8]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin_base[7]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin_base[6]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin_base[5]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin_base[4]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin_base[3]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin_base[2]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin_base[1]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin_base[0]} {-height 16 -radix decimal}} /tb/dut/r_addr_fin_base
add wave -noupdate -radix decimal -childformat {{{/tb/dut/r_addr_fin[25]} -radix decimal} {{/tb/dut/r_addr_fin[24]} -radix decimal} {{/tb/dut/r_addr_fin[23]} -radix decimal} {{/tb/dut/r_addr_fin[22]} -radix decimal} {{/tb/dut/r_addr_fin[21]} -radix decimal} {{/tb/dut/r_addr_fin[20]} -radix decimal} {{/tb/dut/r_addr_fin[19]} -radix decimal} {{/tb/dut/r_addr_fin[18]} -radix decimal} {{/tb/dut/r_addr_fin[17]} -radix decimal} {{/tb/dut/r_addr_fin[16]} -radix decimal} {{/tb/dut/r_addr_fin[15]} -radix decimal} {{/tb/dut/r_addr_fin[14]} -radix decimal} {{/tb/dut/r_addr_fin[13]} -radix decimal} {{/tb/dut/r_addr_fin[12]} -radix decimal} {{/tb/dut/r_addr_fin[11]} -radix decimal} {{/tb/dut/r_addr_fin[10]} -radix decimal} {{/tb/dut/r_addr_fin[9]} -radix decimal} {{/tb/dut/r_addr_fin[8]} -radix decimal} {{/tb/dut/r_addr_fin[7]} -radix decimal} {{/tb/dut/r_addr_fin[6]} -radix decimal} {{/tb/dut/r_addr_fin[5]} -radix decimal} {{/tb/dut/r_addr_fin[4]} -radix decimal} {{/tb/dut/r_addr_fin[3]} -radix decimal} {{/tb/dut/r_addr_fin[2]} -radix decimal} {{/tb/dut/r_addr_fin[1]} -radix decimal} {{/tb/dut/r_addr_fin[0]} -radix decimal}} -subitemconfig {{/tb/dut/r_addr_fin[25]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin[24]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin[23]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin[22]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin[21]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin[20]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin[19]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin[18]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin[17]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin[16]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin[15]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin[14]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin[13]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin[12]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin[11]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin[10]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin[9]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin[8]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin[7]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin[6]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin[5]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin[4]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin[3]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin[2]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin[1]} {-height 16 -radix decimal} {/tb/dut/r_addr_fin[0]} {-height 16 -radix decimal}} /tb/dut/r_addr_fin
add wave -noupdate /tb/dut/r_addr_fout
add wave -noupdate -radix decimal /tb/dut/r_addr_fout_base
add wave -noupdate /tb/dut/r_count_window
add wave -noupdate -radix decimal /tb/dut/r_count_horizontal
add wave -noupdate -radix decimal /tb/dut/r_count_vertical
add wave -noupdate /tb/dut/w_horizontal_end
add wave -noupdate -radix decimal /tb/dut/data_out
add wave -noupdate -radix decimal /tb/dut/data_in
add wave -noupdate /tb/dut/chip_en
add wave -noupdate /tb/dut/wr_en
add wave -noupdate /tb/dut/data_valid_out
add wave -noupdate -radix decimal /tb/dut/address
add wave -noupdate -radix decimal /tb/core/clk
add wave -noupdate -radix decimal /tb/core/reset
add wave -noupdate -radix decimal /tb/core/p_start
add wave -noupdate -radix decimal /tb/core/p_reuse
add wave -noupdate -radix decimal /tb/core/p_end
add wave -noupdate -radix decimal /tb/core/p_fin_en
add wave -noupdate -radix decimal /tb/core/p_fin_valid
add wave -noupdate -radix decimal /tb/core/p_wh_en
add wave -noupdate -radix decimal /tb/core/p_wh_valid
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
add wave -noupdate -radix decimal /tb/core/r_temp
add wave -noupdate -radix decimal /tb/core/r_feat_out
add wave -noupdate -radix decimal /tb/core/w_prod_c
add wave -noupdate -radix decimal /tb/core/w_prod_a
add wave -noupdate /tb/core/r_reuse
add wave -noupdate /tb/core/r_fout_en
add wave -noupdate /tb/core/r_conv_end
add wave -noupdate /tb/core/r_end
add wave -noupdate /tb/core/r_fout_valid
add wave -noupdate /tb/core/w_end
add wave -noupdate /tb/core/w_end_conv
add wave -noupdate /tb/core/r_count_wh
add wave -noupdate /tb/core/r_count_fin
add wave -noupdate /tb/core/r_count_fout
add wave -noupdate -radix decimal /tb/core/r_mult_idx
add wave -noupdate /tb/core/product
add wave -noupdate /tb/core/c_index
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {34 ns} 0}
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
WaveRestoreZoom {0 ns} {224 ns}
