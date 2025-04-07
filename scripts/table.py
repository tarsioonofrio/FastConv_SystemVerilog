import argparse
import csv
from pathlib import Path

parser = argparse.ArgumentParser(description="Process some paths.")
parser.add_argument("folder", type=Path, help="Path to the folder containing data")
args = parser.parse_args()
folder = args.folder.name
src = Path(__file__).parent.parent / "src"
# folder = "tc4n-m4b20c6"
# src = Path(".").resolve().parent / "src"
path = src / folder / "data"

files = list(path.rglob("**/sim_summary.txt"))

file_time = []
for file in files:
    with open(file, "r") as f:
        content = f.readlines()
        data = (folder, int(file.parent.name.split("-")[1]), int(content[1].strip()))
        file_time.append(data)


with open(path / 'time.csv', 'w', newline='') as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(["project", "side", "time/ns"])
    for file in file_time:
        writer.writerow(file)
