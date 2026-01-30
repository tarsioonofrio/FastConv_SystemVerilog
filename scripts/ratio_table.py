#!/usr/bin/env python3
import argparse
from pathlib import Path

import pandas as pd

REPO_ROOT = Path(__file__).resolve().parent.parent


def compute_speedups(df, label):
    required = {"cycles", "Cell Area um^2", "Subtotal", "energy_nj"}
    missing = required - set(df.columns)
    if missing:
        raise ValueError(f"{label}: missing columns {missing}")

    naive_rows = df[df["nome"].astype(str).str.lower() == "naive"]
    if naive_rows.empty:
        raise ValueError(f"{label}: naive row not found")
    naive = naive_rows.iloc[0]

    naive_cycles = float(naive["cycles"])
    naive_area = float(naive["Cell Area um^2"])
    naive_power = float(naive["Subtotal"])
    naive_energy = float(naive["energy_nj"])

    out = df.copy()
    out["cycles"] = pd.to_numeric(out["cycles"], errors="coerce")
    out["Cell Area um^2"] = pd.to_numeric(
        out["Cell Area um^2"], errors="coerce"
    )
    out["Subtotal"] = pd.to_numeric(out["Subtotal"], errors="coerce")
    out["energy_nj"] = pd.to_numeric(out["energy_nj"], errors="coerce")

    out["slowdown_cycles"] = round(100 * (1 - (out["cycles"] / naive_cycles)), 2)
    out["ratio_cell_area"] = round(100 * (1 - (out["Cell Area um^2"] / naive_area)), 2)
    out["ratio_power"] = round(100 * (1 - (out["Subtotal"] / naive_power)), 2)
    out["ratio_energy"] = round(100 * (1 - (out["energy_nj"] / naive_energy)), 2)

    cols = [
        "Project",
        "nome",
        "extra",
        "mult",
        "cycles",
        "Cell Area um^2",
        "Subtotal",
        "energy_nj",
        "slowdown_cycles",
        "ratio_cell_area",
        "ratio_power",
        "ratio_energy",
    ]
    out = out[cols].copy()
    out.sort_values(by=["nome", "mult", "extra"], inplace=True)
    return out


def main():
    default_dir = REPO_ROOT / ".." / "dissertation-doc" / "data" / "chap7"

    parser = argparse.ArgumentParser(
        description="Compute speedups vs naive for conv/sys merged reports."
    )
    parser.add_argument(
        "--report-dir",
        default=str(REPO_ROOT / "report"),
        help="Directory containing *-report-merged.csv files.",
    )
    parser.add_argument(
        "--output-dir",
        default=str(default_dir),
        help="Directory to write the output tables.",
    )
    args = parser.parse_args()

    report_dir = Path(args.report_dir)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    conv = pd.read_csv(report_dir / "conv-report-merged.csv")
    sys = pd.read_csv(report_dir / "sys-report-merged.csv")

    conv_out = compute_speedups(conv, "conv")
    sys_out = compute_speedups(sys, "sys")

    conv_out.to_csv(output_dir / "conv-ratio-naive.csv", index=False)
    sys_out.to_csv(output_dir / "sys-ratio-naive.csv", index=False)

    print(f"Wrote {output_dir / 'conv-ratio-naive.csv'}")
    print(f"Wrote {output_dir / 'sys-ratio-naive.csv'}")


if __name__ == "__main__":
    main()
