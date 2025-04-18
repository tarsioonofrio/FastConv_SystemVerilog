import glob

import pandas as pd


def format_column(folder):
    name = folder[:2].upper()
    bind = folder[2]
    size = folder[3]
    subs = folder[5:]
    output = "$" + name + bind + "^" + size + "_{" + subs + "}$"
    return output


# Define o padrão do caminho para encontrar todos os arquivos time.csv
path = "../src/*/data/time.csv"

# Lista todos os arquivos que correspondem ao padrão
all_files = glob.glob(path)

# Concatena todos os arquivos CSV de uma vez
df = pd.concat(map(pd.read_csv, glob.glob(path)), ignore_index=True)
# Pivota a tabela para o formato desejado
df_pivot = df.pivot(index="side", columns="project", values="time/ns")
df_pivot
# df_pivot.drop(columns='project', inplace=True)
# df_pivot
# # Reordena as colunas caso necessário
# df_pivot = df_pivot[['project', 32, 64, 128, 256, 512]]

df_pivot.columns = sorted([
    format_column(n) if "naive" not in n else n for n in df_pivot.columns
])

# Salva o resultado
df_pivot.to_csv("../data/time.csv")
