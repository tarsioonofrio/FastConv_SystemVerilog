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

# Area
path = Path("../synthesis/*/logical/results/reports/*_area.rpt")
all_files = glob.glob(path.as_posix())
report_area = {project_name(f): read_file(f) for f in all_files}
excluded_area = {k for k in report_area if k in EXCLUDED_PROJECTS}
for name in sorted(excluded_area):
    print(f"Skipping excluded project: {name}")
report_area = {k: v for k, v in report_area.items() if k not in EXCLUDED_PROJECTS}
cell_cout = {k: v[14].split()[1] for k, v in report_area.items()}
cell_area = {k: v[14].split()[2] for k, v in report_area.items()}
net_area = {k: v[14].split()[3] for k, v in report_area.items()}
total_area = {k: v[14].split()[4] for k, v in report_area.items()}

path = Path("../rtl/conv/*/sintese/results/reports/*_clock_gating.rpt")
# clock_gating
all_files = glob.glob(path.as_posix())
report_clock = {project_name(f): read_file(f) for f in all_files}
excluded_clock = {k for k in report_clock if k in EXCLUDED_PROJECTS}
for name in sorted(excluded_clock):
    print(f"Skipping excluded project: {name}")
report_clock = {k: v for k, v in report_clock.items() if k not in EXCLUDED_PROJECTS}
flop_count = {k: v[-4].split()[1] for k, v in report_clock.items()}

# Create a DataFrame from the dictionaries
df = pd.DataFrame(
    {
        "cell-count": cell_cout,
        "cell-area-um": cell_area,
        "net-area-um": net_area,
        "total-area-um": total_area,
        "flop-count": flop_count,
    }
)


dft = df.T
dft.columns = [format_column(n) for n in dft.columns]
dft.sort_index(axis=1, inplace=True)


# # Save to CSV
# dft.to_csv("../data/report.csv")

df = dft.T
df.columns = [
    "Cell Count",
    "Cell Area $\mu m^2$",
    "Net Area $\mu m^2$",
    "Total Area $\mu m^2$",
    "Flop Count",
]

df.insert(0, "Project", [format_project_name(n) for n in df.index])
df.sort_values(by=["Project"], inplace=True)
df.reset_index(drop=True, inplace=True)
df.to_csv("../report/report-logical.csv", index=False)
