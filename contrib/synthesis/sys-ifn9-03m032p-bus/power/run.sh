rm -rf genus.cmd*
rm -rf genus.log*

module purge  > /dev/null 2>&1
module load ddi
genus -f power.tcl
