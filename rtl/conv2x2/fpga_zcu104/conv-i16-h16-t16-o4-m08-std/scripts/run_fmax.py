#!/usr/bin/env python3
"""Run a post-route period sweep; never infer Fmax from synthesis alone."""
from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
BENCH = Path(__file__).resolve().parents[1]
SYNTH = BENCH / "scripts" / "synth_impl.tcl"


def parse_wns(path: Path) -> float | None:
    if not path.exists():
        return None
    text = path.read_text(errors="replace")
    patterns = [
        r"WNS\s*\(ns\).*?([-+]?\d+(?:\.\d+)?)",
        r"Worst Negative Slack.*?([-+]?\d+(?:\.\d+)?)",
    ]
    for pattern in patterns:
        match = re.search(pattern, text, flags=re.I | re.S)
        if match:
            try:
                return float(match.group(1))
            except ValueError:
                pass
    return None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--periods", nargs="+", type=float,
                        default=[5.0, 4.0, 3.333333, 3.154574, 2.857143, 2.5])
    parser.add_argument("--refine-iterations", type=int, default=8)
    parser.add_argument("--target-tolerance-mhz", type=float, default=0.5,
                        help="stop when the pass/fail frequency bracket is this narrow")
    args = parser.parse_args()

    vivado = shutil.which("vivado")
    result = {
        "tool": "vivado",
        "reference_version": "2023.2",
        "part": "xczu7ev-ffvc1156-2-e",
        "post_route_required": True,
        "status": "pending",
        "periods_ns": [],
        "note": "Fmax is valid only for a routed run with WNS >= 0.",
    }
    if not vivado:
        result["status"] = "blocked_tool_unavailable"
        result["tool_path"] = None
        out = BENCH / "results" / "fmax_search.json"
        out.write_text(json.dumps(result, indent=2) + "\n")
        print("vivado not found; wrote", out)
        return 0

    seen: dict[float, dict] = {}

    def run_period(period: float) -> dict:
        period = round(period, 9)
        if period in seen:
            return seen[period]
        name = "fmax_" + f"{period:.6f}".replace(".", "p")
        command = [vivado, "-mode", "batch", "-source", str(SYNTH),
                   "-tclargs", name, str(period)]
        completed = subprocess.run(command, cwd=ROOT, text=True,
                                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        log = BENCH / "reports" / f"{name}.vivado.log"
        log.write_text(completed.stdout)
        wns = parse_wns(BENCH / "reports" / name / "timing_summary.rpt")
        item = {"run": name, "period_ns": period,
                "target_mhz": 1000.0 / period, "wns_ns": wns,
                "timing_closure": wns is not None and wns >= 0,
                "returncode": completed.returncode}
        seen[period] = item
        return item

    for period in args.periods:
        run_period(period)

    # Refine only a real pass/fail bracket from routed results.
    for _ in range(max(0, args.refine_iterations)):
        passed = [p for p, item in seen.items() if item["timing_closure"]]
        failed = [p for p, item in seen.items() if item["wns_ns"] is not None and not item["timing_closure"]]
        if not passed or not failed:
            break
        best_pass = min(passed)
        best_fail = max(failed)
        # Period increases as frequency decreases: the highest-frequency pass
        # has the smallest passing period, while the lowest-frequency fail has
        # the largest failing period. They form a valid bracket when
        # best_fail < best_pass.
        if best_fail >= best_pass or best_pass - best_fail < 1e-6:
            break
        lower_mhz = 1000.0 / best_pass
        upper_mhz = 1000.0 / best_fail
        if upper_mhz - lower_mhz <= args.target_tolerance_mhz:
            break
        run_period((best_pass + best_fail) / 2.0)

    ordered = sorted(seen.values(), key=lambda item: item["period_ns"])
    valid = [item for item in ordered if item["timing_closure"]]
    result["status"] = "complete" if valid else "no_post_route_pass"
    result["periods_ns"] = ordered
    if valid:
        best = min(valid, key=lambda item: item["period_ns"])
        result["fmax"] = best
        result["fmax"]["reported_as"] = "highest_tested_pass_lower_bound"
        passed_periods = [item["period_ns"] for item in ordered
                          if item["timing_closure"]]
        failed_periods = [item["period_ns"] for item in ordered
                          if item["wns_ns"] is not None and not item["timing_closure"]]
        if failed_periods:
            pass_period = min(passed_periods)
            fail_period = max(failed_periods)
            result["fmax_bracket_mhz"] = {
                "lower_bound_mhz": 1000.0 / pass_period,
                "upper_bound_mhz": 1000.0 / fail_period,
                "width_mhz": 1000.0 / fail_period - 1000.0 / pass_period,
                "highest_tested_pass_mhz": 1000.0 / pass_period,
                "lowest_tested_fail_mhz": 1000.0 / fail_period,
                "tolerance_mhz": args.target_tolerance_mhz,
            }
            result["refinement_target_met"] = (
                result["fmax_bracket_mhz"]["width_mhz"] <= args.target_tolerance_mhz
            )
            result["note"] = (
                "Report the highest tested PASS as a lower bound; the true "
                "post-route boundary is bracketed by the nearest PASS/FAIL "
                "points and is not known to the displayed decimal precision."
            )
    out = BENCH / "results" / "fmax_search.json"
    out.write_text(json.dumps(result, indent=2) + "\n")
    print("wrote", out)
    return 0 if result["status"] == "complete" else 1


if __name__ == "__main__":
    raise SystemExit(main())
