onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider high_level
add wave -noupdate /tb/dut/w_read_fin
add wave -noupdate /tb/dut/w_conv_start_dbg
add wave -noupdate /tb/dut/w_conv_end_dbg
add wave -noupdate /tb/dut/w_idle_conv_dbg
add wave -noupdate /tb/dut/w_read_ofmap
add wave -noupdate /tb/dut/w_write_ofmap
add wave -noupdate -radix unsigned /tb/dut/w_addr_ptr_pout
add wave -noupdate -radix unsigned /tb/dut/p_output_addr
add wave -noupdate -radix unsigned /tb/dut/r_col_index_output
add wave -noupdate -radix unsigned /tb/dut/r_row_index_output
add wave -noupdate -radix unsigned /tb/dut/r_row_stride_output
add wave -noupdate -radix unsigned /tb/dut/w_col_offset_output
add wave -noupdate -radix unsigned /tb/dut/w_offset_total_output
add wave -noupdate -radix unsigned /tb/dut/r_weight_read_latency
add wave -noupdate -radix unsigned /tb/dut/r_input_read_latency
add wave -noupdate -radix unsigned /tb/dut/r_output_read_latency
add wave -noupdate -radix unsigned /tb/dut/r_output_write_latency
add wave -noupdate /tb/dut/w_weight_data_ready
add wave -noupdate /tb/dut/w_input_data_ready
add wave -noupdate /tb/dut/w_output_data_ready
add wave -noupdate /tb/dut/w_weight_read_pending
add wave -noupdate /tb/dut/w_input_read_pending
add wave -noupdate /tb/dut/w_output_read_pending
add wave -noupdate /tb/dut/w_output_write_ready
add wave -noupdate /tb/dut/w_output_write_pending
add wave -noupdate -divider base
add wave -noupdate /tb/dut/clk
add wave -noupdate /tb/dut/reset
add wave -noupdate /tb/dut/p_start
add wave -noupdate /tb/dut/p_end
add wave -noupdate -color Red /tb/dut/p_conv_start
add wave -noupdate -color Red /tb/dut/p_conv_end
add wave -noupdate /tb/dut/r_conv_end
add wave -noupdate /tb/dut/f_is_last_row_input/w_is_last_row_input
add wave -noupdate /tb/dut/f_is_last_channel_input/w_is_last_channel_input
add wave -noupdate -radix unsigned /tb/dut/r_hold_output
add wave -noupdate /tb/dut/current_st_input
add wave -noupdate /tb/conv/current_state
add wave -noupdate /tb/dut/current_st_output
add wave -noupdate -color Red /tb/dut/f_is_last_row_out/w_is_last_row_out
add wave -noupdate /tb/dut/f_is_last_read_input/w_is_last_read_input
add wave -noupdate -divider handshake
add wave -noupdate /tb/dut/r_conv_busy
add wave -noupdate /tb/dut/w_conv_ready_for_input
add wave -noupdate /tb/dut/w_conv_input_fire
add wave -noupdate /tb/dut/r_conv_result_pending
add wave -noupdate /tb/dut/w_conv_result_ready
add wave -noupdate /tb/dut/w_conv_result_accept
add wave -noupdate -divider control
add wave -noupdate -radix decimal -childformat {{{/tb/dut/p_conv_output[8]} -radix decimal} {{/tb/dut/p_conv_output[7]} -radix decimal} {{/tb/dut/p_conv_output[6]} -radix decimal} {{/tb/dut/p_conv_output[5]} -radix decimal} {{/tb/dut/p_conv_output[4]} -radix decimal} {{/tb/dut/p_conv_output[3]} -radix decimal} {{/tb/dut/p_conv_output[2]} -radix decimal} {{/tb/dut/p_conv_output[1]} -radix decimal} {{/tb/dut/p_conv_output[0]} -radix decimal}} -expand -subitemconfig {{/tb/dut/p_conv_output[8]} {-height 16 -radix decimal} {/tb/dut/p_conv_output[7]} {-height 16 -radix decimal} {/tb/dut/p_conv_output[6]} {-height 16 -radix decimal} {/tb/dut/p_conv_output[5]} {-height 16 -radix decimal} {/tb/dut/p_conv_output[4]} {-height 16 -radix decimal} {/tb/dut/p_conv_output[3]} {-height 16 -radix decimal} {/tb/dut/p_conv_output[2]} {-height 16 -radix decimal} {/tb/dut/p_conv_output[1]} {-height 16 -radix decimal} {/tb/dut/p_conv_output[0]} {-height 16 -radix decimal}} /tb/dut/p_conv_output
add wave -noupdate -radix decimal -childformat {{{/tb/dut/p_conv_input[24]} -radix decimal} {{/tb/dut/p_conv_input[23]} -radix decimal} {{/tb/dut/p_conv_input[22]} -radix decimal} {{/tb/dut/p_conv_input[21]} -radix decimal} {{/tb/dut/p_conv_input[20]} -radix decimal} {{/tb/dut/p_conv_input[19]} -radix decimal} {{/tb/dut/p_conv_input[18]} -radix decimal} {{/tb/dut/p_conv_input[17]} -radix decimal} {{/tb/dut/p_conv_input[16]} -radix decimal} {{/tb/dut/p_conv_input[15]} -radix decimal} {{/tb/dut/p_conv_input[14]} -radix decimal} {{/tb/dut/p_conv_input[13]} -radix decimal} {{/tb/dut/p_conv_input[12]} -radix decimal} {{/tb/dut/p_conv_input[11]} -radix decimal} {{/tb/dut/p_conv_input[10]} -radix decimal} {{/tb/dut/p_conv_input[9]} -radix decimal} {{/tb/dut/p_conv_input[8]} -radix decimal} {{/tb/dut/p_conv_input[7]} -radix decimal} {{/tb/dut/p_conv_input[6]} -radix decimal} {{/tb/dut/p_conv_input[5]} -radix decimal} {{/tb/dut/p_conv_input[4]} -radix decimal} {{/tb/dut/p_conv_input[3]} -radix decimal} {{/tb/dut/p_conv_input[2]} -radix decimal} {{/tb/dut/p_conv_input[1]} -radix decimal} {{/tb/dut/p_conv_input[0]} -radix decimal}} -subitemconfig {{/tb/dut/p_conv_input[24]} {-height 16 -radix decimal} {/tb/dut/p_conv_input[23]} {-height 16 -radix decimal} {/tb/dut/p_conv_input[22]} {-height 16 -radix decimal} {/tb/dut/p_conv_input[21]} {-height 16 -radix decimal} {/tb/dut/p_conv_input[20]} {-height 16 -radix decimal} {/tb/dut/p_conv_input[19]} {-height 16 -radix decimal} {/tb/dut/p_conv_input[18]} {-height 16 -radix decimal} {/tb/dut/p_conv_input[17]} {-height 16 -radix decimal} {/tb/dut/p_conv_input[16]} {-height 16 -radix decimal} {/tb/dut/p_conv_input[15]} {-height 16 -radix decimal} {/tb/dut/p_conv_input[14]} {-height 16 -radix decimal} {/tb/dut/p_conv_input[13]} {-height 16 -radix decimal} {/tb/dut/p_conv_input[12]} {-height 16 -radix decimal} {/tb/dut/p_conv_input[11]} {-height 16 -radix decimal} {/tb/dut/p_conv_input[10]} {-height 16 -radix decimal} {/tb/dut/p_conv_input[9]} {-height 16 -radix decimal} {/tb/dut/p_conv_input[8]} {-height 16 -radix decimal} {/tb/dut/p_conv_input[7]} {-height 16 -radix decimal} {/tb/dut/p_conv_input[6]} {-height 16 -radix decimal} {/tb/dut/p_conv_input[5]} {-height 16 -radix decimal} {/tb/dut/p_conv_input[4]} {-height 16 -radix decimal} {/tb/dut/p_conv_input[3]} {-height 16 -radix decimal} {/tb/dut/p_conv_input[2]} {-height 16 -radix decimal} {/tb/dut/p_conv_input[1]} {-height 16 -radix decimal} {/tb/dut/p_conv_input[0]} {-height 16 -radix decimal}} /tb/dut/p_conv_input
add wave -noupdate -radix decimal -childformat {{{/tb/dut/p_conv_weight[35]} -radix decimal} {{/tb/dut/p_conv_weight[34]} -radix decimal} {{/tb/dut/p_conv_weight[33]} -radix decimal} {{/tb/dut/p_conv_weight[32]} -radix decimal} {{/tb/dut/p_conv_weight[31]} -radix decimal} {{/tb/dut/p_conv_weight[30]} -radix decimal} {{/tb/dut/p_conv_weight[29]} -radix decimal} {{/tb/dut/p_conv_weight[28]} -radix decimal} {{/tb/dut/p_conv_weight[27]} -radix decimal} {{/tb/dut/p_conv_weight[26]} -radix decimal} {{/tb/dut/p_conv_weight[25]} -radix decimal} {{/tb/dut/p_conv_weight[24]} -radix decimal} {{/tb/dut/p_conv_weight[23]} -radix decimal} {{/tb/dut/p_conv_weight[22]} -radix decimal} {{/tb/dut/p_conv_weight[21]} -radix decimal} {{/tb/dut/p_conv_weight[20]} -radix decimal} {{/tb/dut/p_conv_weight[19]} -radix decimal} {{/tb/dut/p_conv_weight[18]} -radix decimal} {{/tb/dut/p_conv_weight[17]} -radix decimal} {{/tb/dut/p_conv_weight[16]} -radix decimal} {{/tb/dut/p_conv_weight[15]} -radix decimal} {{/tb/dut/p_conv_weight[14]} -radix decimal} {{/tb/dut/p_conv_weight[13]} -radix decimal} {{/tb/dut/p_conv_weight[12]} -radix decimal} {{/tb/dut/p_conv_weight[11]} -radix decimal} {{/tb/dut/p_conv_weight[10]} -radix decimal} {{/tb/dut/p_conv_weight[9]} -radix decimal} {{/tb/dut/p_conv_weight[8]} -radix decimal} {{/tb/dut/p_conv_weight[7]} -radix decimal} {{/tb/dut/p_conv_weight[6]} -radix decimal} {{/tb/dut/p_conv_weight[5]} -radix decimal} {{/tb/dut/p_conv_weight[4]} -radix decimal} {{/tb/dut/p_conv_weight[3]} -radix decimal} {{/tb/dut/p_conv_weight[2]} -radix decimal} {{/tb/dut/p_conv_weight[1]} -radix decimal} {{/tb/dut/p_conv_weight[0]} -radix decimal}} -subitemconfig {{/tb/dut/p_conv_weight[35]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[34]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[33]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[32]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[31]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[30]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[29]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[28]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[27]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[26]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[25]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[24]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[23]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[22]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[21]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[20]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[19]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[18]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[17]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[16]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[15]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[14]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[13]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[12]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[11]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[10]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[9]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[8]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[7]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[6]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[5]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[4]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[3]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[2]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[1]} {-height 16 -radix decimal} {/tb/dut/p_conv_weight[0]} {-height 16 -radix decimal}} /tb/dut/p_conv_weight
add wave -noupdate /tb/dut/p_input_en
add wave -noupdate /tb/dut/p_input_valid
add wave -noupdate /tb/dut/p_output_en
add wave -noupdate /tb/dut/p_output_wr
add wave -noupdate -radix unsigned /tb/dut/p_input_addr
add wave -noupdate -radix decimal /tb/dut/p_input_data
add wave -noupdate -radix unsigned /tb/dut/p_output_addr
add wave -noupdate -radix decimal /tb/dut/p_output_data_read
add wave -noupdate -radix decimal -childformat {{{/tb/dut/p_output_data_write[19]} -radix decimal} {{/tb/dut/p_output_data_write[18]} -radix decimal} {{/tb/dut/p_output_data_write[17]} -radix decimal} {{/tb/dut/p_output_data_write[16]} -radix decimal} {{/tb/dut/p_output_data_write[15]} -radix decimal} {{/tb/dut/p_output_data_write[14]} -radix decimal} {{/tb/dut/p_output_data_write[13]} -radix decimal} {{/tb/dut/p_output_data_write[12]} -radix decimal} {{/tb/dut/p_output_data_write[11]} -radix decimal} {{/tb/dut/p_output_data_write[10]} -radix decimal} {{/tb/dut/p_output_data_write[9]} -radix decimal} {{/tb/dut/p_output_data_write[8]} -radix decimal} {{/tb/dut/p_output_data_write[7]} -radix decimal} {{/tb/dut/p_output_data_write[6]} -radix decimal} {{/tb/dut/p_output_data_write[5]} -radix decimal} {{/tb/dut/p_output_data_write[4]} -radix decimal} {{/tb/dut/p_output_data_write[3]} -radix decimal} {{/tb/dut/p_output_data_write[2]} -radix decimal} {{/tb/dut/p_output_data_write[1]} -radix decimal} {{/tb/dut/p_output_data_write[0]} -radix decimal}} -subitemconfig {{/tb/dut/p_output_data_write[19]} {-height 16 -radix decimal} {/tb/dut/p_output_data_write[18]} {-height 16 -radix decimal} {/tb/dut/p_output_data_write[17]} {-height 16 -radix decimal} {/tb/dut/p_output_data_write[16]} {-height 16 -radix decimal} {/tb/dut/p_output_data_write[15]} {-height 16 -radix decimal} {/tb/dut/p_output_data_write[14]} {-height 16 -radix decimal} {/tb/dut/p_output_data_write[13]} {-height 16 -radix decimal} {/tb/dut/p_output_data_write[12]} {-height 16 -radix decimal} {/tb/dut/p_output_data_write[11]} {-height 16 -radix decimal} {/tb/dut/p_output_data_write[10]} {-height 16 -radix decimal} {/tb/dut/p_output_data_write[9]} {-height 16 -radix decimal} {/tb/dut/p_output_data_write[8]} {-height 16 -radix decimal} {/tb/dut/p_output_data_write[7]} {-height 16 -radix decimal} {/tb/dut/p_output_data_write[6]} {-height 16 -radix decimal} {/tb/dut/p_output_data_write[5]} {-height 16 -radix decimal} {/tb/dut/p_output_data_write[4]} {-height 16 -radix decimal} {/tb/dut/p_output_data_write[3]} {-height 16 -radix decimal} {/tb/dut/p_output_data_write[2]} {-height 16 -radix decimal} {/tb/dut/p_output_data_write[1]} {-height 16 -radix decimal} {/tb/dut/p_output_data_write[0]} {-height 16 -radix decimal}} /tb/dut/p_output_data_write
add wave -noupdate /tb/dut/p_output_valid
add wave -noupdate -radix decimal -childformat {{{/tb/dut/r_feat_input[24]} -radix decimal} {{/tb/dut/r_feat_input[23]} -radix decimal} {{/tb/dut/r_feat_input[22]} -radix decimal} {{/tb/dut/r_feat_input[21]} -radix decimal} {{/tb/dut/r_feat_input[20]} -radix decimal} {{/tb/dut/r_feat_input[19]} -radix decimal} {{/tb/dut/r_feat_input[18]} -radix decimal} {{/tb/dut/r_feat_input[17]} -radix decimal} {{/tb/dut/r_feat_input[16]} -radix decimal} {{/tb/dut/r_feat_input[15]} -radix decimal} {{/tb/dut/r_feat_input[14]} -radix decimal} {{/tb/dut/r_feat_input[13]} -radix decimal} {{/tb/dut/r_feat_input[12]} -radix decimal} {{/tb/dut/r_feat_input[11]} -radix decimal} {{/tb/dut/r_feat_input[10]} -radix decimal} {{/tb/dut/r_feat_input[9]} -radix decimal} {{/tb/dut/r_feat_input[8]} -radix decimal} {{/tb/dut/r_feat_input[7]} -radix decimal} {{/tb/dut/r_feat_input[6]} -radix decimal} {{/tb/dut/r_feat_input[5]} -radix decimal} {{/tb/dut/r_feat_input[4]} -radix decimal} {{/tb/dut/r_feat_input[3]} -radix decimal} {{/tb/dut/r_feat_input[2]} -radix decimal} {{/tb/dut/r_feat_input[1]} -radix decimal} {{/tb/dut/r_feat_input[0]} -radix decimal}} -subitemconfig {{/tb/dut/r_feat_input[24]} {-height 16 -radix decimal} {/tb/dut/r_feat_input[23]} {-height 16 -radix decimal} {/tb/dut/r_feat_input[22]} {-height 16 -radix decimal} {/tb/dut/r_feat_input[21]} {-height 16 -radix decimal} {/tb/dut/r_feat_input[20]} {-height 16 -radix decimal} {/tb/dut/r_feat_input[19]} {-height 16 -radix decimal} {/tb/dut/r_feat_input[18]} {-height 16 -radix decimal} {/tb/dut/r_feat_input[17]} {-height 16 -radix decimal} {/tb/dut/r_feat_input[16]} {-height 16 -radix decimal} {/tb/dut/r_feat_input[15]} {-height 16 -radix decimal} {/tb/dut/r_feat_input[14]} {-height 16 -radix decimal} {/tb/dut/r_feat_input[13]} {-height 16 -radix decimal} {/tb/dut/r_feat_input[12]} {-height 16 -radix decimal} {/tb/dut/r_feat_input[11]} {-height 16 -radix decimal} {/tb/dut/r_feat_input[10]} {-height 16 -radix decimal} {/tb/dut/r_feat_input[9]} {-height 16 -radix decimal} {/tb/dut/r_feat_input[8]} {-height 16 -radix decimal} {/tb/dut/r_feat_input[7]} {-height 16 -radix decimal} {/tb/dut/r_feat_input[6]} {-height 16 -radix decimal} {/tb/dut/r_feat_input[5]} {-height 16 -radix decimal} {/tb/dut/r_feat_input[4]} {-height 16 -radix decimal} {/tb/dut/r_feat_input[3]} {-height 16 -radix decimal} {/tb/dut/r_feat_input[2]} {-height 16 -radix decimal} {/tb/dut/r_feat_input[1]} {-height 16 -radix decimal} {/tb/dut/r_feat_input[0]} {-height 16 -radix decimal}} /tb/dut/r_feat_input
add wave -noupdate -radix decimal -childformat {{{/tb/dut/r_feat_output[8]} -radix decimal} {{/tb/dut/r_feat_output[7]} -radix decimal} {{/tb/dut/r_feat_output[6]} -radix decimal} {{/tb/dut/r_feat_output[5]} -radix decimal} {{/tb/dut/r_feat_output[4]} -radix decimal} {{/tb/dut/r_feat_output[3]} -radix decimal} {{/tb/dut/r_feat_output[2]} -radix decimal} {{/tb/dut/r_feat_output[1]} -radix decimal} {{/tb/dut/r_feat_output[0]} -radix decimal}} -expand -subitemconfig {{/tb/dut/r_feat_output[8]} {-height 16 -radix decimal} {/tb/dut/r_feat_output[7]} {-height 16 -radix decimal} {/tb/dut/r_feat_output[6]} {-height 16 -radix decimal} {/tb/dut/r_feat_output[5]} {-height 16 -radix decimal} {/tb/dut/r_feat_output[4]} {-height 16 -radix decimal} {/tb/dut/r_feat_output[3]} {-height 16 -radix decimal} {/tb/dut/r_feat_output[2]} {-height 16 -radix decimal} {/tb/dut/r_feat_output[1]} {-height 16 -radix decimal} {/tb/dut/r_feat_output[0]} {-height 16 -radix decimal}} /tb/dut/r_feat_output
add wave -noupdate -radix decimal -childformat {{{/tb/dut/r_conv_output[8]} -radix decimal} {{/tb/dut/r_conv_output[7]} -radix decimal} {{/tb/dut/r_conv_output[6]} -radix decimal} {{/tb/dut/r_conv_output[5]} -radix decimal} {{/tb/dut/r_conv_output[4]} -radix decimal} {{/tb/dut/r_conv_output[3]} -radix decimal} {{/tb/dut/r_conv_output[2]} -radix decimal} {{/tb/dut/r_conv_output[1]} -radix decimal} {{/tb/dut/r_conv_output[0]} -radix decimal}} -expand -subitemconfig {{/tb/dut/r_conv_output[8]} {-height 16 -radix decimal} {/tb/dut/r_conv_output[7]} {-height 16 -radix decimal} {/tb/dut/r_conv_output[6]} {-height 16 -radix decimal} {/tb/dut/r_conv_output[5]} {-height 16 -radix decimal} {/tb/dut/r_conv_output[4]} {-height 16 -radix decimal} {/tb/dut/r_conv_output[3]} {-height 16 -radix decimal} {/tb/dut/r_conv_output[2]} {-height 16 -radix decimal} {/tb/dut/r_conv_output[1]} {-height 16 -radix decimal} {/tb/dut/r_conv_output[0]} {-height 16 -radix decimal}} /tb/dut/r_conv_output
add wave -noupdate -radix unsigned /tb/dut/r_addr_pointer_bias
add wave -noupdate -radix unsigned /tb/dut/r_addr_pointer_out
add wave -noupdate -radix unsigned /tb/dut/r_addr_pointer_kernel
add wave -noupdate -radix unsigned /tb/dut/r_addr_pointer_input
add wave -noupdate -radix unsigned /tb/dut/r_addr_count_kernel
add wave -noupdate -radix unsigned /tb/dut/r_addr_count_input
add wave -noupdate -radix unsigned /tb/dut/r_addr_count_read_out
add wave -noupdate -radix unsigned /tb/dut/r_addr_count_write_out
add wave -noupdate -radix unsigned /tb/dut/r_window_counter_total_input
add wave -noupdate -radix unsigned /tb/dut/r_window_counter_all_channel_input
add wave -noupdate -radix unsigned /tb/dut/r_window_counter_channel_input
add wave -noupdate -radix unsigned /tb/dut/r_window_counter_row_input
add wave -noupdate -radix unsigned /tb/dut/r_window_counter_total_out
add wave -noupdate -radix unsigned /tb/dut/r_window_counter_all_channel_out
add wave -noupdate -radix unsigned /tb/dut/r_window_counter_channel_out
add wave -noupdate -radix unsigned /tb/dut/r_window_counter_row_out
add wave -noupdate -radix unsigned /tb/dut/r_channel_counter_input
add wave -noupdate -radix unsigned /tb/dut/r_channel_counter_out
add wave -noupdate /tb/dut/r_read_en
add wave -noupdate -radix decimal -childformat {{{/tb/dut/r_kernel[35]} -radix decimal} {{/tb/dut/r_kernel[34]} -radix decimal} {{/tb/dut/r_kernel[33]} -radix decimal} {{/tb/dut/r_kernel[32]} -radix decimal} {{/tb/dut/r_kernel[31]} -radix decimal} {{/tb/dut/r_kernel[30]} -radix decimal} {{/tb/dut/r_kernel[29]} -radix decimal} {{/tb/dut/r_kernel[28]} -radix decimal} {{/tb/dut/r_kernel[27]} -radix decimal} {{/tb/dut/r_kernel[26]} -radix decimal} {{/tb/dut/r_kernel[25]} -radix decimal} {{/tb/dut/r_kernel[24]} -radix decimal} {{/tb/dut/r_kernel[23]} -radix decimal} {{/tb/dut/r_kernel[22]} -radix decimal} {{/tb/dut/r_kernel[21]} -radix decimal} {{/tb/dut/r_kernel[20]} -radix decimal} {{/tb/dut/r_kernel[19]} -radix decimal} {{/tb/dut/r_kernel[18]} -radix decimal} {{/tb/dut/r_kernel[17]} -radix decimal} {{/tb/dut/r_kernel[16]} -radix decimal} {{/tb/dut/r_kernel[15]} -radix decimal} {{/tb/dut/r_kernel[14]} -radix decimal} {{/tb/dut/r_kernel[13]} -radix decimal} {{/tb/dut/r_kernel[12]} -radix decimal} {{/tb/dut/r_kernel[11]} -radix decimal} {{/tb/dut/r_kernel[10]} -radix decimal} {{/tb/dut/r_kernel[9]} -radix decimal} {{/tb/dut/r_kernel[8]} -radix decimal} {{/tb/dut/r_kernel[7]} -radix decimal} {{/tb/dut/r_kernel[6]} -radix decimal} {{/tb/dut/r_kernel[5]} -radix decimal} {{/tb/dut/r_kernel[4]} -radix decimal} {{/tb/dut/r_kernel[3]} -radix decimal} {{/tb/dut/r_kernel[2]} -radix decimal} {{/tb/dut/r_kernel[1]} -radix decimal} {{/tb/dut/r_kernel[0]} -radix decimal}} -subitemconfig {{/tb/dut/r_kernel[35]} {-height 16 -radix decimal} {/tb/dut/r_kernel[34]} {-height 16 -radix decimal} {/tb/dut/r_kernel[33]} {-height 16 -radix decimal} {/tb/dut/r_kernel[32]} {-height 16 -radix decimal} {/tb/dut/r_kernel[31]} {-height 16 -radix decimal} {/tb/dut/r_kernel[30]} {-height 16 -radix decimal} {/tb/dut/r_kernel[29]} {-height 16 -radix decimal} {/tb/dut/r_kernel[28]} {-height 16 -radix decimal} {/tb/dut/r_kernel[27]} {-height 16 -radix decimal} {/tb/dut/r_kernel[26]} {-height 16 -radix decimal} {/tb/dut/r_kernel[25]} {-height 16 -radix decimal} {/tb/dut/r_kernel[24]} {-height 16 -radix decimal} {/tb/dut/r_kernel[23]} {-height 16 -radix decimal} {/tb/dut/r_kernel[22]} {-height 16 -radix decimal} {/tb/dut/r_kernel[21]} {-height 16 -radix decimal} {/tb/dut/r_kernel[20]} {-height 16 -radix decimal} {/tb/dut/r_kernel[19]} {-height 16 -radix decimal} {/tb/dut/r_kernel[18]} {-height 16 -radix decimal} {/tb/dut/r_kernel[17]} {-height 16 -radix decimal} {/tb/dut/r_kernel[16]} {-height 16 -radix decimal} {/tb/dut/r_kernel[15]} {-height 16 -radix decimal} {/tb/dut/r_kernel[14]} {-height 16 -radix decimal} {/tb/dut/r_kernel[13]} {-height 16 -radix decimal} {/tb/dut/r_kernel[12]} {-height 16 -radix decimal} {/tb/dut/r_kernel[11]} {-height 16 -radix decimal} {/tb/dut/r_kernel[10]} {-height 16 -radix decimal} {/tb/dut/r_kernel[9]} {-height 16 -radix decimal} {/tb/dut/r_kernel[8]} {-height 16 -radix decimal} {/tb/dut/r_kernel[7]} {-height 16 -radix decimal} {/tb/dut/r_kernel[6]} {-height 16 -radix decimal} {/tb/dut/r_kernel[5]} {-height 16 -radix decimal} {/tb/dut/r_kernel[4]} {-height 16 -radix decimal} {/tb/dut/r_kernel[3]} {-height 16 -radix decimal} {/tb/dut/r_kernel[2]} {-height 16 -radix decimal} {/tb/dut/r_kernel[1]} {-height 16 -radix decimal} {/tb/dut/r_kernel[0]} {-height 16 -radix decimal}} /tb/dut/r_kernel
add wave -noupdate /tb/dut/f_is_last_read_input/w_is_last_read_input
add wave -noupdate /tb/dut/f_is_last_row_input/w_is_last_row_input
add wave -noupdate /tb/dut/f_is_last_channel_input/w_is_last_channel_input
add wave -noupdate /tb/dut/f_is_last_all_channel_input/w_is_last_all_channel_input
add wave -noupdate /tb/dut/f_is_last_read_out/w_is_last_read_out
add wave -noupdate /tb/dut/f_is_last_write_out/w_is_last_write_out
add wave -noupdate /tb/dut/f_is_last_row_out/w_is_last_row_out
add wave -noupdate /tb/dut/f_is_last_channel_out/w_is_last_channel_out
add wave -noupdate /tb/dut/f_is_last_all_channel_out/w_is_last_all_channel_out
add wave -noupdate -radix unsigned /tb/dut/w_addr_ptr_pin
add wave -noupdate /tb/dut/w_output_en
add wave -noupdate -radix octal -childformat {{{/tb/conv/r_feat[35]} -radix decimal} {{/tb/conv/r_feat[34]} -radix decimal} {{/tb/conv/r_feat[33]} -radix decimal} {{/tb/conv/r_feat[32]} -radix decimal} {{/tb/conv/r_feat[31]} -radix decimal} {{/tb/conv/r_feat[30]} -radix decimal} {{/tb/conv/r_feat[29]} -radix decimal} {{/tb/conv/r_feat[28]} -radix decimal} {{/tb/conv/r_feat[27]} -radix decimal} {{/tb/conv/r_feat[26]} -radix decimal} {{/tb/conv/r_feat[25]} -radix decimal} {{/tb/conv/r_feat[24]} -radix decimal} {{/tb/conv/r_feat[23]} -radix decimal} {{/tb/conv/r_feat[22]} -radix decimal} {{/tb/conv/r_feat[21]} -radix decimal} {{/tb/conv/r_feat[20]} -radix decimal} {{/tb/conv/r_feat[19]} -radix decimal} {{/tb/conv/r_feat[18]} -radix decimal} {{/tb/conv/r_feat[17]} -radix decimal} {{/tb/conv/r_feat[16]} -radix decimal} {{/tb/conv/r_feat[15]} -radix decimal} {{/tb/conv/r_feat[14]} -radix decimal} {{/tb/conv/r_feat[13]} -radix decimal} {{/tb/conv/r_feat[12]} -radix decimal} {{/tb/conv/r_feat[11]} -radix decimal} {{/tb/conv/r_feat[10]} -radix decimal} {{/tb/conv/r_feat[9]} -radix decimal} {{/tb/conv/r_feat[8]} -radix decimal} {{/tb/conv/r_feat[7]} -radix decimal} {{/tb/conv/r_feat[6]} -radix decimal} {{/tb/conv/r_feat[5]} -radix decimal} {{/tb/conv/r_feat[4]} -radix decimal} {{/tb/conv/r_feat[3]} -radix decimal} {{/tb/conv/r_feat[2]} -radix decimal} {{/tb/conv/r_feat[1]} -radix decimal} {{/tb/conv/r_feat[0]} -radix decimal}} -subitemconfig {{/tb/conv/r_feat[35]} {-height 16 -radix decimal} {/tb/conv/r_feat[34]} {-height 16 -radix decimal} {/tb/conv/r_feat[33]} {-height 16 -radix decimal} {/tb/conv/r_feat[32]} {-height 16 -radix decimal} {/tb/conv/r_feat[31]} {-height 16 -radix decimal} {/tb/conv/r_feat[30]} {-height 16 -radix decimal} {/tb/conv/r_feat[29]} {-height 16 -radix decimal} {/tb/conv/r_feat[28]} {-height 16 -radix decimal} {/tb/conv/r_feat[27]} {-height 16 -radix decimal} {/tb/conv/r_feat[26]} {-height 16 -radix decimal} {/tb/conv/r_feat[25]} {-height 16 -radix decimal} {/tb/conv/r_feat[24]} {-height 16 -radix decimal} {/tb/conv/r_feat[23]} {-height 16 -radix decimal} {/tb/conv/r_feat[22]} {-height 16 -radix decimal} {/tb/conv/r_feat[21]} {-height 16 -radix decimal} {/tb/conv/r_feat[20]} {-height 16 -radix decimal} {/tb/conv/r_feat[19]} {-height 16 -radix decimal} {/tb/conv/r_feat[18]} {-height 16 -radix decimal} {/tb/conv/r_feat[17]} {-height 16 -radix decimal} {/tb/conv/r_feat[16]} {-height 16 -radix decimal} {/tb/conv/r_feat[15]} {-height 16 -radix decimal} {/tb/conv/r_feat[14]} {-height 16 -radix decimal} {/tb/conv/r_feat[13]} {-height 16 -radix decimal} {/tb/conv/r_feat[12]} {-height 16 -radix decimal} {/tb/conv/r_feat[11]} {-height 16 -radix decimal} {/tb/conv/r_feat[10]} {-height 16 -radix decimal} {/tb/conv/r_feat[9]} {-height 16 -radix decimal} {/tb/conv/r_feat[8]} {-height 16 -radix decimal} {/tb/conv/r_feat[7]} {-height 16 -radix decimal} {/tb/conv/r_feat[6]} {-height 16 -radix decimal} {/tb/conv/r_feat[5]} {-height 16 -radix decimal} {/tb/conv/r_feat[4]} {-height 16 -radix decimal} {/tb/conv/r_feat[3]} {-height 16 -radix decimal} {/tb/conv/r_feat[2]} {-height 16 -radix decimal} {/tb/conv/r_feat[1]} {-height 16 -radix decimal} {/tb/conv/r_feat[0]} {-height 16 -radix decimal}} /tb/conv/r_feat
add wave -noupdate -divider mem-read
add wave -noupdate /tb/memory_read/clk
add wave -noupdate /tb/memory_read/reset
add wave -noupdate /tb/memory_read/chip_en
add wave -noupdate /tb/memory_read/wr_en
add wave -noupdate -radix unsigned /tb/memory_read/address
add wave -noupdate /tb/memory_read/data_in
add wave -noupdate -radix decimal /tb/memory_read/data_out
add wave -noupdate /tb/memory_read/data_valid
add wave -noupdate -divider mem-write
add wave -noupdate /tb/memory_write/clk
add wave -noupdate /tb/memory_write/reset
add wave -noupdate /tb/memory_write/chip_en
add wave -noupdate /tb/memory_write/wr_en
add wave -noupdate -radix unsigned /tb/memory_write/address
add wave -noupdate -radix decimal -childformat {{{/tb/memory_write/data_in[19]} -radix decimal} {{/tb/memory_write/data_in[18]} -radix decimal} {{/tb/memory_write/data_in[17]} -radix decimal} {{/tb/memory_write/data_in[16]} -radix decimal} {{/tb/memory_write/data_in[15]} -radix decimal} {{/tb/memory_write/data_in[14]} -radix decimal} {{/tb/memory_write/data_in[13]} -radix decimal} {{/tb/memory_write/data_in[12]} -radix decimal} {{/tb/memory_write/data_in[11]} -radix decimal} {{/tb/memory_write/data_in[10]} -radix decimal} {{/tb/memory_write/data_in[9]} -radix decimal} {{/tb/memory_write/data_in[8]} -radix decimal} {{/tb/memory_write/data_in[7]} -radix decimal} {{/tb/memory_write/data_in[6]} -radix decimal} {{/tb/memory_write/data_in[5]} -radix decimal} {{/tb/memory_write/data_in[4]} -radix decimal} {{/tb/memory_write/data_in[3]} -radix decimal} {{/tb/memory_write/data_in[2]} -radix decimal} {{/tb/memory_write/data_in[1]} -radix decimal} {{/tb/memory_write/data_in[0]} -radix decimal}} -subitemconfig {{/tb/memory_write/data_in[19]} {-height 16 -radix decimal} {/tb/memory_write/data_in[18]} {-height 16 -radix decimal} {/tb/memory_write/data_in[17]} {-height 16 -radix decimal} {/tb/memory_write/data_in[16]} {-height 16 -radix decimal} {/tb/memory_write/data_in[15]} {-height 16 -radix decimal} {/tb/memory_write/data_in[14]} {-height 16 -radix decimal} {/tb/memory_write/data_in[13]} {-height 16 -radix decimal} {/tb/memory_write/data_in[12]} {-height 16 -radix decimal} {/tb/memory_write/data_in[11]} {-height 16 -radix decimal} {/tb/memory_write/data_in[10]} {-height 16 -radix decimal} {/tb/memory_write/data_in[9]} {-height 16 -radix decimal} {/tb/memory_write/data_in[8]} {-height 16 -radix decimal} {/tb/memory_write/data_in[7]} {-height 16 -radix decimal} {/tb/memory_write/data_in[6]} {-height 16 -radix decimal} {/tb/memory_write/data_in[5]} {-height 16 -radix decimal} {/tb/memory_write/data_in[4]} {-height 16 -radix decimal} {/tb/memory_write/data_in[3]} {-height 16 -radix decimal} {/tb/memory_write/data_in[2]} {-height 16 -radix decimal} {/tb/memory_write/data_in[1]} {-height 16 -radix decimal} {/tb/memory_write/data_in[0]} {-height 16 -radix decimal}} /tb/memory_write/data_in
add wave -noupdate -radix decimal /tb/memory_write/data_out
add wave -noupdate /tb/memory_write/data_valid
add wave -noupdate -radix decimal /tb/memory_write/data
add wave -noupdate -divider localparams
add wave -noupdate -radix unsigned /tb/dut/INPUT_NUM_ELEMS
add wave -noupdate -radix unsigned /tb/dut/OUTPUT_NUM_ELEMS
add wave -noupdate -radix unsigned /tb/dut/INPUT_FEATURE_NUM_ELEMS
add wave -noupdate -radix unsigned /tb/dut/OUTPUT_FEATURE_NUM_ELEMS
add wave -noupdate -radix unsigned /tb/dut/KERNEL_NUM_ELEMS
add wave -noupdate -radix unsigned /tb/dut/TOTAL_NUM_CHANNELS
add wave -noupdate -radix unsigned /tb/dut/WINDOW_COUNT_PER_AXIS
add wave -noupdate -radix unsigned /tb/dut/WINDOWS_PER_PLANE
add wave -noupdate -radix unsigned /tb/dut/WINDOWS_PER_INPUT_CHANNEL
add wave -noupdate -radix unsigned /tb/dut/WINDOWS_PER_OUTPUT_CHANNEL
add wave -noupdate -radix unsigned /tb/dut/TOTAL_INPUT_WINDOWS
add wave -noupdate -radix unsigned /tb/dut/LAST_KERNEL_INDEX
add wave -noupdate -radix unsigned /tb/dut/LAST_WINDOW_INDEX_PER_PLANE
add wave -noupdate -radix unsigned /tb/dut/LAST_INPUT_WINDOW_INDEX
add wave -noupdate -radix unsigned /tb/dut/LAST_WINDOW_ROW_INDEX
add wave -noupdate -radix unsigned /tb/dut/LAST_OUTPUT_CHANNEL_WINDOW_INDEX
add wave -noupdate -radix unsigned /tb/dut/RAM_LATENCY
add wave -noupdate -radix unsigned /tb/dut/RAM_LATENCY_RELOAD
add wave -noupdate -radix unsigned /tb/dut/RAM_LATENCY_COUNTER_WIDTH
add wave -noupdate -radix unsigned /tb/dut/CYCLES_HOLD_OUTPUT_RAW
add wave -noupdate -radix unsigned /tb/dut/CYCLES_HOLD_OUTPUT
add wave -noupdate -radix unsigned /tb/dut/INPUT_ROW_WRAP_DELTA
add wave -noupdate -radix unsigned /tb/dut/INPUT_CHANNEL_WRAP_DELTA
add wave -noupdate -radix unsigned /tb/dut/OUTPUT_ROW_WRAP_DELTA
add wave -noupdate -radix unsigned /tb/dut/OUTPUT_CHANNEL_STRIDE
add wave -noupdate -radix unsigned /tb/dut/WINDOW_AXIS_COUNTER_WIDTH
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 3} {3546713 ps} 0} {{Cursor 4} {5870500 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 256
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 30
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1000
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {157500 ns}
