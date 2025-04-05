onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -color Black /tb/conv_naive/clk
add wave -noupdate -color Black /tb/conv_naive/reset
add wave -noupdate -color Black /tb/conv_naive/start
add wave -noupdate -color Black /tb/conv_naive/data_valid
add wave -noupdate -color Black -radix decimal /tb/conv_naive/prod
add wave -noupdate /tb/conv_naive/inputs9
add wave -noupdate -color black /tb/conv_naive/data_valid
add wave -noupdate -color red /tb/conv_naive/row
add wave -noupdate -color red /tb/conv_naive/col
add wave -noupdate -color Black /tb/conv_naive/cont_state
add wave -noupdate -color Black /tb/conv_naive/start_mac
add wave -noupdate -color Black /tb/conv_naive/done_mac
add wave -noupdate -color Black /tb/conv_naive/EA
add wave -noupdate /tb/conv_naive/cont_conv
add wave -noupdate -radix decimal -childformat {{{/tb/conv_naive/outputMAP[0]} -radix decimal} {{/tb/conv_naive/outputMAP[1]} -radix decimal} {{/tb/conv_naive/outputMAP[2]} -radix decimal} {{/tb/conv_naive/outputMAP[3]} -radix decimal} {{/tb/conv_naive/outputMAP[4]} -radix decimal} {{/tb/conv_naive/outputMAP[5]} -radix decimal} {{/tb/conv_naive/outputMAP[6]} -radix decimal} {{/tb/conv_naive/outputMAP[7]} -radix decimal} {{/tb/conv_naive/outputMAP[8]} -radix decimal}} -expand -subitemconfig {{/tb/conv_naive/outputMAP[0]} {-height 21 -radix decimal} {/tb/conv_naive/outputMAP[1]} {-height 21 -radix decimal} {/tb/conv_naive/outputMAP[2]} {-height 21 -radix decimal} {/tb/conv_naive/outputMAP[3]} {-height 21 -radix decimal} {/tb/conv_naive/outputMAP[4]} {-height 21 -radix decimal} {/tb/conv_naive/outputMAP[5]} {-height 21 -radix decimal} {/tb/conv_naive/outputMAP[6]} {-height 21 -radix decimal} {/tb/conv_naive/outputMAP[7]} {-height 21 -radix decimal} {/tb/conv_naive/outputMAP[8]} {-height 21 -radix decimal}} /tb/conv_naive/outputMAP
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1085 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
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
WaveRestoreZoom {999 ns} {1463 ns}
