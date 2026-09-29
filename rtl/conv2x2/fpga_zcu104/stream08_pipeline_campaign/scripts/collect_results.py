#!/usr/bin/env python3
"""Collect utilization, timing, functional simulation, and power reports."""

from __future__ import annotations

import argparse
import csv
import re
from pathlib import Path

RUNS = ("rowconst4", "wstream4", "prefetch4-rowconst4", "prefetch4", "prefetch8-rowconst4")
OPS_PER_JOB = 145800
FREQ_MHZ = 317.0


def read(path: Path) -> str:
    if not path.is_file():
        raise SystemExit(f"missing report: {path}")
    return path.read_text(errors="replace")


def parse_power(path: Path) -> dict[str, float | str]:
    text = read(path)

    def cell(label: str) -> float:
        match = re.search(rf"^\|\s*{re.escape(label)}\s*\|\s*([0-9.]+)", text, re.M)
        return float(match.group(1)) if match else 0.0

    confidence = re.search(r"^\|\s*Confidence Level\s*\|\s*([^|]+)", text, re.M)
    coverage = re.search(r"^\|\s*Design Nets Matched\s*\|\s*[^()]*\((\d+)/(\d+)\)", text, re.M)
    return {
        "total_w": cell("Total On-Chip Power (W)"),
        "dynamic_w": cell("Dynamic (W)"),
        "static_w": cell("Device Static (W)"),
        "clock_w": cell("Clocks"),
        "logic_w": cell("CLB Logic"),
        "signals_w": cell("Signals"),
        "dsp_w": cell("DSPs"),
        "bram_w": cell("Block RAM"),
        "io_w": cell("I/O"),
        "confidence": confidence.group(1).strip() if confidence else "unknown",
        "matched": int(coverage.group(1)) if coverage else 0,
        "nets": int(coverage.group(2)) if coverage else 0,
    }


def collect(bench: Path, name: str) -> dict:
    root = bench / "reports" / name
    util = read(root / "utilization.rpt")
    row = next((line for line in util.splitlines() if re.match(r"^\|\s*Conv\s+\|\s*\(top\)", line)), None)
    if not row:
        raise ValueError(f"Conv utilization row missing: {root}")
    cells = [item.strip() for item in row.strip().strip("|").split("|")]
    timing = read(root / "timing_summary.rpt")
    timing_section = timing[timing.find("Design Timing Summary"):]
    match = re.search(r"^\s*(-?[0-9.]+)\s+(-?[0-9.]+)\s+\d+\s+\d+", timing_section, re.M)
    if not match:
        raise ValueError(f"WNS/TNS missing: {root}")
    log = read(root / "dut" / "xrun.log")
    sim = re.search(r"POWER_RESULT PASS writes=(\d+) final_words=(\d+) mismatches=(\d+) active_cycles=(\d+)", log)
    if not sim:
        raise ValueError(f"functional result missing: {root}")
    writes, output_words, mismatches, cycles = map(int, sim.groups())
    p0_typ = parse_power(root / "power_vectorless_typical.rpt")
    p0_max = parse_power(root / "power_vectorless_maximum.rpt")
    p3_typ = parse_power(root / "power_p3f_typical.rpt")
    p3_max = parse_power(root / "power_p3f_maximum.rpt")
    gops = OPS_PER_JOB * FREQ_MHZ / (cycles * 1000.0)
    job_s = cycles / (FREQ_MHZ * 1e6)
    critical = re.search(
        r"Slack \((?:VIOLATED|MET)\).*?\n\s*Source:\s*(.*?)\n\s*Destination:\s*(.*?)\n"
        r".*?Data Path Delay:\s*([0-9.]+)ns.*?\n\s*Logic Levels:\s*([0-9]+)",
        timing, re.S,
    )
    return {
        "variant": name, "dsp": int(cells[10]), "lut": int(cells[2]), "ff": int(cells[6]),
        "ramb36": int(cells[7]), "ramb18": int(cells[8]), "wns_ns": float(match.group(1)),
        "tns_ns": float(match.group(2)), "timing_pass_317mhz": float(match.group(1)) >= 0 and float(match.group(2)) >= 0,
        "critical_source": critical.group(1).strip().splitlines()[0].strip() if critical else "not parsed",
        "critical_destination": critical.group(2).strip().splitlines()[0].strip() if critical else "not parsed",
        "critical_data_path_ns": float(critical.group(3)) if critical else 0.0,
        "critical_logic_levels": int(critical.group(4)) if critical else 0,
        "writes": writes, "final_words": output_words, "mismatches": mismatches, "active_cycles": cycles,
        "active_job_gops_at_317": gops, "active_job_us_at_317": job_s * 1e6,
        "p0_typical": p0_typ, "p0_maximum": p0_max, "p3f_typical": p3_typ, "p3f_maximum": p3_max,
        "p3f_dynamic_energy_uj": p3_typ["dynamic_w"] * job_s * 1e6,
        "p3f_total_energy_uj": p3_typ["total_w"] * job_s * 1e6,
        "p3f_dynamic_gops_per_w": gops / p3_typ["dynamic_w"] if p3_typ["dynamic_w"] else 0,
        "p3f_total_gops_per_w": gops / p3_typ["total_w"] if p3_typ["total_w"] else 0,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bench-dir", required=True, type=Path)
    bench = parser.parse_args().bench_dir.resolve()
    records = [collect(bench, name) for name in RUNS]
    fields = ["variant", "DSP", "LUT", "FF", "RAMB36", "RAMB18", "WNS_ns", "TNS_ns", "timing_pass_317MHz",
              "critical_source", "critical_destination", "critical_data_path_ns", "critical_logic_levels",
              "output_writes", "final_words", "mismatches", "active_cycles", "active_job_GOPS_at_317",
              "P0_typ_dynamic_W", "P0_typ_static_W", "P0_typ_total_W", "P0_max_dynamic_W", "P0_max_static_W", "P0_max_total_W",
              "P3F_typ_dynamic_W", "P3F_typ_static_W", "P3F_typ_total_W", "P3F_typ_dynamic_energy_uJ", "P3F_typ_total_energy_uJ",
              "P3F_typ_dynamic_GOPS_W", "P3F_typ_total_GOPS_W", "P3F_max_dynamic_W", "P3F_max_static_W", "P3F_max_total_W",
              "P3F_confidence", "P3F_max_confidence", "P3F_matched_nets", "P3F_total_nets",
              "P3F_clock_W", "P3F_logic_W", "P3F_signals_W", "P3F_DSP_W", "P3F_BRAM_W", "P3F_IO_W"]
    with (bench / "results.csv").open("w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields)
        writer.writeheader()
        for item in records:
            p0t, p0m = item["p0_typical"], item["p0_maximum"]
            p3t, p3m = item["p3f_typical"], item["p3f_maximum"]
            writer.writerow({
                "variant": item["variant"], "DSP": item["dsp"], "LUT": item["lut"], "FF": item["ff"],
                "RAMB36": item["ramb36"], "RAMB18": item["ramb18"], "WNS_ns": item["wns_ns"], "TNS_ns": item["tns_ns"],
                "critical_source": item["critical_source"], "critical_destination": item["critical_destination"],
                "critical_data_path_ns": item["critical_data_path_ns"], "critical_logic_levels": item["critical_logic_levels"],
                "timing_pass_317MHz": item["timing_pass_317mhz"], "output_writes": item["writes"],
                "final_words": item["final_words"], "mismatches": item["mismatches"], "active_cycles": item["active_cycles"],
                "active_job_GOPS_at_317": item["active_job_gops_at_317"],
                "P0_typ_dynamic_W": p0t["dynamic_w"], "P0_typ_static_W": p0t["static_w"], "P0_typ_total_W": p0t["total_w"],
                "P0_max_dynamic_W": p0m["dynamic_w"], "P0_max_static_W": p0m["static_w"], "P0_max_total_W": p0m["total_w"],
                "P3F_typ_dynamic_W": p3t["dynamic_w"], "P3F_typ_static_W": p3t["static_w"], "P3F_typ_total_W": p3t["total_w"],
                "P3F_typ_dynamic_energy_uJ": item["p3f_dynamic_energy_uj"], "P3F_typ_total_energy_uJ": item["p3f_total_energy_uj"],
                "P3F_typ_dynamic_GOPS_W": item["p3f_dynamic_gops_per_w"], "P3F_typ_total_GOPS_W": item["p3f_total_gops_per_w"],
                "P3F_max_dynamic_W": p3m["dynamic_w"], "P3F_max_static_W": p3m["static_w"], "P3F_max_total_W": p3m["total_w"],
                "P3F_confidence": p3t["confidence"], "P3F_max_confidence": p3m["confidence"],
                "P3F_matched_nets": p3t["matched"], "P3F_total_nets": p3t["nets"],
                "P3F_clock_W": p3t["clock_w"], "P3F_logic_W": p3t["logic_w"], "P3F_signals_W": p3t["signals_w"],
                "P3F_DSP_W": p3t["dsp_w"], "P3F_BRAM_W": p3t["bram_w"], "P3F_IO_W": p3t["io_w"],
            })

    lines = [
        "# FPGA power results: registered-pipeline stream08 variants", "",
        "ZCU104 / XCZU7EV, Vivado 2023.2, 317 MHz constraint, canonical 32x32, Cin=3, Cout=3, 3x3 workload.",
        "Power is a Vivado estimate, not a physical board measurement. P0 is post-route vectorless; P3F is post-route functional Xcelium SAIF without SDF.",
        "Rows with negative WNS did not close timing at 317 MHz; throughput/energy at the common target are not achieved operating-point results.",
        "The XDC requested 3.154574 ns, which Vivado rounded to 3.155 ns at 1 ps resolution (316.957 MHz). `prefetch4` is the only timing PASS and has only 0.003 ns slack, so it has effectively no timing margin.",
        "The reported WNS is for the clocked internal paths; no input/output delay model was supplied for the external ports, so this is not an interface timing certification.",
        "The worst path in `rowconst4`, `wstream4`, `prefetch4-rowconst4`, and `prefetch8-rowconst4` runs from `r_weight_spatial` to `r_input_weight` through the combinational weight transform (16–17 logic levels). `prefetch4` instead has a 10-level path from `r_input_weight` through the multiply/inverse datapath to `r_inverse_partial_current`.", "",
        "| Variant | DSP | LUT | FF | WNS ns | 317 MHz | Cycles | Active GOPS | P0 typ D/S/T W | P3F typ D/S/T W | P3F SAIF | P3F max D/S/T W |",
        "|---|---:|---:|---:|---:|:---:|---:|---:|---:|---:|---:|---:|",
    ]
    for x in records:
        p0, p3, p3m = x["p0_typical"], x["p3f_typical"], x["p3f_maximum"]
        coverage = f"{p3['matched']}/{p3['nets']}" if p3["nets"] else "not parsed"
        lines.append(f"| {x['variant']} | {x['dsp']} | {x['lut']:,} | {x['ff']:,} | {x['wns_ns']:.3f} | {'PASS' if x['timing_pass_317mhz'] else 'FAIL'} | {x['active_cycles']:,} | {x['active_job_gops_at_317']:.3f} | {p0['dynamic_w']:.3f}/{p0['static_w']:.3f}/{p0['total_w']:.3f} | {p3['dynamic_w']:.3f}/{p3['static_w']:.3f}/{p3['total_w']:.3f} | {coverage} ({p3['confidence']}) | {p3m['dynamic_w']:.3f}/{p3m['static_w']:.3f}/{p3m['total_w']:.3f} |")
    lines += ["", "P3F typical category breakdown (W):", "", "| Variant | Clock | CLB logic | Signals | DSP | BRAM | I/O |", "|---|---:|---:|---:|---:|---:|---:|"]
    for x in records:
        p = x["p3f_typical"]; lines.append(f"| {x['variant']} | {p['clock_w']:.3f} | {p['logic_w']:.3f} | {p['signals_w']:.3f} | {p['dsp_w']:.3f} | {p['bram_w']:.3f} | {p['io_w']:.3f} |")
    lines += ["", "Active-job energy and power-normalized throughput at the common 317 MHz point (estimates; not achieved operating metrics when WNS is negative):", "", "| Variant | Dynamic energy/job (uJ) | Total energy/job (uJ) | Dynamic GOPS/W | Total GOPS/W |", "|---|---:|---:|---:|---:|"]
    for x in records:
        lines.append(f"| {x['variant']} | {x['p3f_dynamic_energy_uj']:.3f} | {x['p3f_total_energy_uj']:.3f} | {x['p3f_dynamic_gops_per_w']:.3f} | {x['p3f_total_gops_per_w']:.3f} |")
    lines += ["", "Worst post-route max-delay path at the 317 MHz constraint:", "", "| Variant | Source register | Destination register | Data path delay (ns) | Logic levels |", "|---|---|---|---:|---:|"]
    for x in records:
        lines.append(f"| {x['variant']} | `{x['critical_source']}` | `{x['critical_destination']}` | {x['critical_data_path_ns']:.3f} | {x['critical_logic_levels']} |")
    (bench / "comparison.md").write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
