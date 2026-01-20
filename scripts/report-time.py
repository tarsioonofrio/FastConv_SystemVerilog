import glob
import re
from pathlib import Path

import pandas as pd

EXCLUDED_PROJECTS = {"source", "template"}


def format_column(folder):
    name = folder[:2].upper()
    time = folder[8:12]
    etc = folder[2:].replace(time, "")
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
    if project in EXCLUDED_PROJECTS:
        print(f"Skipping excluded project: {project}")
        continue
    side = parse_side(project)
    time_ns = parse_time(file_path)
    if side is None or time_ns is None:
        continue
    rows.append({"project": project, "side": side, "time/ns": time_ns})

if not rows:
    raise SystemExit("No valid testbench-synth-time.log files found.")

df = pd.DataFrame(rows)
df.sort_values(by=['project'], inplace=True)
df.reset_index(drop=True, inplace=True)
df.to_csv("../report/report-time.csv")
