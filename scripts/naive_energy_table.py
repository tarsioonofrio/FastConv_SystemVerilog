#!/usr/bin/env python3
import argparse
from pathlib import Path

import pandas as pd


REPO_ROOT = Path(__file__).resolve().parent.parent


def main():
    parser = argparse.ArgumentParser(
        description=(
            "Compute equivalent naive energy needed to match cycle counts of sys-report-merged."
        )
    )
    parser.add_argument(
        "--input",
        default=str(REPO_ROOT / "report" / "sys-report-merged.csv"),
        help="Path to sys-report-merged.csv.",
    )
    parser.add_argument(
        "--output-dir",
        default=str(REPO_ROOT / "report"),
        help="Directory to write the output table.",
    )
    parser.add_argument(
        "--baseline",
        default="naive",
        help="Baseline project name (Project column) or nome value (e.g., naive).",
    )
    args = parser.parse_args()

    input_path = Path(args.input)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    df = pd.read_csv(input_path)
    if "cycles" not in df.columns or "energy_nj" not in df.columns:
        raise ValueError("Missing required columns: cycles and energy_nj")

    baseline = args.baseline
    baseline_rows = df[
        df.get("Project", "").astype(str).str.lower() == baseline.lower()
    ]
    if baseline_rows.empty:
        baseline_rows = df[
            df["nome"].astype(str).str.lower() == baseline.lower()
        ]
    if baseline_rows.empty:
        raise ValueError(f"Baseline row not found: {baseline}")

    baseline_row = baseline_rows.iloc[0]
    baseline_cycles = float(baseline_row["cycles"])
    baseline_energy = float(baseline_row["energy_nj"])

    df_target = df[
        df.get("Project", "").astype(str).str.lower() != baseline.lower()
    ].copy()
    df_target["nome"] = df_target["nome"].astype(str)
    df_target["extra"] = df_target.get("extra", "")
    df_target["mult"] = df_target.get("mult", pd.NA)
    df_target["cycles"] = pd.to_numeric(df_target["cycles"], errors="coerce")
    df_target["energy_nj"] = pd.to_numeric(df_target["energy_nj"], errors="coerce")

    df_target["baseline_factor"] = baseline_cycles / df_target["cycles"]
    df_target["energy_baseline_eq"] = (
        df_target["baseline_factor"] * baseline_energy
    )
    df_target["energy_increase_pct"] = (
        (df_target["energy_baseline_eq"] - df_target["energy_nj"])
        / df_target["energy_nj"]
        * 100.0
    )

    cols = [
        "Project",
        "nome",
        "extra",
        "mult",
        "cycles",
        "energy_nj",
        "baseline_factor",
        "energy_baseline_eq",
        "energy_increase_pct",
    ]
    df_out = df_target[cols].copy()
    df_out.sort_values(by=["nome", "mult", "extra"], inplace=True)

    slug = baseline.lower().replace("/", "-")
    csv_path = output_dir / f"sys-{slug}-equivalent-energy.csv"
    txt_path = output_dir / f"sys-{slug}-equivalent-energy.txt"
    df_out.to_csv(csv_path, index=False)

    with txt_path.open("w", encoding="utf-8") as handle:
        handle.write(
            "Baseline-equivalent energy to match cycles (sys-report-merged)\n"
        )
        handle.write("=" * 64 + "\n")
        handle.write(
            f"baseline={baseline} cycles={baseline_cycles:.0f}, "
            f"energy={baseline_energy:.6f} nJ\n\n"
        )
        for _, row in df_out.iterrows():
            handle.write(
                f"{row['Project']}: cycles={row['cycles']:.0f} "
                f"energy={row['energy_nj']:.6f} nJ | "
                f"baseline_factor={row['baseline_factor']:.4f} "
                f"energy_baseline_eq={row['energy_baseline_eq']:.6f} nJ "
                f"delta={row['energy_increase_pct']:.2f}%\n"
            )

    print(f"Wrote {csv_path}")
    print(f"Wrote {txt_path}")


if __name__ == "__main__":
    main()
