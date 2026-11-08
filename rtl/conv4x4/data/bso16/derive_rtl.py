#!/usr/bin/env python3
"""Monta o RTL rowconst round do bso16 a partir do bsn16 round.

O bso16 tem a mesma forma do bsn16 (F(4,3) bit-shift, 7 produtos, fatores 1, 1/2 e 1/4), só com outra identidade. O RTL
round do bsn16 guarda a identidade em tabelas: QN, QD e B em WeightTransformRowConst (pesos) e A em InverseRow e
InverseRowAccumulate (saída). A transformada de entrada vem de mult-matrices/<alg>/mult_matrices.sv, gerado pelo
fast-conv. Este script troca só essas tabelas e o nome do algoritmo; as matrizes são lidas de make_custom_build.py.

    derive_rtl.py <bsn16 ...-rowconst7-round-column.sv> <make_custom_build.py do bso16> <destino>
"""
import ast
import re
import sys
from fractions import Fraction


def matrizes(path):
    """Lê as listas C, Q, B e A de make_custom_build.py sem importar o fast_convolution."""
    m = {}
    for no in ast.parse(open(path).read()).body:
        if isinstance(no, ast.Assign) and len(no.targets) == 1 and getattr(no.targets[0], "id", None) in "CQBA":
            m[no.targets[0].id] = ast.literal_eval(no.value)
    return m


def tabela(linhas):
    larg = max(len(str(v)) for r in linhas for v in r)
    corpo = ",\n".join("    '{" + ", ".join(str(v).rjust(larg) for v in r) + "}" for r in linhas)
    return "'{\n" + corpo + "\n  };"


def troca(texto, padrao, novo, n):
    texto, k = re.subn(padrao, lambda _: novo, texto, flags=re.S)
    if k != n:
        raise SystemExit("padrão %r encontrado %d vezes, esperado %d" % (padrao, k, n))
    return texto


def main():
    base, build, destino = sys.argv[1:4]
    m = matrizes(build)
    q = [Fraction(n, d) for n, d in m["Q"]]
    if any(x.numerator != 1 for x in q) or max(x.denominator for x in q) > 4:
        raise SystemExit("o RTL do bsn16 supõe fatores 1/QD com QD <= 4 (WEIGHT_SCALE = 16)")
    t = open(base).read()
    t = troca(t, r"localparam int QN \[0:HADAMARD_SIZE-1\] = '\{[^}]*\};",
              "localparam int QN [0:HADAMARD_SIZE-1] = '{%s};" % ", ".join("1" for _ in q), 1)
    t = troca(t, r"localparam int QD \[0:HADAMARD_SIZE-1\] = '\{[^}]*\};",
              "localparam int QD [0:HADAMARD_SIZE-1] = '{%s};" % ", ".join(str(x.denominator) for x in q), 1)
    t = troca(t, r"(localparam int B \[0:HADAMARD_SIZE-1\]\[0:CONV_KERNEL_SIZE-1\] = )'\{\n.*?\n  \};",
              "localparam int B [0:HADAMARD_SIZE-1][0:CONV_KERNEL_SIZE-1] = " + tabela(m["B"]), 1)
    t = troca(t, r"(localparam int A \[0:HADAMARD_SIZE-1\]\[0:CONV_OUTPUT_SIZE-1\] = )'\{\n.*?\n  \};",
              "localparam int A [0:HADAMARD_SIZE-1][0:CONV_OUTPUT_SIZE-1] = " + tabela(m["A"]), 2)
    t = troca(t, r"// q = \[[^\]]*\]\.", "// q = [%s]." % ", ".join(str(x) for x in q), 1)
    t = t.replace("bsn16", "bso16")
    open(destino, "w").write(t)


if __name__ == "__main__":
    main()
