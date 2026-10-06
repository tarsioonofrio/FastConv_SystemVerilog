# Revalidação de fluxos ASIC com clock de 2 ns

Esta campanha corrige resultados que haviam sido gerados com período de clock
incorreto (10 ns). O período nominal usado nos fluxos validados é 2.000 ns.

`final_status.tsv` consolida 20 configurações ASIC: 8 de 2x2, 5 de 3x3 e 7 de
4x4. Todas têm síntese, simulação funcional e power aprovados com período de
2.000 ns. `re-run` identifica resultados refeitos nesta campanha; os demais
foram previamente verificados com o mesmo período.

Os arquivos em `diagnostics/` preservam os status brutos das tentativas. Alguns
status intermediários contêm falsos negativos causados por verificadores com
critérios incompatíveis com o texto real do testbench ou por comparação
sensível a maiúsculas/minúsculas; não são a fonte de status final. Os logs e
relatórios de cada fluxo ficam na pasta de síntese correspondente.

Também foram refeitas as simulações RTL standalone das variantes column m04 e
m08 do 2x2 com clock de 2 ns. Elas não contam como fluxos ASIC adicionais.
