# Conv3x3 FPGA results

The [IFN9 multiplier-scaling RTL record](ifn9-multiplier-scaling-rtl.md)
contains local functional simulation results for 6, 12, and 18 MAC lanes. The
[IFN9 Explore + post-route phys-opt FPGA campaign](ifn9-explore-149bd5be.md)
records the first post-route FPGA characterization for all three lane counts,
including timing closure, functional simulation, SAIF mapping, and P3F power.
The [IFN9 m18 NetDelay_high implementation follow-up](ifn9-netdelay-high-231d0dcf.md)
closes timing at 317 MHz with the same RTL; it contains timing/utilization
evidence only, without a new post-route functional simulation or power run.
