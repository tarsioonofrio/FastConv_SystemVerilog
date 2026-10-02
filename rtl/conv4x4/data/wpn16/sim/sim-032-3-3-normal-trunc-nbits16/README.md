# WPN16 truncated workload, 16-bit package

This package keeps the canonical WPN16 truncated workload values and golden
outputs while declaring every packed sample as signed 16-bit data. It was
derived mechanically from `sim-032-3-3-normal-trunc/pack_data.sv`; no sample or
golden value was recalculated. All arrays fit the signed 16-bit range:

| Array | Minimum | Maximum |
| --- | ---: | ---: |
| `const_data` | -797 | 973 |
| `const_weight` | -466 | 766 |
| `const_feat_in` | -797 | 811 |
| `const_feat_out_batch` | -4978 | 5689 |
| `const_feat_out` | -4978 | 5689 |

The width-narrowed package passed the WPN16 8-MAC RTL testbench with
`NBITS=16`: 2,304 output-column write beats, 9,216 physical words, 2,700 final
outputs, and zero golden mismatches.

Reproduce the package conversion from the repository root with:

```bash
sed -e 's/NBITS = 20/NBITS = 16/g' \
    -e 's/WEIGHT_NBITS = 20/WEIGHT_NBITS = 16/g' \
    -e 's/\[19:0\]/[15:0]/g' \
    rtl/conv4x4/data/wpn16/sim/sim-032-3-3-normal-trunc/pack_data.sv \
    > rtl/conv4x4/data/wpn16/sim/sim-032-3-3-normal-trunc-nbits16/pack_data.sv
```

Original package SHA-256:
`89f6b53f0411b106021faae0586b0209d0a482af5706f0c94e923802ac63374e`

16-bit package SHA-256:
`2bfeb5065993f271d69e62a66a072a0baabbdbec9665117a19c957382baf77b0`
