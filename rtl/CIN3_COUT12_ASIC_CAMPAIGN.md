# Cin=3, Cout=12 ASIC power campaign

The existing Cin=3, Cout=3 datasets and synthesis results are retained. This campaign creates a separate config for each active architecture/MAC variant, with explicit channel overrides and a matching generated pack.

Common workload: image 32x32, Cin=3, Cout=12, seed=0, quantization=8 bits.

## Dataset packages

| Package | SHA-256 |
| --- | --- |
| `rtl/conv2x2/data/tcn4/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv` | a95dee46c651ed6e416f608b9b7c7efe7823a9041c7457e8ed3496bf11b63288 |
| `rtl/conv3x3/data/ifn9/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv` | 1e638d14ba92598022423d791c31235d6e4d1186dd5c5cbf9f7e7638549dab56 |
| `rtl/conv3x3/data/tcn9/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv` | 292ebc47431ca422c6251087a54818af2da621ded10ba680268c7049d70a3145 |
| `rtl/conv4x4/data/tcn16/sim/sim-032-3-12-normal-trunc-frac6-nbits20/pack_data.sv` | 1ffee2ed86741b466b0a2d319a58610746ce07160c17de76039f9b5916682e96 |
| `rtl/conv4x4/data/tcn16/sim/sim-032-3-12-normal-trunc-nbits20/pack_data.sv` | 1d720022b9afa0f5f8afc0be3dcfcc0f4a54dc194a48f7eb5d5baa1d7de737c5 |
| `rtl/conv4x4/data/wpn16/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv` | 55a13381981b4d570f6226615f4f8a0334047717a4c6ce1aecdb887f3851a393 |

## New ASIC configurations

| Config | Dataset | NBITS | pack_data SHA-256 |
| --- | --- | ---: | --- |
| `rtl/conv2x2/synthesis/conv-i24-h13-t08-o4-m04-stream08-prefetch8-rowconst4-trunc-column-nbits16-cin3-cout12` | `rtl/conv2x2/data/tcn4/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv` | 16 | `a95dee46c651ed6e416f608b9b7c7efe7823a9041c7457e8ed3496bf11b63288` |
| `rtl/conv2x2/synthesis/conv-i24-h13-t08-o4-m08-stream08-prefetch8-rowconst4-trunc-column-nbits16-cin3-cout12` | `rtl/conv2x2/data/tcn4/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv` | 16 | `a95dee46c651ed6e416f608b9b7c7efe7823a9041c7457e8ed3496bf11b63288` |
| `rtl/conv3x3/synthesis/conv-ifn9-i35-h15-t12-o9-m06-stream12-prefetch10-rowconst6-trunc-column-nbits16-cin3-cout12` | `rtl/conv3x3/data/ifn9/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv` | 16 | `1e638d14ba92598022423d791c31235d6e4d1186dd5c5cbf9f7e7638549dab56` |
| `rtl/conv3x3/synthesis/conv-ifn9-i35-h21-t24-o9-m12-stream12-prefetch10-rowconst6-trunc-column-nbits16-cin3-cout12` | `rtl/conv3x3/data/ifn9/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv` | 16 | `1e638d14ba92598022423d791c31235d6e4d1186dd5c5cbf9f7e7638549dab56` |
| `rtl/conv3x3/synthesis/conv-ifn9-i35-h27-t36-o9-m18-stream12-prefetch10-rowconst6-trunc-column-nbits16-cin3-cout12` | `rtl/conv3x3/data/ifn9/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv` | 16 | `1e638d14ba92598022423d791c31235d6e4d1186dd5c5cbf9f7e7638549dab56` |
| `rtl/conv3x3/synthesis/conv-ifn9-i40-h15-t12-o9-m06-stream12-prefetch15-rowconst6-trunc-column-nbits16-cin3-cout12` | `rtl/conv3x3/data/ifn9/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv` | 16 | `1e638d14ba92598022423d791c31235d6e4d1186dd5c5cbf9f7e7638549dab56` |
| `rtl/conv3x3/synthesis/conv-ifn9-i40-h21-t24-o9-m12-stream12-prefetch15-rowconst6-trunc-column-nbits16-cin3-cout12` | `rtl/conv3x3/data/ifn9/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv` | 16 | `1e638d14ba92598022423d791c31235d6e4d1186dd5c5cbf9f7e7638549dab56` |
| `rtl/conv3x3/synthesis/conv-ifn9-i40-h27-t36-o9-m18-stream12-prefetch15-rowconst6-trunc-column-nbits16-cin3-cout12` | `rtl/conv3x3/data/ifn9/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv` | 16 | `1e638d14ba92598022423d791c31235d6e4d1186dd5c5cbf9f7e7638549dab56` |
| `rtl/conv3x3/synthesis/conv-tcn9-i35-h14-t10-o9-m05-stream10-prefetch10-rowconst5-trunc-column-nbits16-cin3-cout12` | `rtl/conv3x3/data/tcn9/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv` | 16 | `292ebc47431ca422c6251087a54818af2da621ded10ba680268c7049d70a3145` |
| `rtl/conv3x3/synthesis/conv-tcn9-i40-h14-t10-o9-m05-stream10-prefetch15-rowconst5-trunc-column-nbits16-cin3-cout12` | `rtl/conv3x3/data/tcn9/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv` | 16 | `292ebc47431ca422c6251087a54818af2da621ded10ba680268c7049d70a3145` |
| `rtl/conv4x4/synthesis/conv-tcn16-i60-h15-t12-o16-m06-stream12-prefetch24-pretransformed-column-cin3-cout12` | `rtl/conv4x4/data/tcn16/sim/sim-032-3-12-normal-trunc-nbits20/pack_data.sv` | 20 | `1d720022b9afa0f5f8afc0be3dcfcc0f4a54dc194a48f7eb5d5baa1d7de737c5` |
| `rtl/conv4x4/synthesis/conv-tcn16-i60-h15-t12-o16-m06-stream12-prefetch24-rowconst6-trunc-frac6-column-cin3-cout12` | `rtl/conv4x4/data/tcn16/sim/sim-032-3-12-normal-trunc-frac6-nbits20/pack_data.sv` | 20 | `1ffee2ed86741b466b0a2d319a58610746ce07160c17de76039f9b5916682e96` |
| `rtl/conv4x4/synthesis/conv-tcn16-i60-h21-t24-o16-m12-stream12-prefetch24-pretransformed-column-cin3-cout12` | `rtl/conv4x4/data/tcn16/sim/sim-032-3-12-normal-trunc-nbits20/pack_data.sv` | 20 | `1d720022b9afa0f5f8afc0be3dcfcc0f4a54dc194a48f7eb5d5baa1d7de737c5` |
| `rtl/conv4x4/synthesis/conv-tcn16-i60-h21-t24-o16-m12-stream12-prefetch24-rowconst6-trunc-frac6-column-cin3-cout12` | `rtl/conv4x4/data/tcn16/sim/sim-032-3-12-normal-trunc-frac6-nbits20/pack_data.sv` | 20 | `1ffee2ed86741b466b0a2d319a58610746ce07160c17de76039f9b5916682e96` |
| `rtl/conv4x4/synthesis/conv-tcn16-i60-h27-t36-o16-m18-stream12-prefetch24-pretransformed-column-cin3-cout12` | `rtl/conv4x4/data/tcn16/sim/sim-032-3-12-normal-trunc-nbits20/pack_data.sv` | 20 | `1d720022b9afa0f5f8afc0be3dcfcc0f4a54dc194a48f7eb5d5baa1d7de737c5` |
| `rtl/conv4x4/synthesis/conv-tcn16-i60-h27-t36-o16-m18-stream12-prefetch24-rowconst6-trunc-frac6-column-cin3-cout12` | `rtl/conv4x4/data/tcn16/sim/sim-032-3-12-normal-trunc-frac6-nbits20/pack_data.sv` | 20 | `1ffee2ed86741b466b0a2d319a58610746ce07160c17de76039f9b5916682e96` |
| `rtl/conv4x4/synthesis/conv-wpn16-i60-h17-t16-o16-m08-stream16-prefetch24-rowconst8-trunc-column-nbits16-cin3-cout12` | `rtl/conv4x4/data/wpn16/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv` | 16 | `55a13381981b4d570f6226615f4f8a0334047717a4c6ce1aecdb887f3851a393` |
| `rtl/conv4x4/synthesis/conv-wpn16-i60-h25-t32-o16-m16-stream16-prefetch24-rowconst8-trunc-column-nbits16-cin3-cout12` | `rtl/conv4x4/data/wpn16/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv` | 16 | `55a13381981b4d570f6226615f4f8a0334047717a4c6ce1aecdb887f3851a393` |
| `rtl/conv4x4/synthesis/conv-wpn16-i60-h41-t64-o16-m32-stream16-prefetch24-rowconst8-trunc-column-nbits16-cin3-cout12` | `rtl/conv4x4/data/wpn16/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv` | 16 | `55a13381981b4d570f6226615f4f8a0334047717a4c6ce1aecdb887f3851a393` |

Run the full logical synthesis, gate-level SDF simulation, and Joules power flow in tmux with `scripts/run_cin3_cout12_asic_campaign.sh`.
