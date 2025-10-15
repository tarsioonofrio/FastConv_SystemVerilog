import glob
from pathlib import Path

import pandas as pd


def format_column(folder):
    name = folder[:2].upper()
    bind = folder[2]
    size = folder[3]
    subs = folder[5:]
    output = f"{name}{bind}{size}_{subs}"
    return output


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
file_name = [Path(f).parent.parent.name for f in all_files]
report = [read_file(f) for f in all_files]
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
for f, df in list_df.items():
    df.to_csv(f"../data/{f}_power_report.csv")
df_total = pd.DataFrame({f: df["Total"] for f, df in list_df.items()}).T
df_total.index.name = "file"
df_total.to_csv("../report/category_power_report.csv")
