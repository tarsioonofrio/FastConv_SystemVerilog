# OOC characterization of the frozen Conv pilot

This is a separate IP-level experiment based on the published BRAM-wrapper
diagnostic branch. It does not replace or edit that experiment, the frozen
`Conv` RTL, or the original P0/P1/P2/P3F reports. The wrapper/BRAM branch
records that the current core expects a combinational memory response and that
the proposed synchronous-BRAM wrapper did not close timing at 317 MHz.

The OOC top is the original parameterized `Conv` module from the pilot's
`rtl_manifest.txt`. Vivado 2023.2 synthesizes it with
`synth_design -mode out_of_context`, so logical IP ports remain at the module
boundary without package I/O buffers. The script rejects a routed result if
IBUF/OBUF/IOBUF primitives are present. This is an IP-level characterization,
not a complete FPGA system or board power estimate.

## Timing contract

The IP's internal clock remains 317 MHz (`3.154574 ns`). The real surrounding
system has not yet been selected, so this experiment declares a transparent
reference assumption of zero external max/min delay on all synchronous data
inputs and outputs. Reset is asynchronous and is separately exempted from the
synchronous data-path closure calculation. The XDC and implementation reports
preserve these assumptions; do not interpret this run as a board-level Fmax.

The implementation emits separate reports for:

- register-to-register paths;
- input-port-to-register paths;
- register-to-output-port paths;
- overall timing, including unconstrained-path diagnostics.

The external combinational-memory response is provided by the canonical
functional testbench. OOC static timing does not model the board/system path
from a core address output through an external memory and back into a core data
input. That remains a boundary limitation and must be revisited when the final
FPGA interface is defined.

## Reproduction

From the repository root, the OOC implementation runner is intended to be
invoked inside a `tmux` session on the Paxos after loading Vivado 2023.2:

```bash
bash rtl/conv2x2/fpga_zcu104/conv-i16-h16-t16-o4-m08-std/ooc/scripts/run_impl_tmux.sh 317mhz
```

The functional Xcelium runner likewise requires `tmux`, the previously
compiled Vivado 2023.2 UNISIM libraries, and the routed OOC functional netlist:

```bash
bash rtl/conv2x2/fpga_zcu104/conv-i16-h16-t16-o4-m08-std/ooc/scripts/run_funcsim_xcelium.sh 317mhz /path/to/unisim_xcelium
```

It reuses the pilot's GSR-safe testbench and canonical `pack_data.sv` with the
original combinational-memory semantics. It performs two deterministic
functional captures (internal DUT scope and top-level ports), verifies 8,100
writes, 2,025 tiles and zero golden mismatches, and emits SAIF only from
`p_start` through `p_end`. It does not emit VCD, FST, or SDF.

After both SAIF captures pass, run the power import in the same Vivado 2023.2
environment:

```bash
vivado -mode batch -source rtl/conv2x2/fpga_zcu104/conv-i16-h16-t16-o4-m08-std/ooc/scripts/power_saif.tcl -tclargs 317mhz
```

The generated DCP, functional netlist, mapping reports and power reports are
stored under `ooc/reports/317mhz/`. Do not calculate IP/system GOPS/W or
energy from an OOC report until the report's power categories and static-power
semantics have been inspected and documented.

## Completed pilot result

The first OOC campaign completed on Paxos from commit
`52fb8b8342d47f3c586609f8fcd8dfab59207923`. The measured implementation,
functional-simulation, SAIF and power results, including their limitations,
are recorded in [results/summary_317mhz.md](results/summary_317mhz.md). Raw
artifacts are preserved under `reports/317mhz/`.

The result is an IP-level pilot, not a board-level estimate. In particular,
OOC retains 101 logical top-level interface bits in `report_io`, while the
post-route cell audit finds zero IBUF/OBUF/IOBUF primitives. Boundary timing
is reported under explicit zero-delay assumptions, but route warnings state
that timing to/from ports is not accurate without `HD.PARTPIN_LOCS`; only the
internal register-to-register result is used as the timing-closure evidence.
