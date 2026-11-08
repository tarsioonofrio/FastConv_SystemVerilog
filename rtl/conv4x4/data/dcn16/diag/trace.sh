# diagnóstico: traço por ciclo das portas do DUT no RTL e na netlist com atraso zero
set -u
c=$1; out=$2; R=$PWD; S=rtl/conv4x4/synthesis; C=$R/$S/$c; SPY=$3
module load xcelium/2303 > /dev/null 2>&1
val() { grep -oP "^$1=\K.*" "$C/top-parameters.txt"; }
files=$(grep -v '^$' "$C/list-file.txt" | sed "s|^|$R/|")
defs=$(grep -v -e '^$' -e ASIC_CAPTURE_SHM "$C/list-define.txt" | tr '\n' ' ')
TB=$R/$(cat "$C/testbench-file.txt")
w=$(mktemp -d); cd "$w"
xrun -sv -64bit -q -smartorder -top tb_stream_column -top spy -access +rw -timescale 1ns/1ps \
  -defparam tb_stream_column.WEIGHT_FRAC_BITS=$(val WEIGHT_FRAC_BITS) -defparam tb_stream_column.EXTRA_FRAC_BITS=$(val EXTRA_FRAC_BITS) \
  $files "$TB" "$SPY" $defs -run -exit > rtl.log 2>&1
mv trace.txt "$out.rtl.txt"; rm -rf xcelium.d
RTLTOP=$(awk 'NF {print $1; exit}' "$C/rtl-top-file.txt")
gfiles=$(grep -v -e '^$' -e "^$RTLTOP\$" "$C/list-file.txt" | sed "s|^|$R/|")
LIB=/pdk/tsmc/PDK28/PDK_TSMC28_bv/tcbn28hpcplusbwp30p140_190a/TSMCHOME/digital/Front_End/verilog/tcbn28hpcplusbwp30p140_110a/tcbn28hpcplusbwp30p140.v
xrun -smartorder -top tb_stream_column -top spy -access +rw -timescale 1ns/1ps -nospecify -notimingchecks $LIB \
  $gfiles "$TB" "$SPY" "$C/logical/results/gate_level/Conv_logic_mapped.v" $defs -define GATE_LEVEL -define XRUN -run -exit > gate.log 2>&1
mv trace.txt "$out.gate.txt"
grep -h "passed\|ERROR" rtl.log gate.log | head -3
cd /; rm -rf "$w"; echo TRACEDONE
