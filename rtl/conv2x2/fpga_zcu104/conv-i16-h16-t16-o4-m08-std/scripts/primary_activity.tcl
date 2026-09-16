# Generated from RTL/Verilator SAIF. Do not edit by hand.
# Apply after reset_switching_activity -all and before report_power.
set _activity_port [get_ports -quiet {clk}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.4999899998 -toggle_rate 2 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_end}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 4.0000800016e-05 -toggle_rate 8.0001600032e-05 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[0]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.348486969739 -toggle_rate 0.696973939479 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[10]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.322846456929 -toggle_rate 0.0108802176044 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[11]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.322846456929 -toggle_rate 0.00392007840157 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[12]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0 -toggle_rate 0 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[13]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0 -toggle_rate 0 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[14]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0 -toggle_rate 0 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[15]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0 -toggle_rate 0 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[1]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.464409288186 -toggle_rate 0.353527070541 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[2]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.464769295386 -toggle_rate 0.165603312066 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[3]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.464769295386 -toggle_rate 0.0712814256285 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[4]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.464489289786 -toggle_rate 0.0237604752095 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[5]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.510170203404 -toggle_rate 0.173123462469 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[6]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.472369447389 -toggle_rate 0.0867217344347 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[7]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.47588951779 -toggle_rate 0.0433608672173 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[8]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.47520950419 -toggle_rate 0.0216004320086 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[9]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.47520950419 -toggle_rate 0.0108002160043 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[0]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.35040700814 -toggle_rate 0.385767715354 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[10]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.357487149743 -toggle_rate 0.395367907358 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[11]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.357487149743 -toggle_rate 0.395367907358 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[12]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.357487149743 -toggle_rate 0.395367907358 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[13]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.357487149743 -toggle_rate 0.395367907358 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[14]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.357487149743 -toggle_rate 0.395367907358 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[15]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.357487149743 -toggle_rate 0.395367907358 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[16]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.357487149743 -toggle_rate 0.395367907358 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[17]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.357487149743 -toggle_rate 0.395367907358 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[18]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.357487149743 -toggle_rate 0.395367907358 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[19]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.357487149743 -toggle_rate 0.395367907358 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[1]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.35104702094 -toggle_rate 0.378327566551 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[2]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.341606832137 -toggle_rate 0.401848036961 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[3]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.347606952139 -toggle_rate 0.395527910558 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[4]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.352247044941 -toggle_rate 0.390407808156 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[5]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.34940698814 -toggle_rate 0.385607712154 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[6]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.353407068141 -toggle_rate 0.394887897758 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[7]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.347486949739 -toggle_rate 0.387767755355 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[8]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.348126962539 -toggle_rate 0.386887737755 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[9]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.355287105742 -toggle_rate 0.395047900958 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_en}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.697013940279 -toggle_rate 0.162083241665 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_valid}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.697013940279 -toggle_rate 0.162083241665 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_addr[0]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.495249904998 -toggle_rate 0.270005400108 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_addr[10]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.409768195364 -toggle_rate 0.0110002200044 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_addr[11]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.215244304886 -toggle_rate 0.00616012320246 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_addr[12]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0 -toggle_rate 0 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_addr[13]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0 -toggle_rate 0 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_addr[14]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0 -toggle_rate 0 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_addr[15]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0 -toggle_rate 0 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_addr[1]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.47508950179 -toggle_rate 0.545050901018 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_addr[2]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.471929438589 -toggle_rate 0.312646252925 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_addr[3]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.52529050581 -toggle_rate 0.158843176864 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_addr[4]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.469609392188 -toggle_rate 0.0793615872317 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_addr[5]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.477209544191 -toggle_rate 0.508730174603 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_addr[6]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.444928898578 -toggle_rate 0.287125742515 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_addr[7]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.444648892978 -toggle_rate 0.141442828857 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_addr[8]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.512490249805 -toggle_rate 0.0740414808296 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_addr[9]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.47484949699 -toggle_rate 0.0376407528151 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[0]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.317926358527 -toggle_rate 0.214724294486 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[10]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.316246324926 -toggle_rate 0.212644252885 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[11]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.304926098522 -toggle_rate 0.216964339287 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[12]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.304606092122 -toggle_rate 0.222404448089 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[13]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.304246084922 -toggle_rate 0.222804456089 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[14]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.304246084922 -toggle_rate 0.222804456089 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[15]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.304246084922 -toggle_rate 0.222804456089 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[16]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.304246084922 -toggle_rate 0.222804456089 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[17]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.304246084922 -toggle_rate 0.222804456089 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[18]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.304246084922 -toggle_rate 0.222804456089 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[19]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.304246084922 -toggle_rate 0.222804456089 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[1]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.311606232125 -toggle_rate 0.216644332887 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[2]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.318566371327 -toggle_rate 0.217604352087 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[3]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.320326406528 -toggle_rate 0.216964339287 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[4]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.316286325727 -toggle_rate 0.221204424088 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[5]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.311566231325 -toggle_rate 0.212484249685 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[6]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.319326386528 -toggle_rate 0.215844316886 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[7]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.313686273725 -toggle_rate 0.220004400088 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[8]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.315926318526 -toggle_rate 0.218164363287 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[9]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.305566111322 -toggle_rate 0.221124422488 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[0]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.467369347387 -toggle_rate 0.19960399208 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[10]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.459849196984 -toggle_rate 0.197123942479 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[11]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.455609112182 -toggle_rate 0.194403888078 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[12]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.455969119382 -toggle_rate 0.193683873677 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[13]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.456609132183 -toggle_rate 0.193283865677 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[14]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.456609132183 -toggle_rate 0.193283865677 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[15]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.456609132183 -toggle_rate 0.193283865677 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[16]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.456609132183 -toggle_rate 0.193283865677 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[17]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.456609132183 -toggle_rate 0.193283865677 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[18]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.456609132183 -toggle_rate 0.193283865677 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[19]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.456609132183 -toggle_rate 0.193283865677 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[1]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.516930338607 -toggle_rate 0.204604092082 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[2]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.481249624992 -toggle_rate 0.20096401928 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[3]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.47536950739 -toggle_rate 0.20072401448 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[4]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.526290525811 -toggle_rate 0.202204044081 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[5]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.477809556191 -toggle_rate 0.20008400168 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[6]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.472889457789 -toggle_rate 0.20072401448 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[7]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.467929358587 -toggle_rate 0.203044060881 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[8]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.470689413788 -toggle_rate 0.201684033681 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[9]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.467249344987 -toggle_rate 0.202164043281 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_en}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.734654693094 -toggle_rate 0.0612012240245 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_valid}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.734654693094 -toggle_rate 0.0612012240245 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_wr}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.32400648013 -toggle_rate 0.162003240065 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_start}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 4.0000800016e-05 -toggle_rate 8.0001600032e-05 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {reset}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 8.0001600032e-05 -toggle_rate 8.0001600032e-05 $_activity_port
}
unset _activity_port
