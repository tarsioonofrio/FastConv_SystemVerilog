cd ./sintese/
module purge
module load genus > /dev/null 2>&1
genus -f run_logical_synthesis.tcl

cd ../simSDF/
module purge
module load xcelium > /dev/null 2>&1
bash xrun.sh

cd ../sintese/
module purge  > /dev/null 2>&1
module load ddi
genus -f run_power.tcl
