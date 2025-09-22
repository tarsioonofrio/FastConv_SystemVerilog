onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/dut/clk
add wave -noupdate /tb/dut/reset
add wave -noupdate /tb/dut/p_start
add wave -noupdate /tb/dut/p_end
add wave -noupdate /tb/dut/p_conv_start
add wave -noupdate /tb/dut/p_conv_end
add wave -noupdate -radix decimal /tb/dut/p_input
add wave -noupdate -radix decimal -childformat {{{/tb/dut/p_weight[35]} -radix decimal} {{/tb/dut/p_weight[34]} -radix decimal} {{/tb/dut/p_weight[33]} -radix decimal} {{/tb/dut/p_weight[32]} -radix decimal} {{/tb/dut/p_weight[31]} -radix decimal} {{/tb/dut/p_weight[30]} -radix decimal} {{/tb/dut/p_weight[29]} -radix decimal} {{/tb/dut/p_weight[28]} -radix decimal} {{/tb/dut/p_weight[27]} -radix decimal} {{/tb/dut/p_weight[26]} -radix decimal} {{/tb/dut/p_weight[25]} -radix decimal} {{/tb/dut/p_weight[24]} -radix decimal} {{/tb/dut/p_weight[23]} -radix decimal} {{/tb/dut/p_weight[22]} -radix decimal} {{/tb/dut/p_weight[21]} -radix decimal} {{/tb/dut/p_weight[20]} -radix decimal} {{/tb/dut/p_weight[19]} -radix decimal} {{/tb/dut/p_weight[18]} -radix decimal} {{/tb/dut/p_weight[17]} -radix decimal} {{/tb/dut/p_weight[16]} -radix decimal} {{/tb/dut/p_weight[15]} -radix decimal} {{/tb/dut/p_weight[14]} -radix decimal} {{/tb/dut/p_weight[13]} -radix decimal} {{/tb/dut/p_weight[12]} -radix decimal} {{/tb/dut/p_weight[11]} -radix decimal} {{/tb/dut/p_weight[10]} -radix decimal} {{/tb/dut/p_weight[9]} -radix decimal} {{/tb/dut/p_weight[8]} -radix decimal} {{/tb/dut/p_weight[7]} -radix decimal} {{/tb/dut/p_weight[6]} -radix decimal} {{/tb/dut/p_weight[5]} -radix decimal} {{/tb/dut/p_weight[4]} -radix decimal} {{/tb/dut/p_weight[3]} -radix decimal} {{/tb/dut/p_weight[2]} -radix decimal} {{/tb/dut/p_weight[1]} -radix decimal} {{/tb/dut/p_weight[0]} -radix decimal}} -subitemconfig {{/tb/dut/p_weight[35]} {-height 16 -radix decimal} {/tb/dut/p_weight[34]} {-height 16 -radix decimal} {/tb/dut/p_weight[33]} {-height 16 -radix decimal} {/tb/dut/p_weight[32]} {-height 16 -radix decimal} {/tb/dut/p_weight[31]} {-height 16 -radix decimal} {/tb/dut/p_weight[30]} {-height 16 -radix decimal} {/tb/dut/p_weight[29]} {-height 16 -radix decimal} {/tb/dut/p_weight[28]} {-height 16 -radix decimal} {/tb/dut/p_weight[27]} {-height 16 -radix decimal} {/tb/dut/p_weight[26]} {-height 16 -radix decimal} {/tb/dut/p_weight[25]} {-height 16 -radix decimal} {/tb/dut/p_weight[24]} {-height 16 -radix decimal} {/tb/dut/p_weight[23]} {-height 16 -radix decimal} {/tb/dut/p_weight[22]} {-height 16 -radix decimal} {/tb/dut/p_weight[21]} {-height 16 -radix decimal} {/tb/dut/p_weight[20]} {-height 16 -radix decimal} {/tb/dut/p_weight[19]} {-height 16 -radix decimal} {/tb/dut/p_weight[18]} {-height 16 -radix decimal} {/tb/dut/p_weight[17]} {-height 16 -radix decimal} {/tb/dut/p_weight[16]} {-height 16 -radix decimal} {/tb/dut/p_weight[15]} {-height 16 -radix decimal} {/tb/dut/p_weight[14]} {-height 16 -radix decimal} {/tb/dut/p_weight[13]} {-height 16 -radix decimal} {/tb/dut/p_weight[12]} {-height 16 -radix decimal} {/tb/dut/p_weight[11]} {-height 16 -radix decimal} {/tb/dut/p_weight[10]} {-height 16 -radix decimal} {/tb/dut/p_weight[9]} {-height 16 -radix decimal} {/tb/dut/p_weight[8]} {-height 16 -radix decimal} {/tb/dut/p_weight[7]} {-height 16 -radix decimal} {/tb/dut/p_weight[6]} {-height 16 -radix decimal} {/tb/dut/p_weight[5]} {-height 16 -radix decimal} {/tb/dut/p_weight[4]} {-height 16 -radix decimal} {/tb/dut/p_weight[3]} {-height 16 -radix decimal} {/tb/dut/p_weight[2]} {-height 16 -radix decimal} {/tb/dut/p_weight[1]} {-height 16 -radix decimal} {/tb/dut/p_weight[0]} {-height 16 -radix decimal}} /tb/dut/p_weight
add wave -noupdate -radix decimal -childformat {{{/tb/dut/p_output[8]} -radix decimal} {{/tb/dut/p_output[7]} -radix decimal} {{/tb/dut/p_output[6]} -radix decimal} {{/tb/dut/p_output[5]} -radix decimal} {{/tb/dut/p_output[4]} -radix decimal} {{/tb/dut/p_output[3]} -radix decimal} {{/tb/dut/p_output[2]} -radix decimal} {{/tb/dut/p_output[1]} -radix decimal} {{/tb/dut/p_output[0]} -radix decimal}} -expand -subitemconfig {{/tb/dut/p_output[8]} {-radix decimal} {/tb/dut/p_output[7]} {-radix decimal} {/tb/dut/p_output[6]} {-radix decimal} {/tb/dut/p_output[5]} {-radix decimal} {/tb/dut/p_output[4]} {-radix decimal} {/tb/dut/p_output[3]} {-radix decimal} {/tb/dut/p_output[2]} {-radix decimal} {/tb/dut/p_output[1]} {-radix decimal} {/tb/dut/p_output[0]} {-radix decimal}} /tb/dut/p_output
add wave -noupdate /tb/dut/current_st_input
add wave -noupdate /tb/dut/next_st_input
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
add wave -noupdate /tb/dut/r_fout_en
add wave -noupdate -radix unsigned /tb/dut/r_count_wh
add wave -noupdate -radix unsigned /tb/dut/r_count_fin
add wave -noupdate -radix unsigned /tb/dut/r_count_fout
add wave -noupdate -radix decimal /tb/dut/r_addr_bias
add wave -noupdate -radix decimal /tb/dut/r_addr_wh
add wave -noupdate -radix decimal /tb/dut/r_addr_fin_base
add wave -noupdate -radix decimal /tb/dut/r_addr_fin
add wave -noupdate -radix decimal /tb/dut/r_addr_fout_base
add wave -noupdate -radix decimal /tb/dut/r_addr_fout
add wave -noupdate -radix decimal /tb/dut/r_count_window
add wave -noupdate -radix decimal /tb/dut/r_count_horizontal
add wave -noupdate -radix decimal /tb/dut/w_mem_rd_out
add wave -noupdate -radix decimal /tb/dut/w_mem_rd_in
add wave -noupdate /tb/dut/w_mem_rd_chip
add wave -noupdate /tb/dut/w_mem_rd_wr
add wave -noupdate /tb/dut/w_mem_rd_valid
add wave -noupdate -radix decimal /tb/dut/w_mem_rd_addr
add wave -noupdate -radix decimal /tb/dut/w_mem_wr_out
add wave -noupdate -radix decimal /tb/dut/w_mem_wr_in
add wave -noupdate /tb/dut/w_mem_wr_chip
add wave -noupdate /tb/dut/w_mem_wr_wr
add wave -noupdate /tb/dut/w_mem_wr_valid
add wave -noupdate -radix decimal /tb/dut/w_mem_wr_addr
add wave -noupdate /tb/dut/w_end
add wave -noupdate /tb/dut/w_horizontal_end
add wave -noupdate /tb/dut/w_end_wh
add wave -noupdate /tb/dut/w_end_fin
add wave -noupdate /tb/dut/w_end_fout
add wave -noupdate /tb/dut/w_conv_idle
add wave -noupdate /tb/dut/w_conv_end
add wave -noupdate /tb/dut/w_output_idle
add wave -noupdate -radix decimal /tb/dut/r_feat_in
add wave -noupdate -radix decimal /tb/dut/r_weight
add wave -noupdate -radix decimal /tb/dut/r_conv
add wave -noupdate -radix decimal -childformat {{{/tb/dut/r_feat_out[8]} -radix decimal} {{/tb/dut/r_feat_out[7]} -radix decimal} {{/tb/dut/r_feat_out[6]} -radix decimal} {{/tb/dut/r_feat_out[5]} -radix decimal} {{/tb/dut/r_feat_out[4]} -radix decimal} {{/tb/dut/r_feat_out[3]} -radix decimal} {{/tb/dut/r_feat_out[2]} -radix decimal} {{/tb/dut/r_feat_out[1]} -radix decimal} {{/tb/dut/r_feat_out[0]} -radix decimal}} -expand -subitemconfig {{/tb/dut/r_feat_out[8]} {-radix decimal} {/tb/dut/r_feat_out[7]} {-radix decimal} {/tb/dut/r_feat_out[6]} {-radix decimal} {/tb/dut/r_feat_out[5]} {-radix decimal} {/tb/dut/r_feat_out[4]} {-radix decimal} {/tb/dut/r_feat_out[3]} {-radix decimal} {/tb/dut/r_feat_out[2]} {-radix decimal} {/tb/dut/r_feat_out[1]} {-radix decimal} {/tb/dut/r_feat_out[0]} {-radix decimal}} /tb/dut/r_feat_out
add wave -noupdate /tb/conv/p_start
add wave -noupdate /tb/conv/p_end
add wave -noupdate -radix decimal /tb/conv/p_input
add wave -noupdate -radix decimal /tb/conv/p_weight
add wave -noupdate -radix decimal -childformat {{{/tb/conv/p_output[8]} -radix decimal} {{/tb/conv/p_output[7]} -radix decimal} {{/tb/conv/p_output[6]} -radix decimal} {{/tb/conv/p_output[5]} -radix decimal} {{/tb/conv/p_output[4]} -radix decimal} {{/tb/conv/p_output[3]} -radix decimal} {{/tb/conv/p_output[2]} -radix decimal} {{/tb/conv/p_output[1]} -radix decimal} {{/tb/conv/p_output[0]} -radix decimal}} -expand -subitemconfig {{/tb/conv/p_output[8]} {-height 16 -radix decimal} {/tb/conv/p_output[7]} {-height 16 -radix decimal} {/tb/conv/p_output[6]} {-height 16 -radix decimal} {/tb/conv/p_output[5]} {-height 16 -radix decimal} {/tb/conv/p_output[4]} {-height 16 -radix decimal} {/tb/conv/p_output[3]} {-height 16 -radix decimal} {/tb/conv/p_output[2]} {-height 16 -radix decimal} {/tb/conv/p_output[1]} {-height 16 -radix decimal} {/tb/conv/p_output[0]} {-height 16 -radix decimal}} /tb/conv/p_output
add wave -noupdate -radix decimal /tb/conv/current_state
add wave -noupdate -radix decimal /tb/conv/next_state
add wave -noupdate -radix decimal /tb/conv/r_feat
add wave -noupdate -radix decimal /tb/conv/w_prod_c
add wave -noupdate -radix decimal /tb/conv/w_prod_a
add wave -noupdate /tb/conv/r_end
add wave -noupdate /tb/conv/w_end
add wave -noupdate -radix decimal /tb/conv/r_idx_in
add wave -noupdate -radix decimal /tb/conv/r_idx_out
add wave -noupdate -radix decimal /tb/conv/product
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {43955 ns} 1 Red default} {{Cursor 2} {775 ns} 0}
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
WaveRestoreZoom {666 ns} {890 ns}
