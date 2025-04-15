cd $1
DATA=data/sim/file-032
DATA=$DATA/data.sv vsim -c -do sim.do
cp sim_summary.txt $DATA/
DATA=data/sim/file-064
DATA=$DATA/data.sv vsim -c -do sim.do
cp sim_summary.txt $DATA/
DATA=data/sim/file-128
DATA=$DATA/data.sv vsim -c -do sim.do
cp sim_summary.txt $DATA/
DATA=data/sim/file-256
DATA=$DATA/data.sv vsim -c -do sim.do
cp sim_summary.txt $DATA/
DATA=data/sim/file-512
DATA=$DATA/data.sv sim -c -do sim.do
cp sim_summary.txt $DATA/
