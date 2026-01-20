import re
from pathlib import Path

import pandas as pd


def load_csv(report_dir, names):
    for name in names:
        path = report_dir / name
        if path.exists():
            return pd.read_csv(path)
    raise FileNotFoundError(f"None of the files exist: {', '.join(names)}")


def strip_pixels(project):
    return re.sub(r"m\\d+p", "", project)


report_dir = Path(__file__).resolve().parent.parent / "report"

df_time = load_csv(report_dir, ["report-time.csv"])
df_logical = load_csv(report_dir, ["report-logical.csv", "report_logical.csv"])
df_power = load_csv(report_dir, ["report-power.csv", "reportpower.csv"])

df_time = df_time.rename(columns={"project": "Project", "time/ns": "time_ns"})

df = df_time.merge(df_logical, on="Project", how="left")
df = df.merge(df_power, on="Project", how="left")

df["nome"] = df["Project"].map(strip_pixels)
df["size"] = pd.to_numeric(df["side"], errors="coerce") ** 2
df["Subtotal"] = pd.to_numeric(df.get("Subtotal"), errors="coerce")
df["time_ns"] = pd.to_numeric(df["time_ns"], errors="coerce")
df["energy"] = (df["Subtotal"] * df["time_ns"]) / 1000

df.sort_values(by=["Project"], inplace=True)
df.reset_index(drop=True, inplace=True)

df.to_csv(report_dir / "report-merged.csv", index=False)
