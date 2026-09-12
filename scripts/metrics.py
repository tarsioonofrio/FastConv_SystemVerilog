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


def read_ints(path):
    values = []
    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            values.append(int(float(line)))
    return values


def compute_metrics(quantized_int, reference, quant_bits, eps=1e-9):
    count = min(len(quantized_int), len(reference))
    if count == 0:
        return count, None, None, None, None, None
    scale = 2**quant_bits
    q_int = np.asarray(quantized_int[:count], dtype=int)
    r_arr = np.asarray(reference[:count], dtype=float)
    q_dequant = q_int.astype(float) / scale
    mae = mean_absolute_error(r_arr, q_dequant)
    rmse = math.sqrt(mean_squared_error(r_arr, q_dequant))
    max_abs = max_error(r_arr, q_dequant)
    rel = np.abs(r_arr - q_dequant) / np.maximum(np.abs(r_arr), eps)
    max_rel = float(np.max(rel)) if rel.size else None
    r_quant = np.trunc(r_arr * scale).astype(int)
    mismatches = int(np.sum(q_int != r_quant))
    mismatch_rate = (mismatches / count) if count else None
    return count, mae, rmse, max_abs, max_rel, mismatch_rate


def find_sim_dirs(root):
    # Datasets follow the same RTL-local layout as synthesis projects.  The
    # archived 2x2 experiments live below ``rtl/conv2x2/archive`` and are not
    # part of the current metrics table because this glob only visits direct
    # ``rtl/conv*`` architecture directories.
    return sorted(root.glob("rtl/conv*/data/*/sim/sim-032-*-normal"))


def main():
    parser = argparse.ArgumentParser(
        description="Compute MAE/RMSE between s.txt (quantized) and s_default.txt (reference)."
    )
    parser.add_argument(
        "--report-dir",
        default=str(REPORT_DIR),
        help="Directory to write metrics outputs.",
    )
    parser.add_argument(
        "--quant-bits",
        type=int,
        default=8,
        help="Quantization bits used to dequantize s.txt values.",
    )
    args = parser.parse_args()
    report_dir = Path(args.report_dir)
    report_dir.mkdir(parents=True, exist_ok=True)

    rows = []
    warnings = []
    all_quantized = []
    all_reference = []
    for sim_dir in find_sim_dirs(REPO_ROOT):
        s_path = sim_dir / "s.txt"
        s_default_path = sim_dir / "s_default.txt"
        if not s_path.exists() or not s_default_path.exists():
            warnings.append(f"Missing inputs: {sim_dir}")
            continue
        quantized = read_ints(s_path)
        reference = read_numbers(s_default_path)
        all_quantized.extend(quantized)
        all_reference.extend(reference)
        count, mae, rmse, max_abs, max_rel, mismatch_rate = compute_metrics(
            quantized, reference, args.quant_bits
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

    total_count, total_mae, total_rmse, total_max_abs, total_max_rel, total_mismatch = (
        compute_metrics(all_quantized, all_reference, args.quant_bits)
    )

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
            lineterminator="\n",
        )
        writer.writeheader()
        writer.writerow(
            {
                "dataset": "ALL",
                "count": total_count,
                "mae": total_mae,
                "rmse": total_rmse,
                "max_abs": total_max_abs,
                "max_rel": total_max_rel,
                "mismatch_rate": total_mismatch,
            }
        )

    with txt_path.open("w", encoding="utf-8") as handle:
        handle.write("MAE/RMSE for sim-032-*-normal datasets (merged)\n")
        handle.write("=" * 48 + "\n")
        if total_count and total_mae is not None:
            handle.write(
                f"ALL: count={total_count} "
                f"mae={total_mae:.6f} rmse={total_rmse:.6f} "
                f"max_abs={total_max_abs:.6f} max_rel={total_max_rel:.6f} "
                f"mismatch_rate={total_mismatch:.6f}\n"
            )
        else:
            handle.write("ALL: no samples\n")
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
