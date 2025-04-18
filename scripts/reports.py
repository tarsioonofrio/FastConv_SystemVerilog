import glob
from pathlib import Path

import pandas as pd


def format_column(folder):
    name = folder[:2].upper()
    bind = folder[2]
    size = folder[3]
    subs = folder[5:]
    output = "$" + name + bind + "^" + size + "_{" + subs + "}$" 
    return output


def read_file(file_path):
    with open(file_path, "r") as f:
        content = f.readlines()
    return content


def project_name(path):
    return Path(path).parent.parent.parent.parent.name
    
    
# Define o padrão do caminho para encontrar todos os arquivos rpt

# Area
path = Path("../src/*/sintese/results/reports/*_area.rpt")
all_files = glob.glob(path.as_posix())
report_area = {project_name(f): read_file(f) for f in all_files}
cell_cout = {k: v[14].split()[1] for k, v in report_area.items()}
cell_area = {k: v[14].split()[2] for k, v in report_area.items()}
net_area = {k: v[14].split()[3] for k, v in report_area.items()}
total_area = {k: v[14].split()[4] for k, v in report_area.items()}

path = Path("../src/*/sintese/results/reports/*_clock_gating.rpt")
# clock_gating
all_files = glob.glob(path.as_posix())
report_clock = {project_name(f): read_file(f) for f in all_files}
flop_count = {k: v[-4].split()[1] for k, v in report_clock.items()}

# Power
path = Path(
    "../src/*/sintese/results/reports/*_power_analysis_view_0p90v_25c_captyp_nominal.rpt"
)
# clock_gating
all_files = glob.glob(path.as_posix())
report_power = {project_name(f): read_file(f) for f in all_files}
power = {k: float(v[15].split()[4]) for k, v in report_power.items()}

# Create a DataFrame from the dictionaries
df = pd.DataFrame(
    {
        "cell-cout": cell_cout,
        "cell-area-um": cell_area,
        "net-area-um": net_area,
        "total-area-um": total_area,
        "flop-count": flop_count,
        "power-mW": power,
    }
)

dft = df.T
dft.columns = [format_column(n) if "naive" not in n else n for n in dft.columns]

# Save to CSV
dft.to_csv("../data/reports.csv")

