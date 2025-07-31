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
add wave -noupdate -radix decimal /tb/dut/r_addr_fin_base
add wave -noupdate -radix decimal /tb/dut/r_addr_fin
add wave -noupdate /tb/dut/r_addr_fout
add wave -noupdate -radix decimal /tb/dut/r_addr_fout_idx
add wave -noupdate -radix decimal /tb/dut/r_addr_fout_base
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
add wave -noupdate /tb/core/p_wh_en
add wave -noupdate /tb/core/p_fin_en
add wave -noupdate /tb/core/p_wh_valid
add wave -noupdate /tb/core/p_fin_valid
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
add wave -noupdate -radix decimal -childformat {{{/tb/core/r_weight[35]} -radix decimal} {{/tb/core/r_weight[34]} -radix decimal} {{/tb/core/r_weight[33]} -radix decimal} {{/tb/core/r_weight[32]} -radix decimal} {{/tb/core/r_weight[31]} -radix decimal} {{/tb/core/r_weight[30]} -radix decimal} {{/tb/core/r_weight[29]} -radix decimal} {{/tb/core/r_weight[28]} -radix decimal} {{/tb/core/r_weight[27]} -radix decimal} {{/tb/core/r_weight[26]} -radix decimal} {{/tb/core/r_weight[25]} -radix decimal} {{/tb/core/r_weight[24]} -radix decimal} {{/tb/core/r_weight[23]} -radix decimal} {{/tb/core/r_weight[22]} -radix decimal} {{/tb/core/r_weight[21]} -radix decimal} {{/tb/core/r_weight[20]} -radix decimal} {{/tb/core/r_weight[19]} -radix decimal} {{/tb/core/r_weight[18]} -radix decimal} {{/tb/core/r_weight[17]} -radix decimal} {{/tb/core/r_weight[16]} -radix decimal} {{/tb/core/r_weight[15]} -radix decimal} {{/tb/core/r_weight[14]} -radix decimal} {{/tb/core/r_weight[13]} -radix decimal} {{/tb/core/r_weight[12]} -radix decimal} {{/tb/core/r_weight[11]} -radix decimal} {{/tb/core/r_weight[10]} -radix decimal} {{/tb/core/r_weight[9]} -radix decimal} {{/tb/core/r_weight[8]} -radix decimal} {{/tb/core/r_weight[7]} -radix decimal} {{/tb/core/r_weight[6]} -radix decimal} {{/tb/core/r_weight[5]} -radix decimal} {{/tb/core/r_weight[4]} -radix decimal} {{/tb/core/r_weight[3]} -radix decimal} {{/tb/core/r_weight[2]} -radix decimal} {{/tb/core/r_weight[1]} -radix decimal} {{/tb/core/r_weight[0]} -radix decimal}} -subitemconfig {{/tb/core/r_weight[35]} {-height 16 -radix decimal} {/tb/core/r_weight[34]} {-height 16 -radix decimal} {/tb/core/r_weight[33]} {-height 16 -radix decimal} {/tb/core/r_weight[32]} {-height 16 -radix decimal} {/tb/core/r_weight[31]} {-height 16 -radix decimal} {/tb/core/r_weight[30]} {-height 16 -radix decimal} {/tb/core/r_weight[29]} {-height 16 -radix decimal} {/tb/core/r_weight[28]} {-height 16 -radix decimal} {/tb/core/r_weight[27]} {-height 16 -radix decimal} {/tb/core/r_weight[26]} {-height 16 -radix decimal} {/tb/core/r_weight[25]} {-height 16 -radix decimal} {/tb/core/r_weight[24]} {-height 16 -radix decimal} {/tb/core/r_weight[23]} {-height 16 -radix decimal} {/tb/core/r_weight[22]} {-height 16 -radix decimal} {/tb/core/r_weight[21]} {-height 16 -radix decimal} {/tb/core/r_weight[20]} {-height 16 -radix decimal} {/tb/core/r_weight[19]} {-height 16 -radix decimal} {/tb/core/r_weight[18]} {-height 16 -radix decimal} {/tb/core/r_weight[17]} {-height 16 -radix decimal} {/tb/core/r_weight[16]} {-height 16 -radix decimal} {/tb/core/r_weight[15]} {-height 16 -radix decimal} {/tb/core/r_weight[14]} {-height 16 -radix decimal} {/tb/core/r_weight[13]} {-height 16 -radix decimal} {/tb/core/r_weight[12]} {-height 16 -radix decimal} {/tb/core/r_weight[11]} {-height 16 -radix decimal} {/tb/core/r_weight[10]} {-height 16 -radix decimal} {/tb/core/r_weight[9]} {-height 16 -radix decimal} {/tb/core/r_weight[8]} {-height 16 -radix decimal} {/tb/core/r_weight[7]} {-height 16 -radix decimal} {/tb/core/r_weight[6]} {-height 16 -radix decimal} {/tb/core/r_weight[5]} {-height 16 -radix decimal} {/tb/core/r_weight[4]} {-height 16 -radix decimal} {/tb/core/r_weight[3]} {-height 16 -radix decimal} {/tb/core/r_weight[2]} {-height 16 -radix decimal} {/tb/core/r_weight[1]} {-height 16 -radix decimal} {/tb/core/r_weight[0]} {-height 16 -radix decimal}} /tb/core/r_weight
add wave -noupdate -radix decimal -childformat {{{/tb/core/r_feat_in[35]} -radix decimal} {{/tb/core/r_feat_in[34]} -radix decimal} {{/tb/core/r_feat_in[33]} -radix decimal} {{/tb/core/r_feat_in[32]} -radix decimal} {{/tb/core/r_feat_in[31]} -radix decimal} {{/tb/core/r_feat_in[30]} -radix decimal} {{/tb/core/r_feat_in[29]} -radix decimal} {{/tb/core/r_feat_in[28]} -radix decimal} {{/tb/core/r_feat_in[27]} -radix decimal} {{/tb/core/r_feat_in[26]} -radix decimal} {{/tb/core/r_feat_in[25]} -radix decimal} {{/tb/core/r_feat_in[24]} -radix decimal} {{/tb/core/r_feat_in[23]} -radix decimal} {{/tb/core/r_feat_in[22]} -radix decimal} {{/tb/core/r_feat_in[21]} -radix decimal} {{/tb/core/r_feat_in[20]} -radix decimal} {{/tb/core/r_feat_in[19]} -radix decimal} {{/tb/core/r_feat_in[18]} -radix decimal} {{/tb/core/r_feat_in[17]} -radix decimal} {{/tb/core/r_feat_in[16]} -radix decimal} {{/tb/core/r_feat_in[15]} -radix decimal} {{/tb/core/r_feat_in[14]} -radix decimal} {{/tb/core/r_feat_in[13]} -radix decimal} {{/tb/core/r_feat_in[12]} -radix decimal} {{/tb/core/r_feat_in[11]} -radix decimal} {{/tb/core/r_feat_in[10]} -radix decimal} {{/tb/core/r_feat_in[9]} -radix decimal} {{/tb/core/r_feat_in[8]} -radix decimal} {{/tb/core/r_feat_in[7]} -radix decimal} {{/tb/core/r_feat_in[6]} -radix decimal} {{/tb/core/r_feat_in[5]} -radix decimal} {{/tb/core/r_feat_in[4]} -radix decimal} {{/tb/core/r_feat_in[3]} -radix decimal} {{/tb/core/r_feat_in[2]} -radix decimal} {{/tb/core/r_feat_in[1]} -radix decimal} {{/tb/core/r_feat_in[0]} -radix decimal}} -subitemconfig {{/tb/core/r_feat_in[35]} {-height 16 -radix decimal} {/tb/core/r_feat_in[34]} {-height 16 -radix decimal} {/tb/core/r_feat_in[33]} {-height 16 -radix decimal} {/tb/core/r_feat_in[32]} {-height 16 -radix decimal} {/tb/core/r_feat_in[31]} {-height 16 -radix decimal} {/tb/core/r_feat_in[30]} {-height 16 -radix decimal} {/tb/core/r_feat_in[29]} {-height 16 -radix decimal} {/tb/core/r_feat_in[28]} {-height 16 -radix decimal} {/tb/core/r_feat_in[27]} {-height 16 -radix decimal} {/tb/core/r_feat_in[26]} {-height 16 -radix decimal} {/tb/core/r_feat_in[25]} {-height 16 -radix decimal} {/tb/core/r_feat_in[24]} {-height 16 -radix decimal} {/tb/core/r_feat_in[23]} {-height 16 -radix decimal} {/tb/core/r_feat_in[22]} {-height 16 -radix decimal} {/tb/core/r_feat_in[21]} {-height 16 -radix decimal} {/tb/core/r_feat_in[20]} {-height 16 -radix decimal} {/tb/core/r_feat_in[19]} {-height 16 -radix decimal} {/tb/core/r_feat_in[18]} {-height 16 -radix decimal} {/tb/core/r_feat_in[17]} {-height 16 -radix decimal} {/tb/core/r_feat_in[16]} {-height 16 -radix decimal} {/tb/core/r_feat_in[15]} {-height 16 -radix decimal} {/tb/core/r_feat_in[14]} {-height 16 -radix decimal} {/tb/core/r_feat_in[13]} {-height 16 -radix decimal} {/tb/core/r_feat_in[12]} {-height 16 -radix decimal} {/tb/core/r_feat_in[11]} {-height 16 -radix decimal} {/tb/core/r_feat_in[10]} {-height 16 -radix decimal} {/tb/core/r_feat_in[9]} {-height 16 -radix decimal} {/tb/core/r_feat_in[8]} {-height 16 -radix decimal} {/tb/core/r_feat_in[7]} {-height 16 -radix decimal} {/tb/core/r_feat_in[6]} {-height 16 -radix decimal} {/tb/core/r_feat_in[5]} {-height 16 -radix decimal} {/tb/core/r_feat_in[4]} {-height 16 -radix decimal} {/tb/core/r_feat_in[3]} {-height 16 -radix decimal} {/tb/core/r_feat_in[2]} {-height 16 -radix decimal} {/tb/core/r_feat_in[1]} {-height 16 -radix decimal} {/tb/core/r_feat_in[0]} {-height 16 -radix decimal}} /tb/core/r_feat_in
add wave -noupdate -radix decimal /tb/core/r_feat_out
add wave -noupdate -radix decimal /tb/core/r_count_wh
add wave -noupdate -radix decimal /tb/core/r_count_fin
add wave -noupdate -radix decimal /tb/core/r_count_fout
add wave -noupdate -radix decimal /tb/core/r_mult_idx
add wave -noupdate /tb/dut/memory/clk
add wave -noupdate /tb/dut/memory/reset
add wave -noupdate /tb/dut/memory/chip_en
add wave -noupdate /tb/dut/memory/wr_en
add wave -noupdate /tb/dut/memory/address
add wave -noupdate /tb/dut/memory/data_in
add wave -noupdate /tb/dut/memory/data_out
add wave -noupdate /tb/dut/memory/data_valid
add wave -noupdate /tb/dut/memory/data
add wave -noupdate /tb/dut/memory/r_cycles_latency
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {771 ns} 0}
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
WaveRestoreZoom {1692 ns} {1806 ns}
