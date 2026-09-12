rm -rf genus.cmd*
rm -rf genus.log*

source /usr/share/Modules/init/bash
module purge  > /dev/null 2>&1
module use /soft64/modulefiles
module load cadence/genus/211 > /dev/null 2>&1
genus -f power.tcl
