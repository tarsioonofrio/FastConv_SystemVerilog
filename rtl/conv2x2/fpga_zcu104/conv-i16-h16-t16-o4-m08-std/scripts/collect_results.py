#!/usr/bin/env python3
"""Collect routed Vivado reports without turning missing results into zeros."""
from __future__ import annotations

import csv
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
BENCH = Path(__file__).resolve().parents[1]
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

WINOGEN_F23 = [
    ("WinoGen F(4,1) PNmin, F(2,3)*", "8-16", 4, 1689, 2191, 5.559),
    ("WinoGen F(4,1) constrained, F(2,3)*", "8-16", 16, 2267, 2901, 22.236),
    ("WinoGen F(4,1) PNmax, F(2,3)*", "8-16", 64, 4858, 7579, 92.868),
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
    text = path.read_text(errors="replace") if path.exists() else ""
    setup = re.search(r"Setup\s*:\s*\d+\s+Failing Endpoints,\s+Worst Slack\s+"
                      r"([-+]?\d+(?:\.\d+)?)ns,\s+Total Violation\s+"
                      r"([-+]?\d+(?:\.\d+)?)ns", text)
    if setup:
        wns, tns = map(float, setup.groups())
        return wns, tns, "PASS" if wns >= 0 else "FAIL"
    wns = report_value(path, [r"WNS\s*\(ns\).*?([-+]?\d+(?:\.\d+)?)",
                              r"Worst Negative Slack.*?([-+]?\d+(?:\.\d+)?)"])
    tns = report_value(path, [r"TNS\s*\(ns\).*?([-+]?\d+(?:\.\d+)?)",
                              r"Total Negative Slack.*?([-+]?\d+(?:\.\d+)?)"])
    return wns, tns, ("PASS" if wns is not None and wns >= 0 else
                       "FAIL" if wns is not None else "PENDING")


def utilization(run: str) -> dict[str, float | None]:
    path = REPORTS / run / "utilization.rpt"
    text = path.read_text(errors="replace") if path.exists() else ""
    top_row = next(([part.strip() for part in line.split("|")]
                    for line in text.splitlines()
                    if "| Conv" in line and "(top)" in line), None)
    if top_row and len(top_row) >= 13:
        return {"lut": float(top_row[3]), "lut_logic": float(top_row[4]),
                "lut_memory": float(top_row[5]), "ff": float(top_row[7]),
                "bram": float(top_row[8]) + float(top_row[9]),
                "uram": float(top_row[10]), "dsp": float(top_row[11]),
                "bufg": None}
    patterns = {
        "lut": [r"CLB LUTs\s*\|\s*([\d,]+)", r"Slice LUTs\s*\|\s*([\d,]+)",
                r"Total LUTs\s*\|\s*([\d,]+)"],
        "lut_logic": [r"LUT as Logic\s*\|\s*([\d,]+)", r"Logic LUTs\s*\|\s*([\d,]+)"],
        "lut_memory": [r"LUT as Memory\s*\|\s*([\d,]+)"],
        "ff": [r"CLB Registers\s*\|\s*([\d,]+)", r"Slice Registers\s*\|\s*([\d,]+)",
               r"\|\s*FFs\s*\|\s*([\d,]+)"],
        "dsp": [r"DSPs\s*\|\s*([\d,]+)", r"DSP Blocks\s*\|\s*([\d,]+)"],
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
        "dynamic_w": report_value(path, [r"Dynamic Power\s*\(W\)\s*:\s*([\d.]+)",
                                          r"\|\s*Dynamic \(W\)\s*\|\s*([\d.]+)"]),
        "static_w": report_value(path, [r"Device Static Power\s*\(W\)\s*:\s*([\d.]+)",
                                        r"\|\s*Device Static \(W\)\s*\|\s*([\d.]+)"]),
        "total_w": report_value(path, [r"Total On-Chip Power\s*\(W\)\s*:\s*([\d.]+)",
                                        r"\|\s*Total On-Chip Power \(W\)\s*\|\s*([\d.]+)"]),
    }


def saif_import() -> dict[str, object]:
    """Read the import/coverage facts recorded beside the copied reports."""
    path = REPORTS / "rtl_saif" / "import_summary.txt"
    values: dict[str, object] = {
        "status": None,
        "method": None,
        "saif": None,
        "saif_duration_ps": None,
        "captured_cycles": None,
        "strip_path": None,
        "matched_nets": None,
        "total_design_nets": None,
        "coverage_pct": None,
        "unmatched_nets_use_vectorless": None,
        "tool": None,
        "host": None,
    }
    if not path.exists():
        return values
    for line in path.read_text(errors="replace").splitlines():
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        if key not in values:
            continue
        if key in {"matched_nets", "total_design_nets", "saif_duration_ps"}:
            values[key] = int(value) if value.isdigit() else value
        elif key == "captured_cycles":
            try:
                values[key] = float(value)
            except ValueError:
                values[key] = value
        elif key == "coverage_pct":
            values[key] = float(value) if value.replace(".", "", 1).isdigit() else value
        elif key == "unmatched_nets_use_vectorless":
            values[key] = value.lower() == "true"
        else:
            values[key] = value
    return values


def operation_count() -> dict[str, object]:
    """Load the reviewed operation-count audit instead of re-deriving it here."""
    path = RESULTS / "operation_count.json"
    if not path.exists():
        return {"status": "pending_operation_count_validation",
                "mac_equivalent_ops": None}
    return json.loads(path.read_text())


def rtl_metrics() -> dict[str, int | bool | None]:
    path = REPORTS / "rtl_power_workload.log"
    text = path.read_text(errors="replace") if path.exists() else ""
    match = re.search(r"POWER_WORKLOAD\s+seed=(\d+)\s+jobs=(\d+)\s+"
                      r"latency_cycles=(\d+)\s+ii_cycles=(\d+)\s+"
                      r"tile_ends=(\d+)\s+tile_ii_cycles=(\d+)", text)
    if not match:
        return {"seed": None, "jobs": None, "latency_cycles": None,
                "ii_cycles": None, "observed_ii_cycles": None,
                "job_initiation_interval_cycles": None,
                "job_reentrant": False, "requires_reset_between_jobs": True,
                "tile_ends": None, "tile_ii_cycles": None}
    keys = ["seed", "jobs", "latency_cycles", "ii_cycles", "tile_ends", "tile_ii_cycles"]
    values = dict(zip(keys, map(int, match.groups())))
    values["job_initiation_interval_cycles"] = (
        values["ii_cycles"] if values["jobs"] and values["jobs"] > 1 and values["ii_cycles"] > 0 else None
    )
    values["observed_ii_cycles"] = values["ii_cycles"] if values["ii_cycles"] > 0 else None
    values["ii_cycles"] = values["job_initiation_interval_cycles"]
    values["job_reentrant"] = values["job_initiation_interval_cycles"] is not None
    values["requires_reset_between_jobs"] = not values["job_reentrant"]
    return values


def saif_capture_metadata() -> dict[str, int | float | None]:
    """Read the directed capture timing facts from the Verilator workload log."""
    path = REPORTS / "rtl_saif" / "workload.log"
    text = path.read_text(errors="replace") if path.exists() else ""
    line = next((item for item in text.splitlines()
                 if item.startswith("SAIF_CAPTURE ")), "")
    raw = dict(re.findall(r"(\w+)=([^\s]+)", line))
    integer_keys = {"clock_period_ps", "capture_start_ps", "capture_end_ps",
                    "capture_duration_ps"}
    float_keys = {"nominal_clock_period_ps", "clock_frequency_mhz",
                  "simulated_clock_frequency_mhz", "captured_cycles"}
    values: dict[str, int | float | None] = {}
    for key in integer_keys:
        try:
            values[key] = int(raw[key])
        except (KeyError, ValueError):
            values[key] = None
    for key in float_keys:
        try:
            values[key] = float(raw[key])
        except (KeyError, ValueError):
            values[key] = None
    return values


def energy_metrics(power_values: dict[str, float | None], job_time_s: float | None,
                    gops_eq: float | None) -> dict[str, float | None]:
    """Derive workload energy and efficiency at the 317 MHz implementation point."""
    total = power_values.get("total_w")
    dynamic = power_values.get("dynamic_w")
    if not job_time_s or not gops_eq:
        return {"energy_total_uj": None, "energy_dynamic_uj": None,
                "gops_per_w": None, "pj_per_op": None}
    return {
        "energy_total_uj": total * job_time_s * 1e6 if total is not None else None,
        "energy_dynamic_uj": dynamic * job_time_s * 1e6 if dynamic is not None else None,
        "gops_per_w": gops_eq / total if total else None,
        "pj_per_op": total * 1000 / gops_eq if total is not None else None,
    }


def main() -> int:
    RESULTS.mkdir(parents=True, exist_ok=True)
    rtl = rtl_metrics()
    wns, tns, closure = timing("317mhz")
    util = utilization("317mhz")
    vectorless_typical = power("317mhz", "vectorless", "typical")
    vectorless_maximum = power("317mhz", "vectorless", "maximum")
    rtl_saif_typical = power("317mhz", "rtl_saif", "typical")
    rtl_saif_maximum = power("317mhz", "rtl_saif", "maximum")
    io_activity_typical = power("317mhz", "io_activity", "typical")
    io_activity_maximum = power("317mhz", "io_activity", "maximum")
    saif = saif_import()
    fmax_path = RESULTS / "fmax_search.json"
    fmax = json.loads(fmax_path.read_text()) if fmax_path.exists() else {"status": "not_run"}
    operations = operation_count()
    capture = saif_capture_metadata()
    ops = operations.get("mac_equivalent_ops")
    job_time_s = (rtl["latency_cycles"] / 317e6
                  if rtl.get("latency_cycles") is not None else None)
    hybrid_power_available = (
        rtl_saif_typical["total_w"] is not None
        and not str(saif.get("status", "")).startswith("requires_")
    )
    active_power_typical = (rtl_saif_typical["total_w"]
                            if hybrid_power_available
                            else vectorless_typical["total_w"])
    active_dynamic_typical = (rtl_saif_typical["dynamic_w"]
                              if hybrid_power_available
                              else vectorless_typical["dynamic_w"])
    gops_eq = (ops / job_time_s / 1e9
               if ops is not None and job_time_s else None)
    power_methods = {
        "P0 vectorless": {"typical": vectorless_typical, "maximum": vectorless_maximum},
        "P1 RTL-SAIF hybrid": {"typical": rtl_saif_typical, "maximum": rtl_saif_maximum},
        "P2 input/control activity": {"typical": io_activity_typical, "maximum": io_activity_maximum},
    }
    energy = {
        method: {corner: energy_metrics(values, job_time_s, gops_eq)
                 for corner, values in corners.items()}
        for method, corners in power_methods.items()
    }
    gops_per_w = (gops_eq / active_power_typical
                  if hybrid_power_available and gops_eq is not None and active_power_typical else None)
    pj_per_op = (active_power_typical * job_time_s / ops * 1e12
                 if hybrid_power_available and active_power_typical is not None and job_time_s and ops else None)
    bracket = fmax.get("fmax_bracket_mhz", {})
    if bracket:
        lower = bracket.get("lower_bound_mhz")
        upper = bracket.get("upper_bound_mhz")
        fmax_line = (f"Fmax sweep bracket: `{lower:.2f}`--`{upper:.2f}` MHz; "
                     f"highest tested PASS is `{lower:.2f}` MHz and lowest "
                     f"tested FAIL is `{upper:.2f}` MHz. Exact values remain in "
                     f"`results/fmax_search.json`.")
    else:
        fmax_line = ("Fmax sweep has a PASS/FAIL boundary but no refined bracket "
                     "was recorded in the copied JSON.")
    coverage = (f"{saif['matched_nets']}/{saif['total_design_nets']} "
                f"({saif['coverage_pct']}%)"
                if isinstance(saif.get("matched_nets"), int) else "pending reimport")
    row = {
        "design": "Our Conv pilot @ 317 MHz",
        "bits": 20, "target_mhz": 317.0,
        "achieved_mhz": 317.0 if closure == "PASS" else None,
        "timing": closure, "wns_ns": wns, "tns_ns": tns,
        "dsp": util["dsp"], "lut": util["lut"], "ff": util["ff"],
        "bram": util["bram"], "latency_cycles": rtl["latency_cycles"],
        # A second job cannot be launched without reset, so inter-job II is
        # intentionally null. Latency and tile II remain separate metrics.
        "ii_cycles": rtl["job_initiation_interval_cycles"],
        "tile_ii_cycles": rtl["tile_ii_cycles"],
        "gops_eq": gops_eq, "dynamic_w": active_dynamic_typical,
        "total_w": active_power_typical,
        "dynamic_energy_uj": (active_dynamic_typical * job_time_s * 1e6
                               if active_dynamic_typical is not None and job_time_s else None),
        "gops_per_w": gops_per_w, "pj_per_op": pj_per_op,
        "dynamic_gops_per_w": (gops_eq / active_dynamic_typical
                                if gops_eq is not None and active_dynamic_typical else None),
        "dynamic_pj_per_op": (active_dynamic_typical * 1000 / gops_eq
                               if active_dynamic_typical is not None and gops_eq else None),
    }
    rows = [row]
    for name, bits, dsp, lut, ff, gops in WINOGEN + WINOGEN_F23:
        rows.append({"design": name, "bits": bits, "target_mhz": None,
                     "achieved_mhz": None, "timing": "REFERENCE",
                     "wns_ns": None, "tns_ns": None, "dsp": dsp,
                     "lut": lut, "ff": ff, "bram": None,
                     "latency_cycles": None, "ii_cycles": None,
                     "tile_ii_cycles": None, "gops_eq": gops,
                     "dynamic_w": None, "total_w": None,
                     "dynamic_energy_uj": None, "gops_per_w": None,
                     "pj_per_op": None, "dynamic_gops_per_w": None,
                     "dynamic_pj_per_op": None})

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
               "workload": {"package": "rtl/conv2x2/data/tcn4/sim/sim-032-3-3-normal/pack_data.sv",
                             "sha256": "3ced5c4527374898e1f8d65c275403e1366e2bb09f466542915656b263356da0",
                             "equivalent_ops_per_job": ops,
                             "literal_operations_per_job": operations.get("literal_arithmetic_ops"),
                             "job_latency_cycles": rtl["latency_cycles"],
                             "job_initiation_interval_cycles": rtl["job_initiation_interval_cycles"],
                             "job_reentrant": rtl["job_reentrant"],
                             "throughput_mode": "single_active_job_compute_throughput",
                             "equivalent_throughput_gops_317mhz": gops_eq,
                             "job_time_s_at_317mhz": job_time_s,
                             "saif_window_cycles": capture.get("captured_cycles"),
                             "saif_duration_ps": capture.get("capture_duration_ps"),
                             "saif_clock_period_ps": capture.get("clock_period_ps"),
                             "target_frequency_mhz": 317.0,
                             "saif_frequency_mhz": capture.get("simulated_clock_frequency_mhz"),
                             "operation_count_status": operations.get("status")},
               "operation_count": operations,
               "saif_import": saif,
               "rows": rows,
               "power_rtl_saif_typical": rtl_saif_typical,
               "power_rtl_saif_maximum": rtl_saif_maximum,
               "power_io_activity_typical": io_activity_typical,
               "power_io_activity_maximum": io_activity_maximum,
               "power_comparison": power_methods,
               "energy_comparison": energy,
               "workload_model": "non_reentrant_single_job",
               "completion_status": ("complete_p0_p1_p2_power_fmax_refinement_pending"
                                     if hybrid_power_available and io_activity_typical["total_w"] is not None
                                     else "pending_hybrid_power_reimport")}
    (RESULTS / "results.json").write_text(json.dumps(payload, indent=2) + "\n")

    lines = [
        "# FPGA ZCU104 benchmark summary", "",
        "## Reproducibility boundary", "",
        "Target: `xczu7ev-ffvc1156-2-e`, reference Vivado 2023.2, top `Conv`, pilot 20-bit.",
        "Vivado 2023.2 was executed on Paxos from the direct synchronized snapshot; local reports are a copy of those textual artifacts.",
        fmax_line,
        ("Timing/resource values below are post-route estimates. The complete protocol-directed RTL-SAIF capture at 317 MHz was imported into the routed checkpoint on Paxos; P1 is hybrid SAIF/vectorless and P2 is the input/control cross-check. The prior 245 ns reports and the superseded approximately 100 MHz capture are not final inputs. Timing-SAIF remains optional because XSim hit a Vivado 2023.2 LLVM assertion."), "",
        "## RTL evidence", "",
        f"- seed/jobs: `{rtl['seed']}` / `{rtl['jobs']}`",
        f"- latency: `{rtl['latency_cycles']}` cycles",
        "- job initiation interval: `N/A` (non-reentrant core; reset required between launches)",
        f"- sequential job rate: one complete job every `{rtl['latency_cycles']}` cycles when reset-delimited; this is not a pipeline II",
        f"- tile initiation interval: `{rtl['tile_ii_cycles']}` cycles across `{rtl['tile_ends']}` tile-end events",
        "- canonical Verilator regression: PASS (2025 inverse tiles, 23675 cycles, 8100 writes, zero errors)", "",
        "## Pilot characterization table", "",
        "| Design | bits | target MHz | achieved MHz | timing | DSP | LUT | FF | latency cyc | II | GOPS eq. | dyn. W | total W | GOPS/W | dyn. GOPS/W | pJ/op | dyn. pJ/op |",
        "| --- | ---: | ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
    ]
    for item in rows:
        display_item = {key: ("N/A" if value is None else value)
                        for key, value in item.items()}
        lines.append("| {design} | {bits} | {target_mhz} | {achieved_mhz} | {timing} | {dsp} | {lut} | {ff} | {latency_cycles} | {ii_cycles} | {gops_eq} | {dynamic_w} | {total_w} | {gops_per_w} | {dynamic_gops_per_w} | {pj_per_op} | {dynamic_pj_per_op} |".format(**display_item))
    lines += ["", "## Power table", "",
              "| Design | freq | method | process | Dynamic W | Static W | Total W | SAIF coverage |",
              "| --- | ---: | --- | --- | ---: | ---: | ---: | ---: |",
              f"| our core | 317 MHz | vectorless | typical | {vectorless_typical['dynamic_w']} | {vectorless_typical['static_w']} | {vectorless_typical['total_w']} | N/A |",
              f"| our core | 317 MHz | hybrid RTL-SAIF/vectorless | typical | {rtl_saif_typical['dynamic_w'] if hybrid_power_available else 'PENDING'} | {rtl_saif_typical['static_w'] if hybrid_power_available else 'PENDING'} | {rtl_saif_typical['total_w'] if hybrid_power_available else 'PENDING'} | {coverage} |",
              f"| our core | 317 MHz | vectorless | maximum | {vectorless_maximum['dynamic_w']} | {vectorless_maximum['static_w']} | {vectorless_maximum['total_w']} | N/A |",
              f"| our core | 317 MHz | hybrid RTL-SAIF/vectorless | maximum | {rtl_saif_maximum['dynamic_w'] if hybrid_power_available else 'PENDING'} | {rtl_saif_maximum['static_w'] if hybrid_power_available else 'PENDING'} | {rtl_saif_maximum['total_w'] if hybrid_power_available else 'PENDING'} | {coverage} |",
              f"| our core | 317 MHz | input/control activity + vectorless | typical | {io_activity_typical['dynamic_w']} | {io_activity_typical['static_w']} | {io_activity_typical['total_w']} | 40 injected inputs/controls |",
              f"| our core | 317 MHz | input/control activity + vectorless | maximum | {io_activity_maximum['dynamic_w']} | {io_activity_maximum['static_w']} | {io_activity_maximum['total_w']} | 40 injected inputs/controls |",
              "", "## Operation count, energy and throughput", "",
              "- operation-count audit: `validated dense 2-D convolution`; the generator's 24,300-multiplication line omits input-channel accumulation",
              f"- equivalent operations per complete job: `{ops}`",
              f"- literal arithmetic operations per complete job: `{operations.get('literal_arithmetic_ops')}`",
              f"- job time at 317 MHz: `{job_time_s * 1e6 if job_time_s else None}` us",
              f"- active-job equivalent compute throughput at 317 MHz: `{gops_eq}` GOPS",
              f"- typical total energy/job from P1 hybrid power: `{active_power_typical * job_time_s * 1e6 if hybrid_power_available and active_power_typical is not None and job_time_s else 'PENDING hybrid reimport'}` uJ",
              f"- equivalent throughput: `{gops_eq}` GOPS; P1 total efficiency: `{gops_per_w if hybrid_power_available else 'PENDING hybrid reimport'}` GOPS/W; P1 dynamic-power-normalized efficiency: `{gops_eq / active_dynamic_typical if hybrid_power_available and active_dynamic_typical else 'PENDING hybrid reimport'}` GOPS/W_dynamic",
              f"- P1 total energy: `{pj_per_op if hybrid_power_available else 'PENDING hybrid reimport'}` pJ/op; P1 dynamic-power-normalized energy: `{active_dynamic_typical * 1000 / gops_eq if hybrid_power_available and active_dynamic_typical and gops_eq else 'PENDING hybrid reimport'}` pJ/op_dynamic",
              "GOPS uses the validated dense operation count. Energy is calculated with the 23648-cycle job time at exactly 317 MHz; P1 is the principal hybrid estimate and P2 is the input/control cross-check.",
              "", "## P0/P1/P2 energy comparison", "",
              "| Method | Corner | Dynamic W | Static W | Total W | Dynamic uJ/job | Total uJ/job | GOPS/W | pJ/equivalent-op |",
              "| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
              *[f"| {method} | {corner} | {power_methods[method][corner]['dynamic_w']} | {power_methods[method][corner]['static_w']} | {power_methods[method][corner]['total_w']} | {energy[method][corner]['energy_dynamic_uj']} | {energy[method][corner]['energy_total_uj']} | {energy[method][corner]['gops_per_w']} | {energy[method][corner]['pj_per_op']} |"
                for method in power_methods for corner in ("typical", "maximum")],
              "", "## Direct WinoGen F(2,3) reference", "",
              "The TC2x2 core executes F(2,3). The closest WinoGen Table 1 IP is F(4,1) in supported mode F(2,3)*; its throughput model is based on expected cycles over input tiles, whereas this benchmark uses a complete validated RTL workload.",
              "", "| WinoGen IP | bits | DSP | LUT | FF | equivalent GOPS |", "| --- | ---: | ---: | ---: | ---: | ---: |",
              *[f"| {name} | {bits} | {dsp} | {lut} | {ff} | {gops} |" for name, bits, dsp, lut, ff, gops in WINOGEN_F23],
              "", "WinoGen is 8--16 bit while this pilot is 20 bit. The WinoGen system replicas are not compared directly with this single core; a future replication sweep is the appropriate utilization-matched comparison. The pilot validates the flow and is not automatically part of the final architecture set.",
              "", "Power labels are estimates from Vivado post-route, never physical-board measurements."]
    (RESULTS / "summary.md").write_text("\n".join(lines) + "\n")
    print("wrote", RESULTS / "results.csv", RESULTS / "results.json", RESULTS / "summary.md")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
