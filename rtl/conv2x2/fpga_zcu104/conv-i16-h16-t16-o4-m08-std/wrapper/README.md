# FPGA benchmark wrapper pilot

This isolated experiment keeps the Conv pilot RTL unchanged and replaces its
testbench memories with XPM memories intended to map to Zynq UltraScale+ BRAM.
It does not replace the published top-level pilot or its P0/P1/P2/P3F evidence.

## Block structure

```text
                   fpga_benchmark_top
  clk/reset/start/done (the only external top-level ports)
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
accumulation.

## Data provenance

Run `scripts/generate_memory_images.py` with the canonical generated package:

```bash
python3 wrapper/scripts/generate_memory_images.py \
  --pack-data ../../../../rtl/conv2x2/data/tcn4/sim/sim-032-3-3-normal/pack_data.sv \
  --out-dir wrapper/data
```

It verifies the package array length, splits its first 3072 feature words and
next 144 transformed weights into 20-bit XPM `.mem` images, initializes the
2700-word output BRAM to zero, and writes `memory_manifest.txt` with SHA-256
hashes. The package's final 81 raw spatial weights remain unused, matching the
current core's transformed-weight address stream.

## Validation order

1. Run `scripts/launch_tmux.sh rtl <run-name>` to compile and run
   `tb/tb_fpga_wrapper.sv` against the XPM simulation source supplied by Vivado;
   require zero golden mismatches, 8100 writes, 2025 tile events, and job
   completion. This RTL/XPM-source test is distinct from the earlier local
   Verilator adapter smoke test, which used only a temporary behavioral
   approximation and is not final evidence.
2. Run `scripts/launch_tmux.sh implementation <run-name>` for the
   wrapper-specific Vivado implementation at XCZU7EV / 317 MHz. Inspect
   utilization to prove BRAM inference and confirm there are
   only four top-level I/O ports. Keep package pins and I/O standards
   unspecified; this wrapper is a core/memory boundary study, not a board pinout.
3. Require nonnegative WNS at 317 MHz. In particular, review the half-cycle
   paths from BRAM read outputs to the rising-edge core inputs.
4. Export the post-route functional netlist, run Xcelium without SDF, verify
   the same golden/workload, then capture/import SAIF and report power. All
   long Vivado/Xcelium tasks run in tmux; poll with `tmux has-session` and read
   the per-run `reports/<run-name>/tmux.log` rather than launching a second
   copy.

All long Paxos jobs must run under `tmux`. This experiment intentionally stops
before a final commit/push; present its results for review first.
