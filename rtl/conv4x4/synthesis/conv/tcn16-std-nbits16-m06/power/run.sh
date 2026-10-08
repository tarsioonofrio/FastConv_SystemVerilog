rm -rf genus.cmd*
rm -rf genus.log*

module purge  > /dev/null 2>&1
module use /soft64/modulefiles
module load cadence/genus/211
genus -f power.tcl
