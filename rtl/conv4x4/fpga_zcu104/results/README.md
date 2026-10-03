# Conv4x4 FPGA results

The latest complete WPN16/NBITS=16 campaign for 8, 16, and 32 MACs is
summarized in [wpn16-8-16-32-nbits16-1de1640e.md](wpn16-8-16-32-nbits16-1de1640e.md).
Only the 8-MAC implementation passed post-route functional golden simulation
and has valid P3F power. The 16-MAC implementation met timing with zero rounded
slack but failed all final golden comparisons; the 32-MAC implementation also
failed timing. Do not use their captured SAIF files for power or derive
efficiency from their vectorless estimates.

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
