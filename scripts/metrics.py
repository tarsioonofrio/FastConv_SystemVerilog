#!/usr/bin/env python3
import argparse
import csv
import math
from pathlib import Path

import numpy as np
from sklearn.metrics import mean_absolute_error, mean_squared_error, max_error

REPO_ROOT = Path(__file__).resolve().parent.parent
REPORT_DIR = REPO_ROOT / "report"


def read_numbers(path):
    values = []
    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            values.append(float(line))
    return values


def compute_metrics(quantized, reference, eps=1e-9):
    count = min(len(quantized), len(reference))
    if count == 0:
        return count, None, None, None, None, None
    q = quantized[:count]
    r = reference[:count]
    mae = mean_absolute_error(r, q)
    rmse = math.sqrt(mean_squared_error(r, q))
    max_abs = max_error(r, q)
    r_arr = np.asarray(r, dtype=float)
    q_arr = np.asarray(q, dtype=float)
    rel = np.abs(r_arr - q_arr) / np.maximum(np.abs(r_arr), eps)
    max_rel = float(np.max(rel)) if rel.size else None
    mismatches = int(np.sum(r_arr != q_arr))
    mismatch_rate = (mismatches / count) if count else None
    return count, mae, rmse, max_abs, max_rel, mismatch_rate


def find_sim_dirs(root):
    return sorted(root.glob("data/*/sim/sim-032-*-normal"))


def main():
    parser = argparse.ArgumentParser(
        description="Compute MAE/RMSE between s.txt (quantized) and s_default.txt (reference)."
    )
    parser.add_argument(
        "--report-dir",
        default=str(REPORT_DIR),
        help="Directory to write metrics outputs.",
    )
    args = parser.parse_args()
    report_dir = Path(args.report_dir)
    report_dir.mkdir(parents=True, exist_ok=True)

    rows = []
    warnings = []
    for sim_dir in find_sim_dirs(REPO_ROOT):
        s_path = sim_dir / "s.txt"
        s_default_path = sim_dir / "s_default.txt"
        if not s_path.exists() or not s_default_path.exists():
            warnings.append(f"Missing inputs: {sim_dir}")
            continue
        quantized = read_numbers(s_path)
        reference = read_numbers(s_default_path)
        count, mae, rmse, max_abs, max_rel, mismatch_rate = compute_metrics(
            quantized, reference
        )
        if count == 0 or mae is None or rmse is None:
            warnings.append(f"No samples: {sim_dir}")
            continue
        if len(quantized) != len(reference):
            warnings.append(
                f"Length mismatch: {sim_dir} (s.txt={len(quantized)}, s_default.txt={len(reference)})"
            )
        rows.append(
            {
                "dataset": sim_dir.relative_to(REPO_ROOT).as_posix(),
                "count": count,
                "mae": mae,
                "rmse": rmse,
                "max_abs": max_abs,
                "max_rel": max_rel,
                "mismatch_rate": mismatch_rate,
            }
        )

    csv_path = report_dir / "metrics-sim-032-normal.csv"
    txt_path = report_dir / "metrics-sim-032-normal.txt"

    with csv_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "dataset",
                "count",
                "mae",
                "rmse",
                "max_abs",
                "max_rel",
                "mismatch_rate",
            ],
        )
        writer.writeheader()
        for row in rows:
            writer.writerow(row)

    with txt_path.open("w", encoding="utf-8") as handle:
        handle.write("MAE/RMSE for sim-032-*-normal datasets\n")
        handle.write("=" * 48 + "\n")
        for row in rows:
            handle.write(
                f"{row['dataset']}: count={row['count']} "
                f"mae={row['mae']:.6f} rmse={row['rmse']:.6f} "
                f"max_abs={row['max_abs']:.6f} max_rel={row['max_rel']:.6f} "
                f"mismatch_rate={row['mismatch_rate']:.6f}\n"
            )
        if warnings:
            handle.write("\nWarnings:\n")
            for warning in warnings:
                handle.write(f"- {warning}\n")

    print(f"Wrote {csv_path}")
    print(f"Wrote {txt_path}")
    if warnings:
        print("Warnings:")
        for warning in warnings:
            print(f"- {warning}")


if __name__ == "__main__":
    main()
