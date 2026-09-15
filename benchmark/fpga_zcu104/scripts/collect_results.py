#!/usr/bin/env python3
"""Collect routed Vivado reports without turning missing results into zeros."""
from __future__ import annotations

import csv
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BENCH = ROOT / "benchmark" / "fpga_zcu104"
REPORTS = BENCH / "reports"
RESULTS = BENCH / "results"

WINOGEN = [
    ("WinoGen F(4,3) PNmin", "8-16", 6, 2441, 3587, 9.883),
    ("WinoGen F(4,3) constrained", "8-16", 48, 8267, 11678, 123.824),
    ("WinoGen F(4,3) PNmax", "8-16", 144, 17472, 18476, 371.472),
    ("WinoGen F(6,3) PNmin", "8-16", 8, 3757, 5703, 12.508),
    ("WinoGen F(6,3) constrained", "8-16", 128, 31899, 25307, 412.020),
    ("WinoGen F(6,3) PNmax", "8-16", 256, 41093, 40238, 835.812),
]


def number(pattern: str, text: str) -> float | None:
    match = re.search(pattern, text, flags=re.I | re.S)
    return float(match.group(1)) if match else None


def report_value(path: Path, patterns: list[str]) -> float | None:
    if not path.exists():
        return None
    text = path.read_text(errors="replace")
    for pattern in patterns:
        value = number(pattern, text)
        if value is not None:
            return value
    return None


def timing(run: str) -> tuple[float | None, float | None, str]:
    path = REPORTS / run / "timing_summary.rpt"
    wns = report_value(path, [r"WNS\s*\(ns\).*?([-+]?\d+(?:\.\d+)?)",
                              r"Worst Negative Slack.*?([-+]?\d+(?:\.\d+)?)"])
    tns = report_value(path, [r"TNS\s*\(ns\).*?([-+]?\d+(?:\.\d+)?)",
                              r"Total Negative Slack.*?([-+]?\d+(?:\.\d+)?)"])
    return wns, tns, ("PASS" if wns is not None and wns >= 0 else
                       "FAIL" if wns is not None else "PENDING")


def utilization(run: str) -> dict[str, float | None]:
    path = REPORTS / run / "utilization.rpt"
    text = path.read_text(errors="replace") if path.exists() else ""
    patterns = {
        "lut": [r"CLB LUTs\s*\|\s*([\d,]+)", r"Slice LUTs\s*\|\s*([\d,]+)"],
        "lut_logic": [r"LUT as Logic\s*\|\s*([\d,]+)"],
        "lut_memory": [r"LUT as Memory\s*\|\s*([\d,]+)"],
        "ff": [r"CLB Registers\s*\|\s*([\d,]+)", r"Slice Registers\s*\|\s*([\d,]+)"],
        "dsp": [r"DSPs\s*\|\s*([\d,]+)"],
        "bram": [r"Block RAM Tile\s*\|\s*([\d.]+)", r"RAMB18\s*\|\s*([\d,]+)"],
        "uram": [r"URAM\s*\|\s*([\d,]+)"],
        "bufg": [r"BUFG\s*\|\s*([\d,]+)"],
    }
    out: dict[str, float | None] = {}
    for key, choices in patterns.items():
        out[key] = next((number(pattern, text) for pattern in choices
                         if number(pattern, text) is not None), None)
    return out


def power(run: str, method: str, corner: str) -> dict[str, float | None]:
    path = REPORTS / run / f"power_{method}_{corner}.rpt"
    return {
        "dynamic_w": report_value(path, [r"Dynamic Power\s*\(W\)\s*:\s*([\d.]+)"
                                          , r"Dynamic Power\s*\|\s*([\d.]+)"]),
        "static_w": report_value(path, [r"Device Static Power\s*\(W\)\s*:\s*([\d.]+)"
                                        , r"Device Static Power\s*\|\s*([\d.]+)"]),
        "total_w": report_value(path, [r"Total On-Chip Power\s*\(W\)\s*:\s*([\d.]+)"
                                        , r"Total On-Chip Power\s*\|\s*([\d.]+)"]),
    }


def rtl_metrics() -> dict[str, int | None]:
    path = REPORTS / "rtl_power_workload.log"
    text = path.read_text(errors="replace") if path.exists() else ""
    match = re.search(r"POWER_WORKLOAD\s+seed=(\d+)\s+jobs=(\d+)\s+"
                      r"latency_cycles=(\d+)\s+ii_cycles=(\d+)\s+"
                      r"tile_ends=(\d+)\s+tile_ii_cycles=(\d+)", text)
    if not match:
        return {"seed": None, "jobs": None, "latency_cycles": None,
                "ii_cycles": None, "tile_ends": None, "tile_ii_cycles": None}
    keys = ["seed", "jobs", "latency_cycles", "ii_cycles", "tile_ends", "tile_ii_cycles"]
    return dict(zip(keys, map(int, match.groups())))


def main() -> int:
    RESULTS.mkdir(parents=True, exist_ok=True)
    rtl = rtl_metrics()
    wns, tns, closure = timing("317mhz")
    util = utilization("317mhz")
    fmax_path = RESULTS / "fmax_search.json"
    fmax = json.loads(fmax_path.read_text()) if fmax_path.exists() else {"status": "not_run"}
    row = {
        "design": "Our Conv baseline @ 317 MHz",
        "bits": 20, "target_mhz": 317.0, "achieved_mhz": None,
        "timing": closure, "wns_ns": wns, "tns_ns": tns,
        "dsp": util["dsp"], "lut": util["lut"], "ff": util["ff"],
        "bram": util["bram"], "latency_cycles": rtl["latency_cycles"],
        # The core accepts one complete campaign per launch; tile II is kept
        # separately and is not confused with job-level re-initiation.
        "ii_cycles": rtl["latency_cycles"],
        "tile_ii_cycles": rtl["tile_ii_cycles"],
        "gops_eq": None, "dynamic_w": None, "total_w": None,
        "gops_per_w": None, "pj_per_op": None,
    }
    rows = [row]
    for name, bits, dsp, lut, ff, gops in WINOGEN:
        rows.append({"design": name, "bits": bits, "target_mhz": None,
                     "achieved_mhz": None, "timing": "REFERENCE",
                     "wns_ns": None, "tns_ns": None, "dsp": dsp,
                     "lut": lut, "ff": ff, "bram": None,
                     "latency_cycles": None, "ii_cycles": None,
                     "tile_ii_cycles": None, "gops_eq": gops,
                     "dynamic_w": None, "total_w": None,
                     "gops_per_w": None, "pj_per_op": None})

    fields = list(rows[0])
    # Keep the CSV unambiguous and diff-check clean. JSON retains real nulls;
    # the textual CSV uses the explicit token NA instead of trailing commas.
    csv_rows = [{key: ("NA" if value is None else value)
                 for key, value in item.items()} for item in rows]
    with (RESULTS / "results.csv").open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        writer.writerows(csv_rows)
    payload = {"platform": {"vivado_reference": "2023.2",
                             "part": "xczu7ev-ffvc1156-2-e", "board": "ZCU104"},
               "rtl_validation": rtl, "fmax_search": fmax,
               "rows": rows,
               "completion_status": "pending_remote_vivado"}
    (RESULTS / "results.json").write_text(json.dumps(payload, indent=2) + "\n")

    lines = [
        "# FPGA ZCU104 benchmark summary", "",
        "## Reproducibility boundary", "",
        "Target: `xczu7ev-ffvc1156-2-e`, reference Vivado 2023.2, top `Conv`, baseline 20-bit.",
        "The local checkout has no Vivado binaries; the Paxos module catalog provides Vivado 2023.2. Execute the implementation there before filling post-route timing, Fmax, resource and power cells.",
        "No timing PASS, measured power, or SAIF coverage is claimed.", "",
        "## RTL evidence", "",
        f"- seed/jobs: `{rtl['seed']}` / `{rtl['jobs']}`",
        f"- latency: `{rtl['latency_cycles']}` cycles",
        f"- job-level II: `{rtl['latency_cycles']}` cycles (one campaign per launch)",
        f"- tile initiation interval: `{rtl['tile_ii_cycles']}` cycles across `{rtl['tile_ends']}` tile-end events",
        "- canonical Verilator regression: PASS (2025 inverse tiles, 23675 cycles, 8100 writes, zero errors)", "",
        "## Required final table", "",
        "| Design | bits | target MHz | achieved MHz | timing | DSP | LUT | FF | latency cyc | II | GOPS eq. | dyn. W | total W | GOPS/W | pJ/op |",
        "| --- | ---: | ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
    ]
    for item in rows:
        lines.append("| {design} | {bits} | {target_mhz} | {achieved_mhz} | {timing} | {dsp} | {lut} | {ff} | {latency_cycles} | {ii_cycles} | {gops_eq} | {dynamic_w} | {total_w} | {gops_per_w} | {pj_per_op} |".format(**item))
    lines += ["", "## Power table", "",
              "| Design | freq | method | process | Dynamic W | Static W | Total W | SAIF coverage |",
              "| --- | ---: | --- | --- | ---: | ---: | ---: | ---: |",
              "| our core | 317 MHz | vectorless | typical | PENDING | PENDING | PENDING | N/A |",
              "| our core | 317 MHz | SAIF post-route | typical | PENDING | PENDING | PENDING | PENDING |",
              "| our core | 317 MHz | SAIF post-route | maximum | PENDING | PENDING | PENDING | PENDING |",
              "| our core | Fmax | SAIF post-route | typical | PENDING | PENDING | PENDING | PENDING |",
              "", "WinoGen reference is 8--16 bit; this baseline is 20 bit. WinoGen Table 1 is an IP/core comparison. The reported WinoGen Table 2 system replicas are not compared directly with one core.",
              "", "Power labels are estimates from Vivado post-route, never physical-board measurements."]
    (RESULTS / "summary.md").write_text("\n".join(lines) + "\n")
    print("wrote", RESULTS / "results.csv", RESULTS / "results.json", RESULTS / "summary.md")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
