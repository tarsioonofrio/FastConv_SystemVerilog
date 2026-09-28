#!/usr/bin/env python3
"""Collect matched scalar/column utilization, timing, and power results."""

from __future__ import annotations

import argparse
import csv
import json
import re
from pathlib import Path

RUNS = {
    "std_scalar": ("std", "scalar"),
    "std_column": ("std", "column"),
    "prefetch8_scalar": ("prefetch8-rowconst4", "scalar"),
    "prefetch8_column": ("prefetch8-rowconst4", "column"),
}
OPS_PER_JOB = 145800
TARGET_MHZ = 317.0


def required(path: Path) -> str:
    if not path.is_file():
        raise SystemExit(f"missing required result: {path}")
    return path.read_text(errors="replace")


def numeric_cell(line: str, label: str) -> float:
    match = re.search(rf"^\|\s*{re.escape(label)}\s*\|\s*([0-9.]+)", line, re.M)
    if not match:
        raise ValueError(f"could not parse {label} from power report")
    return float(match.group(1))


def optional_category(power: str, label: str) -> float:
    try:
        return numeric_cell(power, label)
    except ValueError:
        return 0.0


def parse_utilization(path: Path) -> dict:
    text = required(path)
    for line in text.splitlines():
        if re.match(r"^\|\s*Conv\s+\|\s*\(top\)", line):
            cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
            # Instance, Module, LUT, Logic LUT, LUTRAM, SRL, FF, RAMB36, RAMB18, URAM, DSP
            if len(cells) >= 11:
                return {
                    "lut": int(cells[2]),
                    "ff": int(cells[6]),
                    "ramb36": int(cells[7]),
                    "ramb18": int(cells[8]),
                    "uram": int(cells[9]),
                    "dsp": int(cells[10]),
                }
    raise ValueError(f"could not parse top utilization row: {path}")


def parse_power(path: Path) -> dict:
    text = required(path)
    result = {
        "total_w": numeric_cell(text, "Total On-Chip Power (W)"),
        "dynamic_w": numeric_cell(text, "Dynamic (W)"),
        "static_w": numeric_cell(text, "Device Static (W)"),
        "confidence": re.search(r"^\|\s*Confidence Level\s*\|\s*([^|]+)", text, re.M).group(1).strip(),
        "coverage": None,
        "categories_w": {
            "clock": optional_category(text, "Clocks"),
            "clb_logic": optional_category(text, "CLB Logic"),
            "signals": optional_category(text, "Signals"),
            "dsp": optional_category(text, "DSPs"),
            "bram": optional_category(text, "Block RAM"),
            "io": optional_category(text, "I/O"),
        },
    }
    coverage = re.search(r"^\|\s*Design Nets Matched\s*\|\s*[^()]*\((\d+)/(\d+)\)", text, re.M)
    if coverage:
        result["coverage"] = {"matched": int(coverage.group(1)), "total": int(coverage.group(2))}
    return result


def parse_timing(path: Path) -> dict:
    text = required(path)
    match = re.search(r"^\s*(-?[0-9.]+)\s+(-?[0-9.]+)\s+\d+\s+\d+", text[text.find("Design Timing Summary"):], re.M)
    if not match:
        raise ValueError(f"could not parse WNS/TNS from {path}")
    return {"wns_ns": float(match.group(1)), "tns_ns": float(match.group(2))}


def parse_workload(path: Path) -> dict:
    text = required(path)
    match = re.search(r"POWER_RESULT PASS writes=(\d+) final_words=(\d+) mismatches=(\d+) active_cycles=(\d+)", text)
    if not match:
        raise ValueError(f"missing successful golden marker in {path}")
    writes, words, mismatches, cycles = map(int, match.groups())
    latency_s = cycles / (TARGET_MHZ * 1e6)
    gops = OPS_PER_JOB / cycles * TARGET_MHZ / 1000.0
    return {
        "writes": writes,
        "final_words": words,
        "mismatches": mismatches,
        "active_cycles": cycles,
        "active_job_gops": gops,
        "active_job_us": latency_s * 1e6,
    }


def load_run(bench_dir: Path, run: str, pair: str, interface: str) -> dict:
    run_dir = bench_dir / "reports" / run
    utilization = parse_utilization(run_dir / "utilization.rpt")
    timing = parse_timing(run_dir / "timing_summary.rpt")
    p0_typical = parse_power(run_dir / "power_vectorless_typical.rpt")
    p0_maximum = parse_power(run_dir / "power_vectorless_maximum.rpt")
    p3_typical = parse_power(run_dir / "power_p3f_typical.rpt")
    p3_maximum = parse_power(run_dir / "power_p3f_maximum.rpt")
    workload = parse_workload(run_dir / "dut" / "xrun.log")
    mapping_text = required(run_dir / "p3f_mapping_internal_typical.rpt")
    direct_nets = len([line for line in mapping_text.splitlines() if line.strip() and not line.startswith("---")])
    return {
        "run": run,
        "pair": pair,
        "interface": interface,
        "utilization": utilization,
        "timing": timing,
        "p0_vectorless_typical": p0_typical,
        "p0_vectorless_maximum": p0_maximum,
        "p3f_typical": p3_typical,
        "p3f_maximum": p3_maximum,
        "mapping_report_lines": direct_nets,
        "workload": workload,
    }


def row_for_markdown(item: dict) -> str:
    util = item["utilization"]
    p0 = item["p0_vectorless_typical"]
    p3 = item["p3f_typical"]
    work = item["workload"]
    cov = p3["coverage"]
    cov_text = f"{cov['matched']}/{cov['total']}" if cov else "not reported"
    return (
        f"| {item['pair']} | {item['interface']} | {util['dsp']} | {util['lut']:,} | {util['ff']:,} | "
        f"{util['ramb36']} RAMB36 + {util['ramb18']} RAMB18 | {item['timing']['wns_ns']:.3f} | "
        f"{work['active_cycles']:,} | {work['active_job_gops']:.3f} | "
        f"{p0['dynamic_w']:.3f} / {p0['total_w']:.3f} | "
        f"{p3['dynamic_w']:.3f} / {p3['static_w']:.3f} / {p3['total_w']:.3f} | {cov_text} |"
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bench-dir", type=Path, required=True)
    args = parser.parse_args()
    bench_dir = args.bench_dir.resolve()
    records = [load_run(bench_dir, run, *pair) for run, pair in RUNS.items()]

    with (bench_dir / "results.csv").open("w", newline="") as stream:
        fields = ["pair", "interface", "run", "DSP", "LUT", "FF", "RAMB36", "RAMB18", "URAM",
                  "WNS_ns", "active_cycles", "active_job_GOPS", "P0_dynamic_W", "P0_total_W",
                  "P0_max_dynamic_W", "P0_max_static_W", "P0_max_total_W",
                  "P3F_dynamic_W", "P3F_static_W", "P3F_total_W", "P3F_dynamic_energy_uJ",
                  "P3F_total_energy_uJ", "P3F_dynamic_GOPS_per_W", "P3F_total_GOPS_per_W",
                  "P3F_max_dynamic_W", "P3F_max_static_W", "P3F_max_total_W",
                  "P3F_confidence", "P3F_max_confidence", "P3F_matched_nets",
                  "P3F_total_nets", "P3F_clock_W", "P3F_logic_W", "P3F_signals_W", "P3F_DSP_W",
                  "P3F_BRAM_W", "P3F_IO_W"]
        writer = csv.DictWriter(stream, fieldnames=fields)
        writer.writeheader()
        for item in records:
            u, t, work = item["utilization"], item["timing"], item["workload"]
            p0, p3 = item["p0_vectorless_typical"], item["p3f_typical"]
            p0_max, p3_max = item["p0_vectorless_maximum"], item["p3f_maximum"]
            cat = p3["categories_w"]
            cov = p3["coverage"] or {"matched": "", "total": ""}
            job_s = work["active_cycles"] / (TARGET_MHZ * 1e6)
            writer.writerow({
                "pair": item["pair"], "interface": item["interface"], "run": item["run"],
                "DSP": u["dsp"], "LUT": u["lut"], "FF": u["ff"], "RAMB36": u["ramb36"],
                "RAMB18": u["ramb18"], "URAM": u["uram"], "WNS_ns": t["wns_ns"],
                "active_cycles": work["active_cycles"], "active_job_GOPS": work["active_job_gops"],
                "P0_dynamic_W": p0["dynamic_w"], "P0_total_W": p0["total_w"],
                "P0_max_dynamic_W": p0_max["dynamic_w"], "P0_max_static_W": p0_max["static_w"],
                "P0_max_total_W": p0_max["total_w"],
                "P3F_dynamic_W": p3["dynamic_w"], "P3F_static_W": p3["static_w"],
                "P3F_total_W": p3["total_w"], "P3F_dynamic_energy_uJ": p3["dynamic_w"] * job_s * 1e6,
                "P3F_total_energy_uJ": p3["total_w"] * job_s * 1e6,
                "P3F_dynamic_GOPS_per_W": work["active_job_gops"] / p3["dynamic_w"],
                "P3F_total_GOPS_per_W": work["active_job_gops"] / p3["total_w"],
                "P3F_max_dynamic_W": p3_max["dynamic_w"], "P3F_max_static_W": p3_max["static_w"],
                "P3F_max_total_W": p3_max["total_w"], "P3F_confidence": p3["confidence"],
                "P3F_max_confidence": p3_max["confidence"],
                "P3F_matched_nets": cov["matched"], "P3F_total_nets": cov["total"],
                "P3F_clock_W": cat["clock"], "P3F_logic_W": cat["clb_logic"],
                "P3F_signals_W": cat["signals"], "P3F_DSP_W": cat["dsp"],
                "P3F_BRAM_W": cat["bram"], "P3F_IO_W": cat["io"],
            })

    rows = [
        "# FPGA scalar/column power comparison",
        "",
        "All four implementations use the same XCZU7EV, Vivado 2023.2, 317 MHz constraint and canonical 32x32 / Cin=3 / Cout=3 / 3x3 workload. Power values are Vivado estimates, not board measurements. P0 is post-route vectorless; P3F uses post-route functional Xcelium SAIF (no SDF).",
        "",
        "| Architecture pair | Interface | DSP | LUT | FF | BRAM | WNS (ns) | Active cycles | Active-job GOPS | P0 dyn/total (W) | P3F dyn/static/total (W) | P3F direct SAIF mapping |",
        "|---|---|---:|---:|---:|---|---:|---:|---:|---:|---:|---:|",
    ]
    rows.extend(row_for_markdown(item) for item in records)
    rows.extend([
        "",
        "P3F category breakdown (Typical; watts):",
        "",
        "| Pair | Interface | Clocks | CLB logic | Signals | DSPs | BRAM | I/O | Confidence |",
        "|---|---|---:|---:|---:|---:|---:|---:|---|",
    ])
    for item in records:
        cats = item["p3f_typical"]["categories_w"]
        rows.append(f"| {item['pair']} | {item['interface']} | {cats['clock']:.3f} | {cats['clb_logic']:.3f} | {cats['signals']:.3f} | {cats['dsp']:.3f} | {cats['bram']:.3f} | {cats['io']:.3f} | {item['p3f_typical']['confidence']} |")
    rows.extend([
        "",
        "Derived typical-corner metrics use active-job cycles at 317 MHz and 145,800 equivalent operations/job. They are estimates from Vivado power, not board measurements:",
        "",
        "| Pair | Interface | Dynamic energy/job (uJ) | Total energy/job (uJ) | Dynamic GOPS/W | Total GOPS/W | P0 max dyn/total (W) | P3F max dyn/static/total (W) |",
        "|---|---|---:|---:|---:|---:|---:|---:|",
    ])
    for item in records:
        work = item["workload"]
        typical = item["p3f_typical"]
        maximum = item["p3f_maximum"]
        p0_max = item["p0_vectorless_maximum"]
        job_s = work["active_cycles"] / (TARGET_MHZ * 1e6)
        rows.append(
            f"| {item['pair']} | {item['interface']} | {typical['dynamic_w'] * job_s * 1e6:.2f} | "
            f"{typical['total_w'] * job_s * 1e6:.2f} | {work['active_job_gops'] / typical['dynamic_w']:.2f} | "
            f"{work['active_job_gops'] / typical['total_w']:.2f} | {p0_max['dynamic_w']:.3f} / {p0_max['total_w']:.3f} | "
            f"{maximum['dynamic_w']:.3f} / {maximum['static_w']:.3f} / {maximum['total_w']:.3f} |"
        )
    (bench_dir / "comparison.md").write_text("\n".join(rows) + "\n")
    (bench_dir / "results.json").write_text(json.dumps(records, indent=2) + "\n")
    print(f"COMPARISON_COMPLETE records={len(records)} csv={bench_dir / 'results.csv'} md={bench_dir / 'comparison.md'}")


if __name__ == "__main__":
    main()
