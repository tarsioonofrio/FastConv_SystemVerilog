#!/usr/bin/env python3
"""Generate per-dataset functional-quality metrics and provenance."""

import argparse
import csv
from pathlib import Path

from dataset_metrics import (
    METRIC_FIELDS,
    REPO_ROOT,
    aggregate_dataset_quality,
    collect_dataset_metrics,
)


def _format_metric(value):
    return "NA" if value is None else f"{value:.8g}"


def _format_row(row):
    count = row["count"] or 0
    golden_count = row["quantized_golden_count"] or 0
    return "\n".join(
        [
            f"size={row['size']} algorithm={row['algorithm']} "
            f"architecture={row['architecture']} dataset={row['dataset']}: n={count} "
            f"(s={row['quantized_count']}, reference={row['reference_count']}, "
            f"lengths_match={row.get('lengths_match', 'NA')})",
            "  Float-reference error: "
            f"MAE={_format_metric(row['mae'])} "
            f"RMSE={_format_metric(row['rmse'])} "
            f"max_abs={_format_metric(row['max_abs'])} "
            f"max_rel={_format_metric(row['max_rel'])} "
            f"R2={_format_metric(row['r2_computed'])} "
            f"R2_library={_format_metric(row['r2_library'])}",
            "  Float-reference integer mismatches: "
            f"{row['float_reference_mismatch_count']}/{count} "
            f"({_format_metric(row['float_reference_mismatch_rate'])})",
            "  Quantized-golden error (integer codes): "
            f"MAE={_format_metric(row['quantized_golden_mae_codes'])} "
            f"RMSE={_format_metric(row['quantized_golden_rmse_codes'])} "
            f"max_abs={_format_metric(row['quantized_golden_max_abs_codes'])}",
            "  Quantized-golden mismatches: "
            f"{row['quantized_golden_mismatch_count']}/{golden_count} "
            f"({_format_metric(row['quantized_golden_mismatch_rate'])})",
        ]
    )


def _skipped_dataset_reasons(rows):
    included = {row["dataset"] for row in rows}
    skipped = []
    for sim_dir in sorted(REPO_ROOT.glob("rtl/conv*/data/*/sim/sim-032-*")):
        if not sim_dir.is_dir():
            continue
        dataset = sim_dir.relative_to(REPO_ROOT).as_posix()
        if dataset in included:
            continue
        missing = [
            name
            for name in ("s.txt", "s_default.txt")
            if not (sim_dir / name).is_file()
        ]
        reason = (
            "missing " + ", ".join(missing)
            if missing
            else "no valid paired samples or quantization metadata"
        )
        skipped.append((dataset, reason))
    return skipped


def main():
    parser = argparse.ArgumentParser(
        description="Compute quality metrics for generated sim-032 datasets."
    )
    parser.add_argument(
        "--report-dir",
        default=str(REPO_ROOT / "report"),
        help="Directory for the consolidated metrics CSV and text summary.",
    )
    args = parser.parse_args()
    report_dir = Path(args.report_dir)
    rows = collect_dataset_metrics(root=REPO_ROOT)
    aggregate = aggregate_dataset_quality(rows, root=REPO_ROOT)
    skipped = _skipped_dataset_reasons(rows)
    report_rows = [aggregate, *rows]
    report_dir.mkdir(parents=True, exist_ok=True)
    csv_path = report_dir / "metrics-sim-032-normal.csv"
    fields = METRIC_FIELDS + ["lengths_match"]
    with csv_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        writer.writerows({key: row.get(key) for key in fields} for row in report_rows)

    txt_path = report_dir / "metrics-sim-032-normal.txt"
    with txt_path.open("w", encoding="utf-8") as handle:
        handle.write("Metrics for active sim-032 datasets with output/reference vectors\n")
        handle.write("Errors use each dataset's own quantization scale.\n")
        handle.write(
            "TOTAL is pooled over samples, not an average of dataset metrics. "
            "Float-reference errors are in real-value units; quantized-golden "
            "errors are in integer output codes.\n\n"
        )
        handle.write("TOTAL\n")
        handle.write(_format_row(aggregate) + "\n\n")
        handle.write(f"INDIVIDUAL DATASETS ({len(rows)})\n")
        for row in rows:
            handle.write(_format_row(row) + "\n\n")
        handle.write(f"\nTotal paired samples: {aggregate['count']}\n")
        handle.write(
            "Dataset vector lengths match: "
            f"{aggregate['lengths_match']}\n"
        )
        if skipped:
            handle.write(f"\nNOT INCLUDED ({len(skipped)} dataset(s))\n")
            for dataset, reason in skipped:
                handle.write(f"{dataset}: {reason}\n")
    print(f"Wrote {csv_path}")
    print(f"Wrote {txt_path}")


if __name__ == "__main__":
    main()
