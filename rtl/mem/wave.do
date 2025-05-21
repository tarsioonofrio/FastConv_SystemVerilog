onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix symbolic /tb/memory/clk
add wave -noupdate -radix symbolic /tb/memory/reset
add wave -noupdate /tb/memory/chip_en
add wave -noupdate /tb/memory/wr_en
add wave -noupdate -radix unsigned /tb/memory/address
add wave -noupdate -radix decimal /tb/memory/data_in
add wave -noupdate -radix decimal /tb/memory/data_out
add wave -noupdate -radix decimal /tb/memory/reg_out
add wave -noupdate -radix decimal /tb/memory/wire_out
add wave -noupdate -radix symbolic /tb/memory/data_valid
add wave -noupdate /tb/memory/reg_valid
add wave -noupdate /tb/memory/wire_valid
add wave -noupdate /tb/row
add wave -noupdate /tb/col
add wave -noupdate -radix decimal -childformat {{{/tb/memory/data[31]} -radix decimal} {{/tb/memory/data[30]} -radix decimal} {{/tb/memory/data[29]} -radix decimal} {{/tb/memory/data[28]} -radix decimal} {{/tb/memory/data[27]} -radix decimal} {{/tb/memory/data[26]} -radix decimal} {{/tb/memory/data[25]} -radix decimal} {{/tb/memory/data[24]} -radix decimal} {{/tb/memory/data[23]} -radix decimal} {{/tb/memory/data[22]} -radix decimal} {{/tb/memory/data[21]} -radix decimal} {{/tb/memory/data[20]} -radix decimal} {{/tb/memory/data[19]} -radix decimal} {{/tb/memory/data[18]} -radix decimal} {{/tb/memory/data[17]} -radix decimal} {{/tb/memory/data[16]} -radix decimal} {{/tb/memory/data[15]} -radix decimal} {{/tb/memory/data[14]} -radix decimal} {{/tb/memory/data[13]} -radix decimal} {{/tb/memory/data[12]} -radix decimal} {{/tb/memory/data[11]} -radix decimal} {{/tb/memory/data[10]} -radix decimal} {{/tb/memory/data[9]} -radix decimal} {{/tb/memory/data[8]} -radix decimal} {{/tb/memory/data[7]} -radix decimal} {{/tb/memory/data[6]} -radix decimal} {{/tb/memory/data[5]} -radix decimal} {{/tb/memory/data[4]} -radix decimal} {{/tb/memory/data[3]} -radix decimal} {{/tb/memory/data[2]} -radix decimal} {{/tb/memory/data[1]} -radix decimal} {{/tb/memory/data[0]} -radix decimal}} -subitemconfig {{/tb/memory/data[31]} {-height 16 -radix decimal} {/tb/memory/data[30]} {-height 16 -radix decimal} {/tb/memory/data[29]} {-height 16 -radix decimal} {/tb/memory/data[28]} {-height 16 -radix decimal} {/tb/memory/data[27]} {-height 16 -radix decimal} {/tb/memory/data[26]} {-height 16 -radix decimal} {/tb/memory/data[25]} {-height 16 -radix decimal} {/tb/memory/data[24]} {-height 16 -radix decimal} {/tb/memory/data[23]} {-height 16 -radix decimal} {/tb/memory/data[22]} {-height 16 -radix decimal} {/tb/memory/data[21]} {-height 16 -radix decimal} {/tb/memory/data[20]} {-height 16 -radix decimal} {/tb/memory/data[19]} {-height 16 -radix decimal} {/tb/memory/data[18]} {-height 16 -radix decimal} {/tb/memory/data[17]} {-height 16 -radix decimal} {/tb/memory/data[16]} {-height 16 -radix decimal} {/tb/memory/data[15]} {-height 16 -radix decimal} {/tb/memory/data[14]} {-height 16 -radix decimal} {/tb/memory/data[13]} {-height 16 -radix decimal} {/tb/memory/data[12]} {-height 16 -radix decimal} {/tb/memory/data[11]} {-height 16 -radix decimal} {/tb/memory/data[10]} {-height 16 -radix decimal} {/tb/memory/data[9]} {-height 16 -radix decimal} {/tb/memory/data[8]} {-height 16 -radix decimal} {/tb/memory/data[7]} {-height 16 -radix decimal} {/tb/memory/data[6]} {-height 16 -radix decimal} {/tb/memory/data[5]} {-height 16 -radix decimal} {/tb/memory/data[4]} {-height 16 -radix decimal} {/tb/memory/data[3]} {-height 16 -radix decimal} {/tb/memory/data[2]} {-height 16 -radix decimal} {/tb/memory/data[1]} {-height 16 -radix decimal} {/tb/memory/data[0]} {-height 16 -radix decimal}} /tb/memory/data
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
configure wave -namecolwidth 229
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
WaveRestoreZoom {5 ns} {121 ns}
