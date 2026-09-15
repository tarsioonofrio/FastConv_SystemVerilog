# WinoGen comparison point: 317 MHz on the ZCU104.
create_clock -name clk -period 3.154574 [get_ports clk]
set_false_path -from [get_ports reset]
