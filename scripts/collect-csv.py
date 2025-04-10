import glob

import pandas as pd

# Define o padrão do caminho para encontrar todos os arquivos time.csv
path = "../src/*/data/time.csv"

# Lista todos os arquivos que correspondem ao padrão
all_files = glob.glob(path)
all_files
# Concatena todos os arquivos CSV de uma vez
df = pd.concat(map(pd.read_csv,glob.glob(path)), ignore_index=True)

# Pivota a tabela para o formato desejado
df_pivot = df.pivot(index='project', columns='side', values='time/ns')

# Reseta o index para transformar 'project' em uma coluna
df_pivot.reset_index(inplace=True)

# Reordena as colunas caso necessário
df_pivot = df_pivot[['project', 32, 64, 128, 256, 512]]

# Salva o resultado
df_pivot.to_csv("../data/time.csv", index=False)
