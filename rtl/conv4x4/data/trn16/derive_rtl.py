#!/usr/bin/env python3
"""Monta o RTL rowconst do trn16 a partir do wpn16 round e da saída de gen_stream_column.py para o trn16.

gen_stream_column.py não gera a variante round, que foi feita à mão sobre o wpn16. Por isso o trn16 herda o RTL round do
wpn16 e troca só o que depende da identidade: a cadeia de linhas de WeightTransformRowConst, InverseRow e
InverseRowAccumulate, além da escala dos pesos (1 em vez de 4).

    derive_rtl.py <wpn16 ...-rowconst8-round-column.sv> <trn16 gerado> <destino>
"""
import sys


def modulo(texto, nome):
    i = texto.index("module " + nome + " #(")
    return i, texto.index("endmodule", i) + len("endmodule")


def linhas(texto):
    i = texto.index("if (ROW_INDEX == 0) begin")
    return i, texto.index("\n      end\n", texto.index("ROW_INDEX == 7"))


def main():
    base, gerado, destino = sys.argv[1:4]
    wp, tr = open(base).read(), open(gerado).read()
    for nome in ("InverseRow", "InverseRowAccumulate"):
        i, e = modulo(wp, nome)
        a, b = modulo(tr, nome)
        wp = wp[:i] + tr[a:b] + wp[e:]
    i, e = linhas(wp)
    a, b = linhas(tr)
    wp = wp[:i] + tr[a:b] + wp[e:]
    wp = wp.replace("localparam int WEIGHT_SCALE = 4;", "localparam int WEIGHT_SCALE = 1;")
    wp = wp.replace("localparam int WEIGHT_SHIFT = 2;", "localparam int WEIGHT_SHIFT = 0;")
    wp = wp.replace("wpn16", "trn16").replace("WEIGHT_SCALE = 4;", "WEIGHT_SCALE = 1;").replace("division by 4", "division by 1")
    open(destino, "w").write(wp)


if __name__ == "__main__":
    main()
