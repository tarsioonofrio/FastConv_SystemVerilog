#!/usr/bin/env python3
"""Resume os avisos repetitivos de um xrun.log da simulação de portas.

Na simulação com SDF, o modelo de células da TSMC emite um bloco de 6 linhas
("Warning!  Glitch suppression", Time, Scope, Scheduled event, File e uma linha
em branco) a cada glitch filtrado. Em algumas configs são mais de 100 mil
blocos, quase todo o tamanho do log. Este script mantém os K primeiros blocos,
omite os demais e acrescenta uma linha com o total. Todas as outras linhas
(erros, contagens, ciclos, resultado do testbench) ficam iguais, na mesma ordem.

O log original é renomeado para <nome>.full<ext> (ex.: xrun.full.log, ignorado
pelo git) e o resumo fica no nome original, que é o arquivo versionado. Serve
também para logs de console que repetem a saída do xrun (flow.log, runner.log).
Rodar de novo não muda nada: um log já resumido é reconhecido pela linha de marca.

Atenção ao formato: os campos do corpo vêm em qualquer ordem e o último aviso
pode não terminar em linha em branco (a linha seguinte é o resultado do
testbench). O bloco só inclui linhas recuadas com Time/Scope/Scheduled/File.

Uso: python3 scripts/resume_xrun_log.py [-k 10] <xrun.log> [...]
Chamado pelo alvo gate-sim do Makefile.
"""
import argparse
import os
import re
import sys

HEADER = "Warning!  Glitch suppression"
MARK = "[resumo-glitch]"
BODY = re.compile(r"^\s+(Time: \d+ \w+|Scope: |Scheduled event for |File: )")


def is_body(line):
    """Linha do corpo de um aviso de glitch: recuada e com um dos 4 campos do modelo de célula."""
    return line[:1] in (" ", "\t") and BODY.match(line) is not None


def blocks(lines):
    """Gera (eh_glitch, linhas). Um bloco é o cabeçalho, as linhas de corpo seguintes
    (Time, Scope, Scheduled event, File, em qualquer ordem) e no máximo uma linha
    em branco logo depois. Qualquer outra linha encerra o bloco e fica no log."""
    i, n = 0, len(lines)
    while i < n:
        if lines[i].rstrip("\n") == HEADER:
            j = i + 1
            while j < n and is_body(lines[j]):
                j += 1
            if j < n and lines[j].strip() == "":
                j += 1
            yield True, lines[i:j]
            i = j
        else:
            yield False, [lines[i]]
            i += 1


def conteudo(lines):
    """Conferência independente do agrupamento em blocos: linhas não vazias que não são
    cabeçalho, corpo de aviso de glitch nem linha de marca."""
    return [l for l in lines
            if l.strip() and l.rstrip("\n") != HEADER and not is_body(l) and not l.startswith(MARK)]


def resume(path, k):
    with open(path, encoding="utf-8", errors="surrogateescape") as f:
        raw = f.readlines()
    if any(l.startswith(MARK) for l in raw):
        return "já resumido"
    total = sum(1 for g, _ in blocks(raw) if g)
    if total <= k:
        return "%d avisos, nada a resumir" % total
    stem, ext = os.path.splitext(path)
    out, seen = [], 0
    for g, ls in blocks(raw):
        if g:
            seen += 1
            if seen <= k:
                out.extend(ls)
            elif seen == k + 1:
                out.append("%s demais avisos '%s' omitidos; total no fim do arquivo; "
                           "log completo em %s (fora do git)\n" % (MARK, HEADER, os.path.basename(stem) + ".full" + (ext or ".log")))
        else:
            out.extend(ls)
    if out and not out[-1].endswith("\n"):
        out[-1] += "\n"
    out.append("%s avisos '%s': %d (mantidos os %d primeiros)\n" % (MARK, HEADER, total, k))
    # Conferência: fora dos avisos de glitch, o resumo é idêntico ao original, e
    # nenhuma linha de aviso mantida falta no original.
    kept = sum(1 for l in out if l.rstrip("\n") == HEADER)
    if conteudo(out) != conteudo(raw) or kept != min(k, total):
        raise SystemExit("%s: conferência falhou, nada alterado" % path)
    full = stem + ".full" + (ext or ".log")
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8", errors="surrogateescape") as f:
        f.writelines(out)
    os.replace(path, full)
    os.replace(tmp, path)
    return "%d avisos, %d -> %d bytes" % (total, os.path.getsize(full), os.path.getsize(path))


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("-k", type=int, default=10, help="blocos de glitch mantidos (padrão 10)")
    ap.add_argument("logs", nargs="+")
    a = ap.parse_args()
    for p in a.logs:
        if not os.path.isfile(p):
            print("%s: não existe, ignorado" % p)
            continue
        print("%s: %s" % (p, resume(p, a.k)))


if __name__ == "__main__":
    sys.exit(main())
