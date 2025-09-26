# Relatórios Consolidados

Este diretório armazena as tabelas derivadas das rotinas de pós-processamento (
`reports.py` e `time.py`):

- `report.csv`: consolida métricas de síntese (contagem de células, áreas parcial e total, número de registradores e potência média) por projeto. As colunas seguem a convenção `<rede><bind><tamanho>_<variante>`.
- `report_transposed.csv`: a mesma informação anterior, porém transposta para facilitar leitura em planilhas, com uma coluna por métrica.
- `time.csv`: tabela pivoteada com os tempos de simulação (`time/ns`) para cada tamanho de entrada (`side`) e projeto.

Os arquivos já saem prontos para importação em ferramentas de análise ou construção de gráficos.
