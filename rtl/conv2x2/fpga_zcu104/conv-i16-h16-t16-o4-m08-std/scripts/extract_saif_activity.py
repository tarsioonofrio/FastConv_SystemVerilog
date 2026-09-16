#!/usr/bin/env python3
"""Extract DUT primary-port activity from a Verilator SAIF capture."""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


NET_RE = re.compile(
    r"^\s+\((?P<name>[^\s()]+)\s+"
    r"\(T0\s+(?P<t0>\d+)\)\s+"
    r"\(T1\s+(?P<t1>\d+)\)\s+"
    r"\(TZ\s+(?P<tz>\d+)\)\s+"
    r"\(TX\s+(?P<tx>\d+)\)\s+"
    r"\(TB\s+(?P<tb>\d+)\)\s+"
    r"\(TC\s+(?P<tc>\d+)\)\)",
    flags=re.MULTILINE,
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("saif", type=Path)
    parser.add_argument("--json", dest="json_path", type=Path, required=True)
    parser.add_argument("--tcl", dest="tcl_path", type=Path, required=True)
    parser.add_argument("--clock-period-ps", type=float, default=10000.0)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    text = args.saif.read_text(errors="replace")
    duration_match = re.search(r"\(DURATION\s+(\d+)\)", text)
    if not duration_match:
        raise SystemExit("SAIF has no DURATION field")
    duration_ps = float(duration_match.group(1))
    cycles = duration_ps / args.clock_period_ps

    # Keep only the testbench DUT-facing nets. The first tb_power instance is
    # the behavioral port activity; internal dut nets are handled by Vivado's
    # propagation after these primary-port constraints are applied.
    instance = text.split("(INSTANCE tb_power", 1)
    if len(instance) != 2:
        raise SystemExit("SAIF has no tb_power instance")
    port_text = instance[1].split("(INSTANCE dut", 1)[0]
    signals: dict[str, dict[str, float | int | str]] = {}
    for match in NET_RE.finditer(port_text):
        name = match.group("name").replace(r"\[", "[").replace(r"\]", "]")
        if not (name == "clk" or name == "reset" or name.startswith("p_")):
            continue
        t0 = int(match.group("t0"))
        t1 = int(match.group("t1"))
        tz = int(match.group("tz"))
        tx = int(match.group("tx"))
        tc = int(match.group("tc"))
        known = t0 + t1 + tz + tx
        signals[name] = {
            "static_probability": (t1 / known if known else 0.0),
            "toggle_count": tc,
            "toggle_rate_per_clock": (tc / cycles if cycles else 0.0),
            "t0_ps": t0,
            "t1_ps": t1,
            "tz_ps": tz,
            "tx_ps": tx,
            "duration_ps": int(duration_ps),
        }

    if not signals:
        raise SystemExit("SAIF has no DUT-facing primary-port signals")

    payload = {
        "source": str(args.saif),
        "duration_ps": int(duration_ps),
        "clock_period_ps": args.clock_period_ps,
        "simulation_cycles": cycles,
        "signal_count": len(signals),
        "signals": signals,
        "method": "RTL-derived primary-port activity; internal nets remain vectorless",
    }
    args.json_path.parent.mkdir(parents=True, exist_ok=True)
    args.json_path.write_text(json.dumps(payload, indent=2) + "\n")

    lines = [
        "# Generated from RTL/Verilator SAIF. Do not edit by hand.",
        "# Apply after reset_switching_activity -all and before report_power.",
    ]
    for name in sorted(signals):
        values = signals[name]
        lines.append(
            "set _activity_port [get_ports -quiet {%s}]" % name
        )
        lines.append("if {[llength $_activity_port]} {")
        lines.append(
            "  set_switching_activity -static_probability %.12g "
            "-toggle_rate %.12g $_activity_port"
            % (values["static_probability"], values["toggle_rate_per_clock"])
        )
        lines.append("}")
        lines.append("unset _activity_port")
    args.tcl_path.write_text("\n".join(lines) + "\n")
    print(f"extracted {len(signals)} primary-port signals")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
