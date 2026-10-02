# Conv4x4 FPGA results

The WPN16 m16/m32 campaign is still under review. Do not present power-derived
efficiency for m32 until its post-route functional golden simulation passes.
See the campaign-specific result summary added after diagnosing the m32
mismatch.

The earlier capacity result for 32 replicated WPN16 m08 cores at NBITS=16 is
preserved in [wpn16-n32-capacity-a75f073.md](wpn16-n32-capacity-a75f073.md):
220 MHz passed post-route, while 250 MHz failed. This is a timing/capacity
result for the unpipelined core and is separate from the m16/m32 campaign.

The first feature-only transform-pipeline trial for 32 WPN16 m08 replicas is
preserved in [wpn16-n32-featurepipe-5dad37b9.md](wpn16-n32-featurepipe-5dad37b9.md).
It passed the RTL golden but failed the 317 MHz routed timing target. A second
candidate that pipelines both feature and weight transform axes is being tested
separately; do not conflate its status with the feature-only trial.
