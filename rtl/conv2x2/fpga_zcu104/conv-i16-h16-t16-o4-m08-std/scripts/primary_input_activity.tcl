# Generated P2 activity: primary inputs and controls only.
# Clock is constrained by XDC; outputs are observation-only.
# Apply after reset_switching_activity -all and before report_power.
set _activity_port [get_ports -quiet {p_input_addr[0]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.368395458486 -toggle_rate 0.736790916971 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[10]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.341290145252 -toggle_rate 0.0115017865827 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[11]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.341290145252 -toggle_rate 0.00414402604816 $_activity_port
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
  set_switching_activity -static_probability 0.490940228767 -toggle_rate 0.373723491976 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[2]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.491320802588 -toggle_rate 0.175063957545 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[3]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.491320802588 -toggle_rate 0.0753536165084 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[4]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.491024800727 -toggle_rate 0.0251178721695 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[5]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.539315389982 -toggle_rate 0.183013721801 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[6]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.499355138804 -toggle_rate 0.0916760048206 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[7]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.503076305051 -toggle_rate 0.0458380024103 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[8]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.50235744339 -toggle_rate 0.022834429245 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[9]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.50235744339 -toggle_rate 0.0114172146225 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[0]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.37042518553 -toggle_rate 0.407805991923 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[10]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.377909804004 -toggle_rate 0.417954627143 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[11]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.377909804004 -toggle_rate 0.417954627143 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[12]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.377909804004 -toggle_rate 0.417954627143 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[13]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.377909804004 -toggle_rate 0.417954627143 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[14]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.377909804004 -toggle_rate 0.417954627143 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[15]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.377909804004 -toggle_rate 0.417954627143 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[16]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.377909804004 -toggle_rate 0.417954627143 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[17]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.377909804004 -toggle_rate 0.417954627143 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[18]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.377909804004 -toggle_rate 0.417954627143 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[19]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.377909804004 -toggle_rate 0.417954627143 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[1]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.371101761211 -toggle_rate 0.399940799628 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[2]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.361122269911 -toggle_rate 0.424804955917 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[3]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.367465166924 -toggle_rate 0.418123771064 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[4]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.372370340614 -toggle_rate 0.412711165613 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[5]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.369368036028 -toggle_rate 0.407636848003 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[6]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.373596634036 -toggle_rate 0.417447195382 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[7]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.367338308984 -toggle_rate 0.409920290928 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[8]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.368014884665 -toggle_rate 0.408989999366 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[9]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.3755840751 -toggle_rate 0.417616339303 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_en}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.736833202952 -toggle_rate 0.171342791298 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_valid}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.736833202952 -toggle_rate 0.171342791298 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_start}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 4.22859800833e-05 -toggle_rate 8.45719601666e-05 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {reset}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0 -toggle_rate 0 $_activity_port
}
unset _activity_port
