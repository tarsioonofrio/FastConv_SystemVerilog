# FPGA benchmark wrapper pilot

This isolated experiment keeps the Conv pilot RTL unchanged and replaces its
testbench memories with XPM memories intended to map to Zynq UltraScale+ BRAM.
It does not replace the published top-level pilot or its P0/P1/P2/P3F evidence.

## Block structure

```text
                   fpga_benchmark_top
  clk/reset/start/done/result_valid/result_ok (external top-level ports)
                         |
                 accelerator_core (Conv)
             p_input_*              p_output_*
                 |                       |
        address-range adapter      read/write adapter
          /             \                 |
 Input feature ROM   Weight ROM     Output simple-dual-port RAM
 3072 x 20 BRAM      144 x 20 BRAM       2700 x 20 BRAM
   read on clk-         read on clk-      write clk+, read clk-
```

The exact original interface contract is recorded in
[`docs/original_core_protocol.md`](docs/original_core_protocol.md). The core
has no input-read stall: its feature/weight stream must be ready at every
consuming rising edge. XPM block-memory reads are synchronous, so the adapter
uses the falling edge to make their data available before the core's next
rising-edge sample. This preserves the core's cycle count but leaves a
half-cycle timing path that must be checked in the 317 MHz implementation.
No extra full-cycle pipeline is inserted.

The core exposes one shared input/weight request port. Since the RTL reads
weights and features in mutually exclusive FSM states, a range decoder routes
each request to one of two single-port ROMs. The output memory uses a
simple-dual-port XPM: the core only reads or writes it in distinct FSM states,
so write-on-rising-edge and read-on-falling-edge ports are sufficient. The
output initialization image is all zeros; every output address is overwritten
by the first input-channel pass before the core reads it for cross-channel
accumulation. After the core asserts `done` (`p_end`), the wrapper scans the
2,700 final output words through the output BRAM read port and computes a
CRC-32/MPEG-2 signature. `result_valid` and `result_ok` expose the checker
result at the top level, making the calculated image functionally observable
without exporting memory buses. The CRC consumes all 20 bits of each word in
ascending address order, MSB first, with polynomial `04C11DB7`, init
`FFFFFFFF`, xorout `00000000`, and no reflection. Its expected value is
generated from canonical `const_feat_out` alongside the memory images and
recorded with the workload hash. A 32-bit signature is a compact functional
check, not a mathematical proof that every output bit matches. The optional
`rtl-fault` simulation mode flips one checker-input bit in the first scanned
word and must produce `result_valid=1, result_ok=0`; synthesis uses the default
fault-injection parameter value of zero.

The checker reuses the output BRAM read port only after `core_done`; it adds no
fanout to the core output datapath while the job runs. `done` remains the core
completion pulse. `result_valid` follows the 2,700-word readback and
`result_ok` remains the comparison result until reset. The wrapper accepts one
job after reset, matching the core's non-reentrant contract. Core-job latency
and the power-capture window end at `done`; checker/readback latency and power
are reported separately from the active-core job.

The feature and weight BRAM read enables are tied high to avoid a failing
half-cycle path from the core address/control decode into the BRAM enable pin.
The core only consumes the selected ROM data when its own input enable is
active. Both ROMs therefore perform reads during otherwise idle cycles; this
is included in implementation activity/power and is not a claim of minimum
memory power.

## Data provenance

Run `scripts/generate_memory_images.py` with the canonical generated package:

```bash
python3 wrapper/scripts/generate_memory_images.py \
  --pack-data ../../../../rtl/conv2x2/data/tcn4/sim/sim-032-3-3-normal/pack_data.sv \
  --out-dir wrapper/data
```

It verifies the package array lengths, splits its first 3072 feature words and
next 144 transformed weights into 20-bit XPM `.mem` images, initializes the
2700-word output BRAM to zero, derives the expected output CRC from the 2700
canonical `const_feat_out` values, and writes `memory_manifest.txt` with the
algorithm parameters and SHA-256 hashes. The package's final 81 raw spatial
weights remain unused, matching the current core's transformed-weight address
stream.

## Validation order

1. Run `scripts/launch_tmux.sh rtl <run-name>` to compile and run
   `tb/tb_fpga_wrapper.sv` against the XPM simulation source supplied by Vivado;
   require zero golden mismatches, 8100 writes, 2025 tile events, and job
   completion. This RTL/XPM-source test is distinct from the earlier local
   Verilator adapter smoke test, which used only a temporary behavioral
   approximation and is not final evidence.
2. Run `scripts/launch_tmux.sh implementation <run-name>` for the
   wrapper-specific Vivado implementation at XCZU7EV / 317 MHz. Inspect
   utilization to prove BRAM inference and confirm that the top-level ports
   are limited to `clk`, `reset`, `start`, `done`, `result_valid`, and
   `result_ok`. Keep package pins and I/O standards
   unspecified; this wrapper is a core/memory boundary study, not a board pinout.
3. Require nonnegative WNS at 317 MHz. In particular, review the half-cycle
   paths from BRAM read outputs to the rising-edge core inputs.
4. Export the post-route functional netlist, run Xcelium without SDF, verify
   `done`, `result_valid`, and `result_ok`, then capture/import SAIF and report
   power. Reuse the Xcelium UNISIM library compiled for the same Vivado release:

   ```bash
   scripts/launch_tmux.sh funcsim <run-name> <compiled-unisim-simlib-dir>
   scripts/launch_tmux.sh power <run-name>
   ```

   The funcsim SAIF window starts at `start` and ends at the edge that commits
   the final core write (`capture_done`). It excludes the subsequent BRAM
   readback/CRC scan. The wrapper's resources and timing include the checker,
   while the active-core SAIF does not. All long Vivado/Xcelium tasks run in
   tmux; poll with `tmux has-session` and read the per-run
   `reports/<run-name>/tmux.log` instead of launching another copy.

All long Paxos jobs must run under `tmux`. The implementation results below
are diagnostic only until the wrapper closes timing at the target frequency.

## Current implementation result (not accepted at 317 MHz)

The functionally passing BRAM version preserves the core and maps 8 DSPs,
2,340 LUTs, 1,330 FFs, four RAMB36, and three RAMB18, with six top-level I/Os.
However, its routed WNS is -0.553 ns at a 3.155 ns clock period. The worst
path is from the core output-address logic to the falling-edge output-BRAM
read address, which has only a half-cycle setup budget. Therefore this DCP is
not a timing-closed 317 MHz benchmark and has not been used for P3F power.

Two diagnostics confirmed the interface trade-off. Moving the output BRAM
read to the rising edge and applying a simple valid alternation did not
preserve the golden outputs (2,009 mismatches). A distributed asynchronous
output RAM restored the core's combinational-read contract and passed the
golden/CRC check, but used 1,032 LUTRAMs and routed at -2.990 ns WNS. It is not
an acceptable replacement for the requested output BRAM. The wrapper
therefore remains an experiment: the unchanged core's combinational
output-memory read protocol has not yet been reconciled with a 317 MHz
synchronous output BRAM implementation.
