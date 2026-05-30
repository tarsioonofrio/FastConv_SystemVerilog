import sys
import time

TAM = 200


def separador(car):
    # Verifica se o caractere é um separador (espaço, vírgula, nova linha, tab, return)
    return car in [" ", ",", "\n", "\t", "\r"]


def search_word(line, start_idx):
    """
    A partir da posição start_idx, ignora os separadores e retorna o token encontrado
    e a nova posição.
    """
    # Avança enquanto encontra separadores
    while start_idx < len(line) and separador(line[start_idx]):
        start_idx += 1
    token = ""
    while start_idx < len(line) and (not separador(line[start_idx])):
        token += line[start_idx]
        start_idx += 1
    return token, start_idx


def initialize_matrix(pow_val, hor_size, ver_size):
    """
    Cria uma matriz 3D com dimensões [pow_val][hor_size][ver_size], preenchida com zeros.
    """
    return [
        [[0 for _ in range(ver_size)] for _ in range(hor_size)]
        for _ in range(pow_val)
    ]


def find_parameters(filename):
    """
    Lê o arquivo e determina os parâmetros x (número de linhas válidas na primeira matriz),
    y (número de palavras na primeira linha válida) e pow (número de blocos de dados extras).

    As linhas que começam com '0' ou '1' são consideradas linhas válidas da matriz.
    As demais linhas contam como blocos de dados (pow).
    """
    x = 0
    y = 0
    pow_val = 0

    try:
        with open(filename, "r") as fp:
            lines = fp.readlines()
    except FileNotFoundError:
        print(f"File {filename} does not exist\n")
        sys.exit(0)

    for line in lines:
        # Se a linha começa com '0' ou '1', trata como linha válida
        if line and (line[0] == "0" or line[0] == "1"):
            # Se pow_val ainda é zero (processa apenas as linhas da primeira matriz)
            if pow_val == 0:
                if x == 0:
                    # Conta os tokens da linha para determinar y
                    idx = 0
                    cont = 0
                    while idx < len(line):
                        token, idx = search_word(line, idx)
                        if token:
                            cont += 1
                    y = cont
                x += 1
        else:
            # Se a linha não for válida, consideramos como bloco (aumenta pow)
            pow_val += 1

    return x, y, pow_val


def read_matrix(filename, pow_val, ver_size, hor_size):
    """
    Lê o arquivo e preenche uma matriz 3D (list) com dimensões [pow_val][ver_size][hor_size]
    com os valores inteiros encontrados. Aqui, a ordem de iteração segue o código C.
    """
    # Inicializa a matriz com zeros
    matrix = initialize_matrix(pow_val, ver_size, hor_size)
    try:
        with open(filename, "r") as fp:
            lines = fp.readlines()
    except FileNotFoundError:
        print(f"File {filename} does not exist\n")
        sys.exit(0)

    current_block = 0
    X = 0
    line_idx = 0
    while current_block < pow_val and line_idx < len(lines):
        line = lines[line_idx]
        line_idx += 1
        # Se a linha é válida (começa com '0' ou '1'), processa a linha
        if line and (line[0] == "0" or line[0] == "1"):
            Y = 0
            idx = 0
            while idx < len(line):
                token, idx = search_word(line, idx)
                if token:
                    # Converte o token para inteiro e armazena na posição correspondente
                    try:
                        matrix[current_block][X][Y] = int(token)
                    except ValueError:
                        matrix[current_block][X][Y] = 0
                    Y += 1
            X += 1
            # Quando lermos ver_size linhas válidas para o bloco atual
            if X >= ver_size:
                current_block += 1
                X = 0
    return matrix


def generate_output(
    filename1, filename2, matriz1, matriz2, pow_val, ver_size, hor_size
):
    """
    Gera a saída intercalada baseada nas duas matrizes lidas e imprime a saída
    no mesmo formato que o código em SystemVerilog.
    """
    # Corta as strings dos nomes dos arquivos para os 2 primeiros caracteres
    file1 = filename1[:2]
    file2 = filename2[:2]

    # Imprime os parâmetros do pacote
    print("package packMatrix;")
    print("    parameter int NBITS = 32;")
    print("    typedef logic [NBITS-1:0] reg32;")
    print("    typedef reg32 param [0:24];")
    print("    typedef reg32 param2 [0:8];")
    print("endpackage : packMatrix\n")

    print(
        f"\n// X (rows): {ver_size}     Y (coluns): {hor_size}     max shift: {pow_val-1}"
    )
    print(f"module Matrix{file1.upper()}")
    print("   import packMatrix::*;")
    print("    (")
    print("      input  param P,")
    if ver_size == 9:
        print("      output param2 soma")
    else:
        print("      output param soma")
    print("    );\n")

    # Imprime os sinais necessários
    print(f"      param {file1}, {file2};")

    # Prepara a linha com os sinais de shift
    buffer = ""
    for Y in range(hor_size):
        # zera os deslocamentos
        deslocamentos = [0] * pow_val
        for X in range(ver_size):
            for depth in range(1, pow_val):
                if matriz1[depth][X][Y] or matriz2[depth][X][Y]:
                    deslocamentos[depth] = 1
        for depth in range(pow_val):
            if deslocamentos[depth]:
                buffer += f" s{depth}P{Y},"
    # Remove a última vírgula, se existir
    if buffer.endswith(","):
        buffer = buffer[:-1]
    print(f"      reg32 {buffer};\n")

    # Imprime os shifts necessários
    print("      always_comb begin")
    for Y in range(hor_size):
        deslocamentos = [0] * pow_val
        for X in range(ver_size):
            for depth in range(1, pow_val):
                if matriz1[depth][X][Y] or matriz2[depth][X][Y]:
                    deslocamentos[depth] = 1
        for depth in range(pow_val):
            if deslocamentos[depth]:
                # Em Python, usamos f-string para formatação.
                # A expressão {P[{Y}][NBITS-{depth+1}:0]} é ilustrativa, pois em SV a fatia de bits é representada assim.
                # Aqui apenas reproduzimos a lógica da saída.
                zeros = "0" * depth
                print(
                    f"        s{depth}P{Y} = {{P[{Y}][NBITS-{depth+1}:0],  {depth}'b{zeros}}};"
                )
    print("      end\n")

    # Imprime o mapeamento dos CSAs linha a linha
    for X in range(ver_size):
        cont1 = 0
        cont2 = 0
        # Conta as parcelas válidas de cada matriz para a linha X
        for Y in range(hor_size):
            for depth in range(pow_val):
                if matriz1[depth][X][Y] == 1:
                    cont1 += 1
                if matriz2[depth][X][Y] == 1:
                    cont2 += 1

        # Imprime a linha correspondente à primeira matriz
        if cont1:
            # Imprime nome do módulo CSA com base em cont1 e o caractere no índice 1 do nome do arquivo
            sys.stdout.write(f"        CSA_{cont1} s{file1[1]}{X} (")
            for Y in range(hor_size):
                for depth in range(pow_val):
                    if matriz1[depth][X][Y] == 1:
                        if depth == 0:
                            sys.stdout.write(f"P[{Y}], ")
                        else:
                            sys.stdout.write(f"s{depth}P{Y}, ")
            print(f" {file1}[{X}]);")

        # Imprime a linha correspondente à segunda matriz
        if cont2:
            sys.stdout.write(f"        CSA_{cont2} s{file2[1]}{X} (")
            for Y in range(hor_size):
                for depth in range(pow_val):
                    if matriz2[depth][X][Y] == 1:
                        if depth == 0:
                            sys.stdout.write(f"P[{Y}], ")
                        else:
                            sys.stdout.write(f"s{depth}P{Y}, ")
            print(f"{file2}[{X}] );")

        if not cont1:
            print(f"        assign soma[{X}] =  - {file2}[{X}];\n")
        elif not cont2:
            print(f"        assign soma[{X}] =  {file1}[{X}];\n")
        else:
            print(f"        assign soma[{X}] =  {file1}[{X}] - {file2}[{X}];\n")

    print("\nendmodule")


def main(argv):
    # Exibe data atual
    current_time = time.localtime()
    date_str = time.strftime("%d/%m/%Y %H:%M:%S", current_time)
    if len(argv) != 3:
        print(f"{argv[0]}  <arquivos com as 2 matrizes>")
        return

    # Determina os parâmetros a partir do primeiro arquivo
    x, y, pow_val = find_parameters(argv[1])
    print(f"// Date: {date_str}")

    # Aloca as matrizes com as dimensões detectadas
    matriz1 = initialize_matrix(pow_val, x, y)
    matriz2 = initialize_matrix(pow_val, x, y)

    # Lê as duas matrizes dos arquivos
    matriz1 = read_matrix(argv[1], pow_val, x, y)
    matriz2 = read_matrix(argv[2], pow_val, x, y)

    # Gera a saída
    generate_output(argv[1], argv[2], matriz1, matriz2, pow_val, x, y)


if __name__ == "__main__":
    main(sys.argv)
