import glob
import re
from pathlib import Path

import pandas as pd

def format_column(folder):
    name = folder[:2].upper()
    etc = folder[2:]
    output = f"{name}{etc}"
    return output


def parse_side(project):
    match = re.search(r"m(\d+)p", project)
    if not match:
        return None
    return int(match.group(1))


def parse_time(path):
    with open(path, "r") as handle:
        content = handle.read()
    match = re.search(r"Total execution time:\s*(\d+)", content)
    if not match:
        return None
    return int(match.group(1))


# Define the glob pattern for synth time logs.
path = "../synthesis/*/sim/testbench-synth-time.log"

rows = []
for file_path in glob.glob(path):
    project = Path(file_path).parents[1].name
    side = parse_side(project)
    time_ns = parse_time(file_path)
    if side is None or time_ns is None:
        continue
    rows.append({"project": project, "side": side, "time/ns": time_ns})

if not rows:
    raise SystemExit("No valid testbench-synth-time.log files found.")

df = pd.DataFrame(rows)
# Pivot to the desired shape.
df_pivot = df.pivot(index="side", columns="project", values="time/ns")
# df_pivot
# df_pivot.drop(columns='project', inplace=True)
# df_pivot
# # Reordena as colunas caso necessário
# df_pivot = df_pivot[['project', 32, 64, 128, 256, 512]]

df_pivot.columns = [format_column(n) for n in df_pivot.columns]
df_pivot.sort_index(axis=1, inplace=True)
df_pivot.sort_index(axis=0, inplace=True)
# Salva o resultado
df_pivot.to_csv("../report/time.csv")
