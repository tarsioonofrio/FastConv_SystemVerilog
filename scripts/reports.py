import glob
from pathlib import Path

import pandas as pd


def read_file(file_path):
    with open(file_path, 'r') as f:
        content = f.readlines()
    return content
    
def project_name(path):
    return Path(path).parent.parent.parent.parent.name
    
# Define o padrão do caminho para encontrar todos os arquivos rpt

# name = ["conv_rapida_area.rpt", "conv_rapida_power_analysis_view_0p90v_25c_captyp_nominal.rpt"]

path = Path("../src/*/sintese/results/reports/*_area.rpt")
# Lista todos os arquivos que correspondem ao padrão
all_files = glob.glob(path.as_posix())

area = {project_name(f): read_file(f)[14].split()[4] for f in all_files}
path = Path("../src/*/sintese/results/reports/*_power_analysis_view_0p90v_25c_captyp_nominal.rpt")
# Lista todos os arquivos que correspondem ao padrão
all_files = glob.glob(path.as_posix())

power = {project_name(f): read_file(f)[15].split()[4] for f in all_files}

# Create a DataFrame from the dictionaries
df = pd.DataFrame({'area-um': area, 'power-mW': power})
df

# Save to CSV
df.to_csv('../data/reports.csv')
