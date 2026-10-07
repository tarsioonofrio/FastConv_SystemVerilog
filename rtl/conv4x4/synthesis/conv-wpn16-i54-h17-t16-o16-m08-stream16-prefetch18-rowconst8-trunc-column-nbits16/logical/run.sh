rm -rf genus.cmd*
rm -rf genus.log*

module purge
module load cadence/genus/211 > /dev/null 2>&1
genus -f logical_synthesis.tcl
