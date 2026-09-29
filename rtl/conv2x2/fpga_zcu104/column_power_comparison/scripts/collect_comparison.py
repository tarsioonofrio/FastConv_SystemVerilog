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


def parse_user_io(path: Path) -> int:
    text = required(path)
    match = re.search(r"Total User IO\s*\|\s*\n\+[-+]+\+\s*\n\|\s*(\d+)\s*\|", text)
    if not match:
        raise ValueError(f"could not parse Total User IO from {path}")
    return int(match.group(1))


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
    user_io = parse_user_io(run_dir / "io.rpt")
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
        "user_io": user_io,
        "timing": {
            **timing,
            "meets_317_mhz": timing["wns_ns"] >= 0.0 and timing["tns_ns"] >= 0.0,
        },
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
        f"{util['ramb36']} RAMB36 + {util['ramb18']} RAMB18 | {item['user_io']} | "
        f"{item['timing']['wns_ns']:.3f} ({'PASS' if item['timing']['meets_317_mhz'] else 'FAIL'}) | "
        f"{work['active_cycles']:,} | {work['active_job_gops']:.3f} | "
        f"{p0['dynamic_w']:.3f} / {p0['static_w']:.3f} / {p0['total_w']:.3f} | "
        f"{p3['dynamic_w']:.3f} / {p3['static_w']:.3f} / {p3['total_w']:.3f} | {cov_text} |"
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bench-dir", type=Path, required=True)
    args = parser.parse_args()
    bench_dir = args.bench_dir.resolve()
    records = [load_run(bench_dir, run, *pair) for run, pair in RUNS.items()]

    with (bench_dir / "results.csv").open("w", newline="") as stream:
        fields = ["pair", "interface", "run", "DSP", "LUT", "FF", "RAMB36", "RAMB18", "URAM", "User_IO",
                  "WNS_ns", "timing_pass_317MHz", "active_cycles", "active_job_GOPS", "P0_dynamic_W", "P0_static_W", "P0_total_W",
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
                "timing_pass_317MHz": t["meets_317_mhz"],
                "User_IO": item["user_io"],
                "active_cycles": work["active_cycles"], "active_job_GOPS": work["active_job_gops"],
                "P0_dynamic_W": p0["dynamic_w"], "P0_total_W": p0["total_w"],
                "P0_static_W": p0["static_w"],
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

    by_pair = {
        name: {item["interface"]: item for item in records if item["pair"] == name}
        for name in dict.fromkeys(item["pair"] for item in records)
    }
    rows = [
        "# FPGA scalar/column power comparison",
        "",
        "All four implementations use the same XCZU7EV, Vivado 2023.2, 317 MHz constraint and canonical 32x32 / Cin=3 / Cout=3 / 3x3 workload. Power values are Vivado estimates, not board measurements. P0 is post-route vectorless; P3F uses post-route functional Xcelium SAIF (no SDF). The reported GOPS is computed at the 317 MHz target; rows that fail timing did not close at that frequency, so their GOPS and energy figures are constrained-point estimates, not achievable operating results.",
        "",
        "## Scalar versus column, paired",
        "",
        "Each cell is scalar → column, so the effect of changing only the memory interface is visible directly:",
        "",
        "| Architecture | DSP | LUT | FF | User I/O bits | WNS @317 MHz (ns) | Active cycles | Active-job GOPS* | P0 dynamic/static/total (W) | P3F dynamic/static/total (W) | P3F SAIF mapping |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for pair_name, interfaces in by_pair.items():
        scalar = interfaces["scalar"]
        column = interfaces["column"]
        su, cu = scalar["utilization"], column["utilization"]
        st, ct = scalar["timing"], column["timing"]
        sw, cw = scalar["workload"], column["workload"]
        sp0, cp0 = scalar["p0_vectorless_typical"], column["p0_vectorless_typical"]
        sp3, cp3 = scalar["p3f_typical"], column["p3f_typical"]
        scov, ccov = sp3["coverage"], cp3["coverage"]
        rows.append(
            f"| {pair_name} | {su['dsp']} → {cu['dsp']} | {su['lut']:,} → {cu['lut']:,} | "
            f"{su['ff']:,} → {cu['ff']:,} | {scalar['user_io']} → {column['user_io']} | "
            f"{st['wns_ns']:.3f} ({'PASS' if st['meets_317_mhz'] else 'FAIL'}) → "
            f"{ct['wns_ns']:.3f} ({'PASS' if ct['meets_317_mhz'] else 'FAIL'}) | "
            f"{sw['active_cycles']:,} → {cw['active_cycles']:,} | {sw['active_job_gops']:.3f} → {cw['active_job_gops']:.3f} | "
            f"{sp0['dynamic_w']:.3f}/{sp0['static_w']:.3f}/{sp0['total_w']:.3f} → "
            f"{cp0['dynamic_w']:.3f}/{cp0['static_w']:.3f}/{cp0['total_w']:.3f} | "
            f"{sp3['dynamic_w']:.3f}/{sp3['static_w']:.3f}/{sp3['total_w']:.3f} → "
            f"{cp3['dynamic_w']:.3f}/{cp3['static_w']:.3f}/{cp3['total_w']:.3f} | "
            f"{scov['matched']}/{scov['total']} → {ccov['matched']}/{ccov['total']} |"
        )
    rows.extend([
        "",
        "Interpretation of the paired results:",
        "",
        "- `std-column` reduces active cycles by 55.3% (23,648 to 10,578) and raises active-job throughput 2.24x at 317 MHz while retaining positive WNS. P3F dynamic power rises from 0.281 W to 0.452 W; the 100 additional top-level user-I/O bits account for a substantial part of that estimate.",
        "- `prefetch8-rowconst4-column` reduces active cycles by 50.9% (21,865 to 10,730), but both prefetch8 implementations fail timing at 317 MHz. The corresponding GOPS and energy figures are only common-target comparisons, not a valid 317 MHz operating result. Its P3F dynamic power rises from 0.246 W to 0.537 W, with I/O rising from 0.118 W to 0.354 W.",
        "",
        "Detailed per-variant values:",
        "",
        "| Architecture pair | Interface | DSP | LUT | FF | BRAM | User I/O bits | WNS @317 MHz (ns) | Active cycles | Active-job GOPS* | P0 dyn/static/total (W) | P3F dyn/static/total (W) | P3F direct SAIF mapping |",
        "|---|---|---:|---:|---:|---|---:|---:|---:|---:|---:|---:|---:|",
    ])
    rows.extend(row_for_markdown(item) for item in records)
    rows.extend([
        "",
        "P3F category breakdown (Typical; watts):",
        "",
        "| Pair | Interface | Clocks | CLB logic | Signals | DSPs | BRAM | I/O | Non-I/O dynamic | Confidence |",
        "|---|---|---:|---:|---:|---:|---:|---:|---:|---|",
    ])
    for item in records:
        cats = item["p3f_typical"]["categories_w"]
        non_io_dynamic = item["p3f_typical"]["dynamic_w"] - cats["io"]
        rows.append(f"| {item['pair']} | {item['interface']} | {cats['clock']:.3f} | {cats['clb_logic']:.3f} | {cats['signals']:.3f} | {cats['dsp']:.3f} | {cats['bram']:.3f} | {cats['io']:.3f} | {non_io_dynamic:.3f} | {item['p3f_typical']['confidence']} |")
    rows.extend([
        "",
        "`report_io` lists 101 user-I/O bits for each scalar top and 201 for each column top; the report marks these ports UNFIXED. P3F power therefore includes Vivado-estimated I/O power at this top-level boundary with inferred defaults, not a board pinout/load model. The column interface roughly doubles the exposed top-level I/O count, so do not attribute the P3F power difference solely to internal datapath switching.",
        "",
        "*Throughput is an equivalent active-job rate derived from active cycles and 317 MHz. It excludes inter-job reset/rearm and is not a sustained multi-job rate. The prefetch8 rows fail the 317 MHz timing constraint (negative WNS/TNS); their 317 MHz throughput and energy figures are hypothetical at the common comparison point and require a lower-frequency implementation before being claimed as achievable FPGA performance.",
        "",
        "Derived typical-corner metrics use active-job cycles at 317 MHz and 145,800 equivalent operations/job. They are estimates from Vivado power, not board measurements:",
        "",
        "| Pair | Interface | Dynamic energy/job (uJ) | Total energy/job (uJ) | Dynamic GOPS/W | Total GOPS/W | P0 max dyn/static/total (W) | P3F max dyn/static/total (W) |",
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
            f"{work['active_job_gops'] / typical['total_w']:.2f} | {p0_max['dynamic_w']:.3f} / "
            f"{p0_max['static_w']:.3f} / {p0_max['total_w']:.3f} | "
            f"{maximum['dynamic_w']:.3f} / {maximum['static_w']:.3f} / {maximum['total_w']:.3f} |"
        )
    (bench_dir / "comparison.md").write_text("\n".join(rows) + "\n")
    (bench_dir / "results.json").write_text(json.dumps(records, indent=2) + "\n")
    print(f"COMPARISON_COMPLETE records={len(records)} csv={bench_dir / 'results.csv'} md={bench_dir / 'comparison.md'}")


if __name__ == "__main__":
    main()
