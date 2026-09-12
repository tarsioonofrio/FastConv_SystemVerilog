rm -rf genus.cmd*
rm -rf genus.log*

module purge
module load genus > /dev/null 2>&1
genus -f logical_synthesis.tcl
