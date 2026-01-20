import glob
from pathlib import Path

import pandas as pd

EXCLUDED_PROJECTS = {"source", "template"}


def format_column(folder):
    name = folder[:2].upper()
    etc = folder[2:]
    output = f"{name}{etc}"
    return output


def format_project_name(name):
    if len(name) < 2:
        return name.upper()
    return f"{name[:2].upper()}{name[2:]}"


def read_file(file_path):
    with open(file_path, "r") as f:
        content = f.readlines()
    return content


def project_name(path):
    return Path(path).parent.parent.parent.parent.name


# Define o padrão do caminho para encontrar todos os arquivos rpt

# Power
path = Path("../synthesis/*/power/power_evaluation.txt")
# clock_gating
all_files = glob.glob(path.as_posix())
filtered_files = []
for f in all_files:
    name = Path(f).parent.parent.name
    if name in EXCLUDED_PROJECTS:
        print(f"Skipping excluded project: {name}")
        continue
    filtered_files.append(f)
file_name = [Path(f).parent.parent.name for f in filtered_files]
report = [read_file(f) for f in filtered_files]
columns = report[0][15].split()[1:5]
indexes = [v.split()[0] for v in report[0][17:27] if "--" not in v]
data = [
    [[float(i) for i in vv.split()[1:5]] for vv in v[16:27] if "--" not in vv]
    for v in report
]


# Create a DataFrame from the dictionaries
list_df = {
    f: pd.DataFrame(columns=columns, index=indexes, data=list(d))
    for f, d in zip(file_name, data)
}
# for f, df in list_df.items():
#     df.to_csv(f"../report/{f}_power_report.csv")
df_total = pd.DataFrame({f: df["Total"] for f, df in list_df.items()}).T
df_total.insert(0, "Project", [format_project_name(n) for n in df_total.index])
df_total.sort_values(by=["Project"], inplace=True)
df_total.reset_index(drop=True, inplace=True)
df_total.to_csv("../report/report-power.csv", index=False)
