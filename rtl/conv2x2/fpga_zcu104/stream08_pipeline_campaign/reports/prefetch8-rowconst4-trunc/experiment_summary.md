# `prefetch8-rowconst4-trunc` FPGA experiment

## Setup

- Source commit: `a37f1df2ec065b408ba3915d028628f193746f59`
- Rounded baseline report commit: `49e2a22b3bb5476625397c7943d3f507714154e2`
- Host: `paxos.inf.pucrs.br`
- Tool: Vivado 2023.2
- Part: `xczu7ev-ffvc1156-2-e`
- Clock target: 317 MHz; the 3.154574 ns XDC period is rounded by Vivado to
  3.155 ns at 1 ps resolution.
- Workload package SHA-256:
  `3ced5c4527374898e1f8d65c275403e1366e2bb09f466542915656b263356da0`

The source was transferred directly from the local checkout to an isolated
temporary clone on Paxos. The pre-existing persistent Paxos checkout was left
untouched. Vivado synthesis, optimization, placement, physical optimization,
and routing produced a routed DCP and timing/utilization reports. The run was
launched in `tmux`.

## RTL functional check

The truncating variant completed the canonical workload with 2,025 tiles,
8,100 writes, and 23,774 cycles. It produced **2,473 mismatches among the
2,700 final outputs** against the rounded reference golden. This is an
intentional numerical change, not a bit-exact implementation. It must not be
treated as a functionally approved replacement.

## Implementation result

| Variant | LUT | FF | DSP | WNS @317 MHz | TNS | Failing endpoints |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Existing `prefetch8-rowconst4` | 4,416 | 1,457 | 8 | -1.330 ns | -176.073 ns | 205 |
| `prefetch8-rowconst4-trunc` | 2,949 | 1,409 | 8 | +0.009 ns | 0.000 ns | 0 |

The existing rounded design's worst path was
`r_weight_spatial_reg[2][1]` to `r_input_weight_reg[1][6]`, with 4.724 ns data
delay and 17 logic levels. In the truncating implementation, that path is no
longer critical. The new worst path is
`r_transform_feature_reg_reg[3][9]` to
`r_inverse_partial_current_reg[1][14]`: 3.030 ns, 10 logic levels, of which
2.132 ns is logic and 0.898 ns is routing. The 9 ps positive slack is a very
marginal timing pass, not meaningful margin for a robust target.

The truncating implementation reduces total LUTs by 1,467 (about 33.2%) and
FFs by 48 (about 3.3%), with the same eight DSPs.

## Interpretation and power status

Removing the rounding logic substantially shortens the weight-transform path
and reduces LUT use, but changes the numerical result for this workload. No
P3F SAIF-based power result was generated: activity from this non-golden
execution would not represent the validated workload, so power/energy metrics
are intentionally withheld.

The routed checkpoint SHA-256 is
`a869fcde6d673827a548db41ed92ab8d52e37875ffdd4a10324066bd8eb6e450`.
