# Conv4x4 FPGA results

The corrected WPN16/NBITS=16 campaign for 8, 16, and 32 MACs is summarized in
[wpn16-8-16-32-nbits16-ae16c90e.md](wpn16-8-16-32-nbits16-ae16c90e.md).
All three variants now pass post-route functional golden simulation and have
P3F power reports. The 8- and 16-MAC points close timing at 317 MHz; 32 MACs
misses by 9 ps (one endpoint), so it is not a timing-closed 317 MHz result.
The original campaign is preserved in
[wpn16-8-16-32-nbits16-1de1640e.md](wpn16-8-16-32-nbits16-1de1640e.md) as
historical evidence of the previous inverse-accumulation bug.

The separate IFN9 m12 result already passes post-route golden and closes
317 MHz; see [ifn9-explore-149bd5be.md](../../../conv3x3/fpga_zcu104/results/ifn9-explore-149bd5be.md).
WPN16 m12 is not a supported point in the current 4x4 schedule: its MAC count
must cover whole 16-row Hadamard batches. Do not conflate IFN9 m12 with WPN16
m16.

The earlier capacity result for 32 replicated WPN16 m08 cores at NBITS=16 is
preserved in [wpn16-n32-capacity-a75f073.md](wpn16-n32-capacity-a75f073.md):
220 MHz passed post-route, while 250 MHz failed. This is a timing/capacity
result for the unpipelined core and is separate from the m16/m32 campaign.

The first feature-only transform-pipeline trial for 32 WPN16 m08 replicas is
preserved in [wpn16-n32-featurepipe-5dad37b9.md](wpn16-n32-featurepipe-5dad37b9.md).
It passed the RTL golden but failed the 317 MHz routed timing target. The
separate dual-barrier candidate is documented in
[wpn16-n32-pipeboth-317mhz-94eb5f85.md](wpn16-n32-pipeboth-317mhz-94eb5f85.md):
it passed the same 16-bit RTL golden and met 317 MHz post-route with WNS
`+0.043 ns`. Keep both records distinct. The dual-barrier result is OOC and
does not include replicated post-route functional simulation or power analysis.

The follow-up physical A/B experiment that forced replication of the
high-fanout transform-register enable is documented in
[wpn16-n32-enable-replication-317mhz.md](wpn16-n32-enable-replication-317mhz.md).
It improved WNS from `+0.043 ns` to `+0.062 ns` from a common post-place
checkpoint, with 311 additional FFs and no LUT/DSP change. This is a modest
OOC timing improvement; the critical path moved into the DSP/MAC datapath.

The subsequent DSP-internal-pipeline experiment is documented in
[wpn16-n32-dsp-pipeline-317mhz-9ea006cd.md](wpn16-n32-dsp-pipeline-317mhz-9ea006cd.md).
With the multiplier pipeline enabled, the standard Explore route closed at
317 MHz with `+0.124 ns` WNS. All 256 DSPs inferred `MREG`, but only 156
inferred `PREG`; the remaining critical path is the inverse/output-accumulate
logic after a registered DSP output. Forced enable replication did not improve
the result (`+0.123 ns`). No post-route functional simulation or power analysis
was run for this experiment.
