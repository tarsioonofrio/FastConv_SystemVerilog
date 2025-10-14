onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/dut/clk
add wave -noupdate /tb/dut/reset
add wave -noupdate /tb/dut/p_start
add wave -noupdate /tb/dut/p_end
add wave -noupdate -expand -group memory /tb/memory_read/clk
add wave -noupdate -expand -group memory /tb/memory_read/reset
add wave -noupdate -expand -group memory /tb/memory_read/chip_en
add wave -noupdate -expand -group memory /tb/memory_read/wr_en
add wave -noupdate -expand -group memory -radix unsigned /tb/memory_read/address
add wave -noupdate -expand -group memory /tb/memory_read/data_in
add wave -noupdate -expand -group memory -radix decimal /tb/memory_read/data_out
add wave -noupdate -expand -group memory /tb/memory_read/data_valid
add wave -noupdate -expand -group memory /tb/memory_read/r_cycles_latency
add wave -noupdate -radix decimal -childformat {{{/tb/dut/p_input[24]} -radix decimal} {{/tb/dut/p_input[23]} -radix decimal} {{/tb/dut/p_input[22]} -radix decimal} {{/tb/dut/p_input[21]} -radix decimal} {{/tb/dut/p_input[20]} -radix decimal} {{/tb/dut/p_input[19]} -radix decimal} {{/tb/dut/p_input[18]} -radix decimal} {{/tb/dut/p_input[17]} -radix decimal} {{/tb/dut/p_input[16]} -radix decimal} {{/tb/dut/p_input[15]} -radix decimal} {{/tb/dut/p_input[14]} -radix decimal} {{/tb/dut/p_input[13]} -radix decimal} {{/tb/dut/p_input[12]} -radix decimal} {{/tb/dut/p_input[11]} -radix decimal} {{/tb/dut/p_input[10]} -radix decimal} {{/tb/dut/p_input[9]} -radix decimal} {{/tb/dut/p_input[8]} -radix decimal} {{/tb/dut/p_input[7]} -radix decimal} {{/tb/dut/p_input[6]} -radix decimal} {{/tb/dut/p_input[5]} -radix decimal} {{/tb/dut/p_input[4]} -radix decimal} {{/tb/dut/p_input[3]} -radix decimal} {{/tb/dut/p_input[2]} -radix decimal} {{/tb/dut/p_input[1]} -radix decimal} {{/tb/dut/p_input[0]} -radix decimal}} -subitemconfig {{/tb/dut/p_input[24]} {-height 16 -radix decimal} {/tb/dut/p_input[23]} {-height 16 -radix decimal} {/tb/dut/p_input[22]} {-height 16 -radix decimal} {/tb/dut/p_input[21]} {-height 16 -radix decimal} {/tb/dut/p_input[20]} {-height 16 -radix decimal} {/tb/dut/p_input[19]} {-height 16 -radix decimal} {/tb/dut/p_input[18]} {-height 16 -radix decimal} {/tb/dut/p_input[17]} {-height 16 -radix decimal} {/tb/dut/p_input[16]} {-height 16 -radix decimal} {/tb/dut/p_input[15]} {-height 16 -radix decimal} {/tb/dut/p_input[14]} {-height 16 -radix decimal} {/tb/dut/p_input[13]} {-height 16 -radix decimal} {/tb/dut/p_input[12]} {-height 16 -radix decimal} {/tb/dut/p_input[11]} {-height 16 -radix decimal} {/tb/dut/p_input[10]} {-height 16 -radix decimal} {/tb/dut/p_input[9]} {-height 16 -radix decimal} {/tb/dut/p_input[8]} {-height 16 -radix decimal} {/tb/dut/p_input[7]} {-height 16 -radix decimal} {/tb/dut/p_input[6]} {-height 16 -radix decimal} {/tb/dut/p_input[5]} {-height 16 -radix decimal} {/tb/dut/p_input[4]} {-height 16 -radix decimal} {/tb/dut/p_input[3]} {-height 16 -radix decimal} {/tb/dut/p_input[2]} {-height 16 -radix decimal} {/tb/dut/p_input[1]} {-height 16 -radix decimal} {/tb/dut/p_input[0]} {-height 16 -radix decimal}} /tb/dut/p_input
add wave -noupdate -radix unsigned -childformat {{{/tb/dut/p_weight[35]} -radix decimal} {{/tb/dut/p_weight[34]} -radix decimal} {{/tb/dut/p_weight[33]} -radix decimal} {{/tb/dut/p_weight[32]} -radix decimal} {{/tb/dut/p_weight[31]} -radix decimal} {{/tb/dut/p_weight[30]} -radix decimal} {{/tb/dut/p_weight[29]} -radix decimal} {{/tb/dut/p_weight[28]} -radix decimal} {{/tb/dut/p_weight[27]} -radix decimal} {{/tb/dut/p_weight[26]} -radix decimal} {{/tb/dut/p_weight[25]} -radix decimal} {{/tb/dut/p_weight[24]} -radix decimal} {{/tb/dut/p_weight[23]} -radix decimal} {{/tb/dut/p_weight[22]} -radix decimal} {{/tb/dut/p_weight[21]} -radix decimal} {{/tb/dut/p_weight[20]} -radix decimal} {{/tb/dut/p_weight[19]} -radix decimal} {{/tb/dut/p_weight[18]} -radix decimal} {{/tb/dut/p_weight[17]} -radix decimal} {{/tb/dut/p_weight[16]} -radix decimal} {{/tb/dut/p_weight[15]} -radix decimal} {{/tb/dut/p_weight[14]} -radix decimal} {{/tb/dut/p_weight[13]} -radix decimal} {{/tb/dut/p_weight[12]} -radix decimal} {{/tb/dut/p_weight[11]} -radix decimal} {{/tb/dut/p_weight[10]} -radix decimal} {{/tb/dut/p_weight[9]} -radix decimal} {{/tb/dut/p_weight[8]} -radix decimal} {{/tb/dut/p_weight[7]} -radix decimal} {{/tb/dut/p_weight[6]} -radix decimal} {{/tb/dut/p_weight[5]} -radix decimal} {{/tb/dut/p_weight[4]} -radix decimal} {{/tb/dut/p_weight[3]} -radix decimal} {{/tb/dut/p_weight[2]} -radix decimal} {{/tb/dut/p_weight[1]} -radix decimal} {{/tb/dut/p_weight[0]} -radix decimal}} -subitemconfig {{/tb/dut/p_weight[35]} {-height 16 -radix decimal} {/tb/dut/p_weight[34]} {-height 16 -radix decimal} {/tb/dut/p_weight[33]} {-height 16 -radix decimal} {/tb/dut/p_weight[32]} {-height 16 -radix decimal} {/tb/dut/p_weight[31]} {-height 16 -radix decimal} {/tb/dut/p_weight[30]} {-height 16 -radix decimal} {/tb/dut/p_weight[29]} {-height 16 -radix decimal} {/tb/dut/p_weight[28]} {-height 16 -radix decimal} {/tb/dut/p_weight[27]} {-height 16 -radix decimal} {/tb/dut/p_weight[26]} {-height 16 -radix decimal} {/tb/dut/p_weight[25]} {-height 16 -radix decimal} {/tb/dut/p_weight[24]} {-height 16 -radix decimal} {/tb/dut/p_weight[23]} {-height 16 -radix decimal} {/tb/dut/p_weight[22]} {-height 16 -radix decimal} {/tb/dut/p_weight[21]} {-height 16 -radix decimal} {/tb/dut/p_weight[20]} {-height 16 -radix decimal} {/tb/dut/p_weight[19]} {-height 16 -radix decimal} {/tb/dut/p_weight[18]} {-height 16 -radix decimal} {/tb/dut/p_weight[17]} {-height 16 -radix decimal} {/tb/dut/p_weight[16]} {-height 16 -radix decimal} {/tb/dut/p_weight[15]} {-height 16 -radix decimal} {/tb/dut/p_weight[14]} {-height 16 -radix decimal} {/tb/dut/p_weight[13]} {-height 16 -radix decimal} {/tb/dut/p_weight[12]} {-height 16 -radix decimal} {/tb/dut/p_weight[11]} {-height 16 -radix decimal} {/tb/dut/p_weight[10]} {-height 16 -radix decimal} {/tb/dut/p_weight[9]} {-height 16 -radix decimal} {/tb/dut/p_weight[8]} {-height 16 -radix decimal} {/tb/dut/p_weight[7]} {-height 16 -radix decimal} {/tb/dut/p_weight[6]} {-height 16 -radix decimal} {/tb/dut/p_weight[5]} {-height 16 -radix decimal} {/tb/dut/p_weight[4]} {-height 16 -radix decimal} {/tb/dut/p_weight[3]} {-height 16 -radix decimal} {/tb/dut/p_weight[2]} {-height 16 -radix decimal} {/tb/dut/p_weight[1]} {-height 16 -radix decimal} {/tb/dut/p_weight[0]} {-height 16 -radix decimal}} /tb/dut/p_weight
add wave -noupdate -radix decimal /tb/dut/p_output
add wave -noupdate -radix unsigned /tb/dut/p_write_addr
add wave -noupdate /tb/dut/p_read_en
add wave -noupdate /tb/dut/p_read_valid
add wave -noupdate -radix unsigned /tb/dut/p_read_data
add wave -noupdate -radix unsigned -childformat {{{/tb/dut/p_read_addr[15]} -radix unsigned} {{/tb/dut/p_read_addr[14]} -radix unsigned} {{/tb/dut/p_read_addr[13]} -radix unsigned} {{/tb/dut/p_read_addr[12]} -radix unsigned} {{/tb/dut/p_read_addr[11]} -radix unsigned} {{/tb/dut/p_read_addr[10]} -radix unsigned} {{/tb/dut/p_read_addr[9]} -radix unsigned} {{/tb/dut/p_read_addr[8]} -radix unsigned} {{/tb/dut/p_read_addr[7]} -radix unsigned} {{/tb/dut/p_read_addr[6]} -radix unsigned} {{/tb/dut/p_read_addr[5]} -radix unsigned} {{/tb/dut/p_read_addr[4]} -radix unsigned} {{/tb/dut/p_read_addr[3]} -radix unsigned} {{/tb/dut/p_read_addr[2]} -radix unsigned} {{/tb/dut/p_read_addr[1]} -radix unsigned} {{/tb/dut/p_read_addr[0]} -radix unsigned}} -subitemconfig {{/tb/dut/p_read_addr[15]} {-height 16 -radix unsigned} {/tb/dut/p_read_addr[14]} {-height 16 -radix unsigned} {/tb/dut/p_read_addr[13]} {-height 16 -radix unsigned} {/tb/dut/p_read_addr[12]} {-height 16 -radix unsigned} {/tb/dut/p_read_addr[11]} {-height 16 -radix unsigned} {/tb/dut/p_read_addr[10]} {-height 16 -radix unsigned} {/tb/dut/p_read_addr[9]} {-height 16 -radix unsigned} {/tb/dut/p_read_addr[8]} {-height 16 -radix unsigned} {/tb/dut/p_read_addr[7]} {-height 16 -radix unsigned} {/tb/dut/p_read_addr[6]} {-height 16 -radix unsigned} {/tb/dut/p_read_addr[5]} {-height 16 -radix unsigned} {/tb/dut/p_read_addr[4]} {-height 16 -radix unsigned} {/tb/dut/p_read_addr[3]} {-height 16 -radix unsigned} {/tb/dut/p_read_addr[2]} {-height 16 -radix unsigned} {/tb/dut/p_read_addr[1]} {-height 16 -radix unsigned} {/tb/dut/p_read_addr[0]} {-height 16 -radix unsigned}} /tb/dut/p_read_addr
add wave -noupdate /tb/dut/p_write_en
add wave -noupdate -radix unsigned /tb/dut/w_addr_fin
add wave -noupdate -radix unsigned /tb/dut/r_addr_fin
add wave -noupdate -radix unsigned /tb/dut/r_count_fin
add wave -noupdate -radix unsigned /tb/dut/r_addr_wh
add wave -noupdate -radix unsigned /tb/dut/r_count_fin_horizontal
add wave -noupdate -radix unsigned /tb/dut/r_count_fout_horizontal
add wave -noupdate /tb/dut/clk
add wave -noupdate -radix unsigned /tb/dut/w_read_addr
add wave -noupdate -divider {controle de leitura}
add wave -noupdate /tb/dut/w_end_fin_horizontal
add wave -noupdate /tb/dut/w_end_fout_horizontal
add wave -noupdate /tb/dut/w_end_fin
add wave -noupdate /tb/dut/current_st_input
add wave -noupdate -divider convolucao
add wave -noupdate -color Red /tb/dut/p_conv_start
add wave -noupdate -radix decimal /tb/conv/current_state
add wave -noupdate -color Red /tb/dut/p_conv_end
add wave -noupdate -divider saida
add wave -noupdate /tb/dut/current_st_output
add wave -noupdate /tb/dut/w_end_fout
add wave -noupdate -radix decimal /tb/dut/p_write_data
add wave -noupdate -radix unsigned /tb/dut/r_count_wh
add wave -noupdate -radix unsigned /tb/dut/r_count_fin
add wave -noupdate -radix unsigned /tb/dut/r_count_fout
add wave -noupdate -radix unsigned /tb/dut/r_addr_bias
add wave -noupdate -radix unsigned /tb/dut/r_addr_wh
add wave -noupdate -radix unsigned /tb/dut/r_addr_fin
add wave -noupdate -radix unsigned /tb/dut/r_addr_fout
add wave -noupdate -radix unsigned /tb/dut/r_count_window
add wave -noupdate -radix decimal -childformat {{{/tb/dut/r_feat_in[24]} -radix decimal} {{/tb/dut/r_feat_in[23]} -radix decimal} {{/tb/dut/r_feat_in[22]} -radix decimal} {{/tb/dut/r_feat_in[21]} -radix decimal} {{/tb/dut/r_feat_in[20]} -radix decimal} {{/tb/dut/r_feat_in[19]} -radix decimal} {{/tb/dut/r_feat_in[18]} -radix decimal} {{/tb/dut/r_feat_in[17]} -radix decimal} {{/tb/dut/r_feat_in[16]} -radix decimal} {{/tb/dut/r_feat_in[15]} -radix decimal} {{/tb/dut/r_feat_in[14]} -radix decimal} {{/tb/dut/r_feat_in[13]} -radix decimal} {{/tb/dut/r_feat_in[12]} -radix decimal} {{/tb/dut/r_feat_in[11]} -radix decimal} {{/tb/dut/r_feat_in[10]} -radix decimal} {{/tb/dut/r_feat_in[9]} -radix decimal} {{/tb/dut/r_feat_in[8]} -radix decimal} {{/tb/dut/r_feat_in[7]} -radix decimal} {{/tb/dut/r_feat_in[6]} -radix decimal} {{/tb/dut/r_feat_in[5]} -radix decimal} {{/tb/dut/r_feat_in[4]} -radix decimal} {{/tb/dut/r_feat_in[3]} -radix decimal} {{/tb/dut/r_feat_in[2]} -radix decimal} {{/tb/dut/r_feat_in[1]} -radix decimal} {{/tb/dut/r_feat_in[0]} -radix decimal}} -subitemconfig {{/tb/dut/r_feat_in[24]} {-height 16 -radix decimal} {/tb/dut/r_feat_in[23]} {-height 16 -radix decimal} {/tb/dut/r_feat_in[22]} {-height 16 -radix decimal} {/tb/dut/r_feat_in[21]} {-height 16 -radix decimal} {/tb/dut/r_feat_in[20]} {-height 16 -radix decimal} {/tb/dut/r_feat_in[19]} {-height 16 -radix decimal} {/tb/dut/r_feat_in[18]} {-height 16 -radix decimal} {/tb/dut/r_feat_in[17]} {-height 16 -radix decimal} {/tb/dut/r_feat_in[16]} {-height 16 -radix decimal} {/tb/dut/r_feat_in[15]} {-height 16 -radix decimal} {/tb/dut/r_feat_in[14]} {-height 16 -radix decimal} {/tb/dut/r_feat_in[13]} {-height 16 -radix decimal} {/tb/dut/r_feat_in[12]} {-height 16 -radix decimal} {/tb/dut/r_feat_in[11]} {-height 16 -radix decimal} {/tb/dut/r_feat_in[10]} {-height 16 -radix decimal} {/tb/dut/r_feat_in[9]} {-height 16 -radix decimal} {/tb/dut/r_feat_in[8]} {-height 16 -radix decimal} {/tb/dut/r_feat_in[7]} {-height 16 -radix decimal} {/tb/dut/r_feat_in[6]} {-height 16 -radix decimal} {/tb/dut/r_feat_in[5]} {-height 16 -radix decimal} {/tb/dut/r_feat_in[4]} {-height 16 -radix decimal} {/tb/dut/r_feat_in[3]} {-height 16 -radix decimal} {/tb/dut/r_feat_in[2]} {-height 16 -radix decimal} {/tb/dut/r_feat_in[1]} {-height 16 -radix decimal} {/tb/dut/r_feat_in[0]} {-height 16 -radix decimal}} /tb/dut/r_feat_in
add wave -noupdate -radix unsigned /tb/dut/r_weight
add wave -noupdate -radix unsigned /tb/dut/r_feat_out
add wave -noupdate /tb/conv/p_start
add wave -noupdate /tb/conv/p_end
add wave -noupdate -radix decimal /tb/conv/p_input
add wave -noupdate -radix decimal /tb/conv/p_weight
add wave -noupdate -radix decimal -childformat {{{/tb/conv/p_output[8]} -radix decimal} {{/tb/conv/p_output[7]} -radix decimal} {{/tb/conv/p_output[6]} -radix decimal} {{/tb/conv/p_output[5]} -radix decimal} {{/tb/conv/p_output[4]} -radix decimal} {{/tb/conv/p_output[3]} -radix decimal} {{/tb/conv/p_output[2]} -radix decimal} {{/tb/conv/p_output[1]} -radix decimal} {{/tb/conv/p_output[0]} -radix decimal}} -expand -subitemconfig {{/tb/conv/p_output[8]} {-height 16 -radix decimal} {/tb/conv/p_output[7]} {-height 16 -radix decimal} {/tb/conv/p_output[6]} {-height 16 -radix decimal} {/tb/conv/p_output[5]} {-height 16 -radix decimal} {/tb/conv/p_output[4]} {-height 16 -radix decimal} {/tb/conv/p_output[3]} {-height 16 -radix decimal} {/tb/conv/p_output[2]} {-height 16 -radix decimal} {/tb/conv/p_output[1]} {-height 16 -radix decimal} {/tb/conv/p_output[0]} {-height 16 -radix decimal}} /tb/conv/p_output
add wave -noupdate -radix decimal /tb/conv/next_state
add wave -noupdate -radix decimal /tb/conv/r_feat
add wave -noupdate -radix decimal /tb/conv/w_prod_c
add wave -noupdate -radix decimal /tb/conv/w_prod_a
add wave -noupdate /tb/conv/r_end
add wave -noupdate -radix decimal /tb/conv/r_idx_in
add wave -noupdate -radix decimal /tb/conv/r_idx_out
add wave -noupdate -radix decimal /tb/conv/product
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 3} {665 ns} 0} {{Cursor 4} {655 ns} 0}
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
WaveRestoreZoom {574 ns} {736 ns}
