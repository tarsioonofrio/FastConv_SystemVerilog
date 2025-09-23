onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/dut/clk
add wave -noupdate /tb/dut/reset
add wave -noupdate /tb/dut/p_start
add wave -noupdate /tb/dut/p_end
add wave -noupdate /tb/dut/p_conv_start
add wave -noupdate /tb/dut/p_conv_end
add wave -noupdate -radix unsigned /tb/dut/p_input
add wave -noupdate -radix unsigned /tb/dut/p_weight
add wave -noupdate -radix unsigned /tb/dut/p_output
add wave -noupdate /tb/dut/p_read_en
add wave -noupdate -radix unsigned /tb/dut/p_read_addr
add wave -noupdate -radix unsigned /tb/dut/p_read_data
add wave -noupdate /tb/dut/p_read_valid
add wave -noupdate /tb/dut/p_write_en
add wave -noupdate -radix unsigned /tb/dut/p_write_addr
add wave -noupdate -radix unsigned /tb/dut/p_write_data
add wave -noupdate /tb/dut/current_st_input
add wave -noupdate /tb/dut/next_st_input
add wave -noupdate /tb/dut/current_st_output
add wave -noupdate /tb/dut/next_st_output
add wave -noupdate /tb/dut/r_wh_en
add wave -noupdate /tb/dut/r_fin_en
add wave -noupdate /tb/dut/r_end_wh
add wave -noupdate /tb/dut/r_end_fin
add wave -noupdate /tb/dut/r_fout_en
add wave -noupdate -radix unsigned /tb/dut/r_count_wh
add wave -noupdate -radix unsigned /tb/dut/r_count_fin
add wave -noupdate -radix unsigned /tb/dut/r_count_fout
add wave -noupdate -radix unsigned /tb/dut/r_addr_bias
add wave -noupdate -radix unsigned /tb/dut/r_addr_wh
add wave -noupdate -radix unsigned /tb/dut/r_addr_fin
add wave -noupdate -radix unsigned /tb/dut/r_addr_fout_base
add wave -noupdate -radix unsigned /tb/dut/r_addr_fout
add wave -noupdate -radix unsigned /tb/dut/r_count_window
add wave -noupdate -radix unsigned /tb/dut/r_count_horizontal
add wave -noupdate /tb/dut/w_end_horizontal
add wave -noupdate /tb/dut/w_end_wh
add wave -noupdate /tb/dut/w_end_fin
add wave -noupdate /tb/dut/w_end_fout
add wave -noupdate -radix unsigned /tb/dut/r_feat_in
add wave -noupdate -radix unsigned /tb/dut/r_weight
add wave -noupdate -radix unsigned /tb/dut/r_feat_out
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
add wave -noupdate /tb/memory_write/clk
add wave -noupdate /tb/memory_write/reset
add wave -noupdate /tb/memory_write/chip_en
add wave -noupdate /tb/memory_write/wr_en
add wave -noupdate -radix decimal /tb/memory_write/address
add wave -noupdate -radix decimal /tb/memory_write/data_in
add wave -noupdate -radix decimal /tb/memory_write/data_out
add wave -noupdate /tb/memory_write/data_valid
add wave -noupdate -radix decimal /tb/memory_write/data
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {565 ns} 0 Red default} {{Cursor 2} {0 ns} 0}
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
WaveRestoreZoom {677 ns} {901 ns}
