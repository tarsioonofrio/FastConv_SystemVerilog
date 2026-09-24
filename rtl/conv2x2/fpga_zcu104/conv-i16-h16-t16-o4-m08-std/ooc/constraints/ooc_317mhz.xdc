# OOC IP timing reference. The surrounding system is not physically modeled.
# Zero external delay is an explicit boundary assumption, not a board claim.
create_clock -name clk -period 3.154574 [get_ports clk]

set_input_delay -clock clk -max 0.000 [get_ports {p_start p_input_data[*] p_input_valid p_output_data_read[*] p_output_valid}]
set_input_delay -clock clk -min 0.000 [get_ports {p_start p_input_data[*] p_input_valid p_output_data_read[*] p_output_valid}]

set_output_delay -clock clk -max 0.000 [get_ports {p_end p_input_en p_input_addr[*] p_output_en p_output_wr p_output_addr[*] p_output_data_write[*]}]
set_output_delay -clock clk -min 0.000 [get_ports {p_end p_input_en p_input_addr[*] p_output_en p_output_wr p_output_addr[*] p_output_data_write[*]}]

# Reset is asynchronous. Its assertion/deassertion is reported separately;
# this exception only excludes reset paths from synchronous data-path closure.
set_false_path -from [get_ports reset]
