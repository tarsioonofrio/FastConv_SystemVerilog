import re
from pathlib import Path

import pandas as pd


def load_merged(report_dir):
    path = report_dir / "report-merged.csv"
    if not path.exists():
        raise FileNotFoundError(f"Missing merged report: {path}")
    return pd.read_csv(path)


report_dir = Path(__file__).resolve().parent.parent / "report"
df = load_merged(report_dir)

mask = df["Project"].astype(str).str.contains(r"9-.*032p", regex=True)
df_out = df[mask].copy()
df_out.reset_index(drop=True, inplace=True)

df_out.to_csv(report_dir / "report-merged-9-032p.csv", index=False)
