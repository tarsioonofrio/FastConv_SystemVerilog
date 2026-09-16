# Operation-count audit

The canonical package is a dense 2-D convolution workload, not a depthwise or
channel-wise convolution. The generated arrays have shapes
`feature=(1,3,32,32)` and `weights=(3,3,3,3)`, producing
`output=(1,3,30,30)`.

The reference generator's `sim.txt` reports 2,700 convolutions, 24,300
multiplications, and 21,600 additions. That report is formed as
`output_default.size * 9` and `output_default.size * 8`; it counts one spatial
3x3 kernel per output element and omits the three input-channel contributions.
It is therefore not the complete dense-job operation count.

The Python reference path explicitly loops over every output kernel and every
input channel, accumulating the channel results. The RTL does the same: its
input-channel counter visits all three input channels, and the output FSM reads
the partial result and adds it to the output value before writing the next
channel contribution.

For this job:

| quantity | derivation | value |
| --- | --- | ---: |
| output elements | `1 * 3 * 30 * 30` | 2,700 |
| input-channel/kernel contributions | `2,700 * 3` | 8,100 |
| multiplications | `8,100 * 9` | 72,900 |
| within-kernel additions | `8,100 * 8` | 64,800 |
| cross-channel additions | `2,700 * (3 - 1)` | 5,400 |
| literal additions | `64,800 + 5,400` | 70,200 |
| literal arithmetic operations | `72,900 + 70,200` | 143,100 |
| MAC-equivalent operations | `2 * 72,900` | **145,800** |

The benchmark uses the conventional accelerator definition MAC = 2 operations,
so `145800` is retained as the validated equivalent-operation count. The
generator's `24300` multiplication line is documented as an incomplete
single-channel spatial-kernel tally rather than treated as the dense job total.
