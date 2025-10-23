onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/control/clk
add wave -noupdate -radix decimal /tb/w_write_data_in
add wave -noupdate -divider control
add wave -noupdate /tb/control/clk
add wave -noupdate /tb/control/reset
add wave -noupdate /tb/control/p_start
add wave -noupdate /tb/control/p_end
add wave -noupdate /tb/control/p_conv_start
add wave -noupdate /tb/control/p_conv_idle
add wave -noupdate /tb/control/p_conv_end
add wave -noupdate -radix decimal /tb/control/p_input
add wave -noupdate -radix decimal /tb/control/p_weight
add wave -noupdate -radix decimal /tb/control/p_output
add wave -noupdate /tb/control/p_read_en
add wave -noupdate -radix unsigned /tb/control/p_read_addr
add wave -noupdate -radix decimal /tb/control/p_read_data
add wave -noupdate /tb/control/p_read_valid
add wave -noupdate /tb/control/p_write_en
add wave -noupdate -radix unsigned /tb/control/p_write_addr
add wave -noupdate -radix decimal /tb/control/p_write_data
add wave -noupdate /tb/control/current_st_input
add wave -noupdate /tb/control/current_st_output
add wave -noupdate -radix unsigned /tb/control/r_count_wh
add wave -noupdate -radix unsigned /tb/control/r_count_fin
add wave -noupdate -radix unsigned /tb/control/r_count_fout
add wave -noupdate -radix unsigned /tb/control/r_addr_bias
add wave -noupdate -radix unsigned /tb/control/r_addr_wh
add wave -noupdate -radix unsigned /tb/control/r_addr_fin
add wave -noupdate -radix unsigned /tb/control/r_addr_fout
add wave -noupdate -radix unsigned /tb/control/r_window
add wave -noupdate -radix unsigned /tb/control/r_window_in
add wave -noupdate -radix unsigned /tb/control/r_window_out
add wave -noupdate /tb/control/w_end_line_in
add wave -noupdate /tb/control/w_end_fin
add wave -noupdate /tb/control/w_end_fout
add wave -noupdate /tb/control/w_end_line_out
add wave -noupdate /tb/control/w_end_channel_out
add wave -noupdate -radix unsigned /tb/control/w_addr_fin
add wave -noupdate /tb/control/r_read_en
add wave -noupdate /tb/control/r_conv_end
add wave -noupdate -divider channel-sum
add wave -noupdate /tb/dut/clk
add wave -noupdate /tb/dut/reset
add wave -noupdate /tb/dut/p_start
add wave -noupdate /tb/dut/p_end
add wave -noupdate /tb/dut/p_read_en
add wave -noupdate -radix unsigned /tb/dut/p_read_addr
add wave -noupdate -radix decimal /tb/dut/p_read_data
add wave -noupdate /tb/dut/p_read_valid
add wave -noupdate /tb/dut/current_st_read
add wave -noupdate -radix unsigned /tb/dut/r_count_fout
add wave -noupdate -radix unsigned /tb/dut/r_addr_fout
add wave -noupdate -radix unsigned /tb/dut/r_window_out
add wave -noupdate /tb/dut/w_end_line_in
add wave -noupdate /tb/dut/w_end_line_out
add wave -noupdate /tb/dut/w_end_fin
add wave -noupdate /tb/dut/w_end_fout
add wave -noupdate /tb/dut/w_end_channel_out
add wave -noupdate -radix unsigned /tb/dut/w_addr
add wave -noupdate /tb/dut/r_read_en
add wave -noupdate -divider mem-write
add wave -noupdate /tb/memory_write/clk
add wave -noupdate /tb/memory_write/reset
add wave -noupdate /tb/memory_write/chip_en
add wave -noupdate /tb/memory_write/wr_en
add wave -noupdate -radix unsigned /tb/memory_write/address
add wave -noupdate -radix decimal /tb/memory_write/data_in
add wave -noupdate -radix decimal /tb/memory_write/data_out
add wave -noupdate /tb/memory_write/data_valid
add wave -noupdate /tb/memory_write/r_cycles_latency
add wave -noupdate -divider conv
add wave -noupdate /tb/conv/p_start
add wave -noupdate /tb/conv/p_end
add wave -noupdate -radix decimal -childformat {{{/tb/conv/p_input[24]} -radix decimal} {{/tb/conv/p_input[23]} -radix decimal} {{/tb/conv/p_input[22]} -radix decimal} {{/tb/conv/p_input[21]} -radix decimal} {{/tb/conv/p_input[20]} -radix decimal} {{/tb/conv/p_input[19]} -radix decimal} {{/tb/conv/p_input[18]} -radix decimal} {{/tb/conv/p_input[17]} -radix decimal} {{/tb/conv/p_input[16]} -radix decimal} {{/tb/conv/p_input[15]} -radix decimal} {{/tb/conv/p_input[14]} -radix decimal} {{/tb/conv/p_input[13]} -radix decimal} {{/tb/conv/p_input[12]} -radix decimal} {{/tb/conv/p_input[11]} -radix decimal} {{/tb/conv/p_input[10]} -radix decimal} {{/tb/conv/p_input[9]} -radix decimal} {{/tb/conv/p_input[8]} -radix decimal} {{/tb/conv/p_input[7]} -radix decimal} {{/tb/conv/p_input[6]} -radix decimal} {{/tb/conv/p_input[5]} -radix decimal} {{/tb/conv/p_input[4]} -radix decimal} {{/tb/conv/p_input[3]} -radix decimal} {{/tb/conv/p_input[2]} -radix decimal} {{/tb/conv/p_input[1]} -radix decimal} {{/tb/conv/p_input[0]} -radix decimal}} -subitemconfig {{/tb/conv/p_input[24]} {-height 16 -radix decimal} {/tb/conv/p_input[23]} {-height 16 -radix decimal} {/tb/conv/p_input[22]} {-height 16 -radix decimal} {/tb/conv/p_input[21]} {-height 16 -radix decimal} {/tb/conv/p_input[20]} {-height 16 -radix decimal} {/tb/conv/p_input[19]} {-height 16 -radix decimal} {/tb/conv/p_input[18]} {-height 16 -radix decimal} {/tb/conv/p_input[17]} {-height 16 -radix decimal} {/tb/conv/p_input[16]} {-height 16 -radix decimal} {/tb/conv/p_input[15]} {-height 16 -radix decimal} {/tb/conv/p_input[14]} {-height 16 -radix decimal} {/tb/conv/p_input[13]} {-height 16 -radix decimal} {/tb/conv/p_input[12]} {-height 16 -radix decimal} {/tb/conv/p_input[11]} {-height 16 -radix decimal} {/tb/conv/p_input[10]} {-height 16 -radix decimal} {/tb/conv/p_input[9]} {-height 16 -radix decimal} {/tb/conv/p_input[8]} {-height 16 -radix decimal} {/tb/conv/p_input[7]} {-height 16 -radix decimal} {/tb/conv/p_input[6]} {-height 16 -radix decimal} {/tb/conv/p_input[5]} {-height 16 -radix decimal} {/tb/conv/p_input[4]} {-height 16 -radix decimal} {/tb/conv/p_input[3]} {-height 16 -radix decimal} {/tb/conv/p_input[2]} {-height 16 -radix decimal} {/tb/conv/p_input[1]} {-height 16 -radix decimal} {/tb/conv/p_input[0]} {-height 16 -radix decimal}} /tb/conv/p_input
add wave -noupdate -radix decimal /tb/conv/p_weight
add wave -noupdate -radix decimal -childformat {{{/tb/conv/p_output[8]} -radix decimal} {{/tb/conv/p_output[7]} -radix decimal} {{/tb/conv/p_output[6]} -radix decimal} {{/tb/conv/p_output[5]} -radix decimal} {{/tb/conv/p_output[4]} -radix decimal} {{/tb/conv/p_output[3]} -radix decimal} {{/tb/conv/p_output[2]} -radix decimal} {{/tb/conv/p_output[1]} -radix decimal} {{/tb/conv/p_output[0]} -radix decimal}} -subitemconfig {{/tb/conv/p_output[8]} {-height 16 -radix decimal} {/tb/conv/p_output[7]} {-height 16 -radix decimal} {/tb/conv/p_output[6]} {-height 16 -radix decimal} {/tb/conv/p_output[5]} {-height 16 -radix decimal} {/tb/conv/p_output[4]} {-height 16 -radix decimal} {/tb/conv/p_output[3]} {-height 16 -radix decimal} {/tb/conv/p_output[2]} {-height 16 -radix decimal} {/tb/conv/p_output[1]} {-height 16 -radix decimal} {/tb/conv/p_output[0]} {-height 16 -radix decimal}} /tb/conv/p_output
add wave -noupdate -radix decimal /tb/conv/next_state
add wave -noupdate -radix decimal -childformat {{{/tb/conv/r_feat[35]} -radix decimal} {{/tb/conv/r_feat[34]} -radix decimal} {{/tb/conv/r_feat[33]} -radix decimal} {{/tb/conv/r_feat[32]} -radix decimal} {{/tb/conv/r_feat[31]} -radix decimal} {{/tb/conv/r_feat[30]} -radix decimal} {{/tb/conv/r_feat[29]} -radix decimal} {{/tb/conv/r_feat[28]} -radix decimal} {{/tb/conv/r_feat[27]} -radix decimal} {{/tb/conv/r_feat[26]} -radix decimal} {{/tb/conv/r_feat[25]} -radix decimal} {{/tb/conv/r_feat[24]} -radix decimal} {{/tb/conv/r_feat[23]} -radix decimal} {{/tb/conv/r_feat[22]} -radix decimal} {{/tb/conv/r_feat[21]} -radix decimal} {{/tb/conv/r_feat[20]} -radix decimal} {{/tb/conv/r_feat[19]} -radix decimal} {{/tb/conv/r_feat[18]} -radix decimal} {{/tb/conv/r_feat[17]} -radix decimal} {{/tb/conv/r_feat[16]} -radix decimal} {{/tb/conv/r_feat[15]} -radix decimal} {{/tb/conv/r_feat[14]} -radix decimal} {{/tb/conv/r_feat[13]} -radix decimal} {{/tb/conv/r_feat[12]} -radix decimal} {{/tb/conv/r_feat[11]} -radix decimal} {{/tb/conv/r_feat[10]} -radix decimal} {{/tb/conv/r_feat[9]} -radix decimal} {{/tb/conv/r_feat[8]} -radix decimal} {{/tb/conv/r_feat[7]} -radix decimal} {{/tb/conv/r_feat[6]} -radix decimal} {{/tb/conv/r_feat[5]} -radix decimal} {{/tb/conv/r_feat[4]} -radix decimal} {{/tb/conv/r_feat[3]} -radix decimal} {{/tb/conv/r_feat[2]} -radix decimal} {{/tb/conv/r_feat[1]} -radix decimal} {{/tb/conv/r_feat[0]} -radix decimal}} -expand -subitemconfig {{/tb/conv/r_feat[35]} {-height 16 -radix decimal} {/tb/conv/r_feat[34]} {-height 16 -radix decimal} {/tb/conv/r_feat[33]} {-height 16 -radix decimal} {/tb/conv/r_feat[32]} {-height 16 -radix decimal} {/tb/conv/r_feat[31]} {-height 16 -radix decimal} {/tb/conv/r_feat[30]} {-height 16 -radix decimal} {/tb/conv/r_feat[29]} {-height 16 -radix decimal} {/tb/conv/r_feat[28]} {-height 16 -radix decimal} {/tb/conv/r_feat[27]} {-height 16 -radix decimal} {/tb/conv/r_feat[26]} {-height 16 -radix decimal} {/tb/conv/r_feat[25]} {-height 16 -radix decimal} {/tb/conv/r_feat[24]} {-height 16 -radix decimal} {/tb/conv/r_feat[23]} {-height 16 -radix decimal} {/tb/conv/r_feat[22]} {-height 16 -radix decimal} {/tb/conv/r_feat[21]} {-height 16 -radix decimal} {/tb/conv/r_feat[20]} {-height 16 -radix decimal} {/tb/conv/r_feat[19]} {-height 16 -radix decimal} {/tb/conv/r_feat[18]} {-height 16 -radix decimal} {/tb/conv/r_feat[17]} {-height 16 -radix decimal} {/tb/conv/r_feat[16]} {-height 16 -radix decimal} {/tb/conv/r_feat[15]} {-height 16 -radix decimal} {/tb/conv/r_feat[14]} {-height 16 -radix decimal} {/tb/conv/r_feat[13]} {-height 16 -radix decimal} {/tb/conv/r_feat[12]} {-height 16 -radix decimal} {/tb/conv/r_feat[11]} {-height 16 -radix decimal} {/tb/conv/r_feat[10]} {-height 16 -radix decimal} {/tb/conv/r_feat[9]} {-height 16 -radix decimal} {/tb/conv/r_feat[8]} {-height 16 -radix decimal} {/tb/conv/r_feat[7]} {-height 16 -radix decimal} {/tb/conv/r_feat[6]} {-height 16 -radix decimal} {/tb/conv/r_feat[5]} {-height 16 -radix decimal} {/tb/conv/r_feat[4]} {-height 16 -radix decimal} {/tb/conv/r_feat[3]} {-height 16 -radix decimal} {/tb/conv/r_feat[2]} {-height 16 -radix decimal} {/tb/conv/r_feat[1]} {-height 16 -radix decimal} {/tb/conv/r_feat[0]} {-height 16 -radix decimal}} /tb/conv/r_feat
add wave -noupdate -radix decimal /tb/conv/w_prod_c
add wave -noupdate -radix decimal /tb/conv/w_prod_a
add wave -noupdate /tb/conv/r_end
add wave -noupdate -radix decimal /tb/conv/r_idx_in
add wave -noupdate -radix decimal /tb/conv/r_idx_out
add wave -noupdate -radix decimal /tb/conv/product
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 2} {1756500 ps} 1} {{Cursor 3} {1748492 ps} 0}
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
configure wave -gridperiod 1000
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {1723169 ps} {1789491 ps}
