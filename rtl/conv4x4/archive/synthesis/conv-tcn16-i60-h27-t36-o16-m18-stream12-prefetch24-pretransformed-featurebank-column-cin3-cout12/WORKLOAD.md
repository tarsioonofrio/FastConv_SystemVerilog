# ASIC workload: Cin=3, Cout=12

Source RTL: `rtl/conv4x4/archive/tcn16-pretransformed/conv-tcn16-i60-h27-t36-o16-m18-stream12-prefetch24-pretransformed-featurebank-column.sv`.

Workload package: `rtl/conv4x4/data/tcn16/sim/sim-032-3-12-normal-trunc-nbits20/pack_data.sv`.

Top overrides: `NBITS=20`, `N_CHANNEL_IN=3`, `N_CHANNEL_OUT=12`.

This is the integer pretransformed-weight and reused-feature-bank variant. It loads the floor-truncated scale-576 transformed weights as 20-bit integers, with no additional fractional weight bits. It computes and captures all 36 input-feature transform values together in one cycle. The 18 MAC lanes read the active feature batch from the front of `r_transform_feature_bank` and the weight batch directly from `r_pretransformed_weight`; there are no separate 18-word active feature or weight banks. During Hadamard, unprocessed features shift toward the bank front and each computed product batch is committed to its tail. The inverse consumes the previous registered tail batch while the next Hadamard batch runs, so there is no separate `r_hadamard_product_reg`. Once the current tile's feature transform is captured, the four new input columns are prefetched directly into their destination positions in `r_input_feat`, so there is no separate 24-word prefetch-data bank. This variant has no rowconst weight transform. It is kept separate from the frac6 and online rowconst variants so each result has matching RTL and package provenance. The power flow must be rerun against the current source revision before its results are used; the interrupted flow artifacts were generated from the preceding RTL revision. Run the full flow inside tmux using the configuration directory basename.

The five data-register banks contain 140 words total (2,800 bits at `NBITS=20`):

| Bank | Words | Role |
| --- | ---: | --- |
| `r_input_feat` | 36 | Input tile; also receives the next tile's prefetched columns directly |
| `r_pretransformed_weight` | 36 | Full transformed-weight tile |
| `r_transform_feature_bank` | 36 | Feature transform, then reused in place for Hadamard products |
| `r_output_write` | 16 | Output accumulation and write data |
| `r_output_read` | 16 | Output readback for accumulation |

This count excludes FSM, address, counter, phase, and valid/control registers.
