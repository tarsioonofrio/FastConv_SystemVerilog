#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <strings.h>
#include <time.h>

#define TAM 200

int separador(char car) {
    switch (car) {
        case ' ': case ',': case '\n': case '\t': case '\r': return 1;
        default: return 0;
    }
}

int search_word(char *word, int *counter, char *token) {
    int k=0;
    while (separador(word[*counter])) (*counter)++;
    while (!separador(word[*counter]) && word[*counter] != '\0')
        token[k++]=word[(*counter)++];
    token[k]='\0';
    return k;
}

////////////////////////////////////////////////////////////////////////////////
// Função para inicializar a matriz dinamicamente alocada
////////////////////////////////////////////////////////////////////////////////
void initialize_matrix(unsigned int ***matriz, int pow, int hor_size, int ver_size) {
    int depth, Y, X;
    for (depth=0; depth<pow; depth++)
        for (Y=0; Y<hor_size; Y++)
            for (X=0; X<ver_size; X++)
                matriz[depth][Y][X]=0;
}

////////////////////////////////////////////////////////////////////////////////
// Função para encontrar os parâmetros X, Y e pow
////////////////////////////////////////////////////////////////////////////////
void find_parameters(char *filename, int *x, int *y, int *pow) {
    FILE *fp;
    char line[TAM], wd[TAM];
    int i;

    // Inicializa os valores
    *y=0;
    *x=0;
    *pow=0;

    if ((fp=fopen(filename, "r")) == NULL) {
        printf("File %s does not exist\n\n", filename);
        exit(0);
    }

    // Lê o arquivo linha por linha
    while (fgets(line, TAM, fp)) 
        if (line[0] == '0' || line[0] == '1') {  // Verifica se a linha é válida
            if (!(*pow)) {  // Somente processa se pow ainda for zero
                if (!(*y)) {  // Conta a primeira linha para determinar Y
                    i=0;
                    while (search_word(line, &i, wd))
                        (*y)++;
                }
                (*x)++;  // Conta uma linha válida para determinar X
            }
        } else 
            (*pow)++;  // Conta o número de blocos de dados (pow)
    
    fclose(fp);
}

////////////////////////////////////////////////////////////////////////////////
// Função para ler a matriz de um arquivo
////////////////////////////////////////////////////////////////////////////////
void read_matrix(char *filename, unsigned int ***matriz, int pow, int ver_size, int hor_size) {
    FILE *fp;
    char line[TAM], wd[TAM];
    int depth, Y, X, i;

    if ((fp=fopen(filename, "r")) == NULL) {
        printf("File %s does not exist\n\n", filename);
        exit(0);
    }

    for (depth=0; depth<pow; depth++) {
        X=0;
        do {
            fgets(line, TAM, fp);  // lê uma linha com parâmetros
            if (line[0] == '0' || line[0] == '1') {  // linha válida
                Y=0;
                i=0;
                while (search_word(line, &i, wd)) {
                    sscanf(wd, "%d", &(matriz[depth][X][Y]));
                    Y++;
                }
                X++;  // lê uma linha válida
            }
        } while (X<ver_size);
    }

    fclose(fp);
}

////////////////////////////////////////////////////////////////////////////////
// Função para gerar a saída intercalada baseada nas duas matrizes lidas
////////////////////////////////////////////////////////////////////////////////
void generate_output(char *filename1, char *filename2, unsigned int ***matriz1, unsigned int ***matriz2, int pow, int ver_size, int hor_size) {
    int Y, X, depth, deslocamentos[pow];
    char buffer[1024], temp[50]; // buffer para armazenar a saída


    filename1[2]='\0';  // corta a string
    filename2[2]='\0';  // corta a string



    printf("package packMatrix;\n");
    printf("    parameter int NBITS = 32;\n");
    printf("    typedef logic [NBITS-1:0] reg32;\n");
    printf("    typedef reg32 param [0:24];\n");
    printf("    typedef reg32 param2 [0:8];\n");
    printf("endpackage : packMatrix\n\n");   
    
    printf("\n// X (rows): %d     Y (coluns): %d     max shift: %d \n", ver_size, hor_size, pow-1);
    printf("module Matrix%c\n", toupper(filename1[0]));
    printf("   import packMatrix::*;\n");
    printf("    (\n");
    printf("      input  param P,\n");

    if (ver_size==9)
        printf("      output param2 soma\n");
    else
        printf("      output param soma\n");
    printf("    );\n");


    ////////////////////////////////////////////////  imprime os sinais necessários
    printf("\n      param %s, %s;\n", filename1, filename2);
    
    buffer[0] = '\0';
    for (Y=0; Y<hor_size; Y++) {
        // zera os deslocamentos
        for (depth=0; depth<pow; deslocamentos[depth++]=0);
        // varre as colunas
        for (X=0; X<ver_size; X++) 
            for (depth=1; depth<pow; depth++)
                if (matriz1[depth][X][Y] || matriz2[depth][X][Y])
                    deslocamentos[depth]=1;   

        for (depth=0; depth<pow; depth++) 
            if (deslocamentos[depth])
                {  sprintf(temp, " s%dP%d,", depth, Y);
                   strcat(buffer, temp);
                } 
    }
     // Remove a última vírgula
    int len = strlen(buffer);
    if (len > 0 && buffer[len - 1] == ',') {
        buffer[len - 1] = '\0';
    }
    printf("      reg32 %s;\n\n",buffer ); 
    

    /////////////////////////////////////////////// imprime os shifts necessários
    puts("      always_comb begin");
    for (Y=0; Y<hor_size; Y++) {
        // zera os deslocamentos
        for (depth=0; depth<pow; depth++)
            deslocamentos[depth]=0;

        // varre as colunas
        for (X=0; X<ver_size; X++) 
            for (depth=1; depth<pow; depth++)
                if (matriz1[depth][X][Y] || matriz2[depth][X][Y])
                    deslocamentos[depth]=1;   
        
        for (depth=0; depth<pow; depth++) 
            if (deslocamentos[depth])
               { printf("        s%dP%d = {P[%d][NBITS-%d:0],  %d'b",  depth, Y, Y,   depth+1, depth );

                 for(int k=0; k<depth; k++)
                     printf("0");
                 printf("};\n");
               } 
    }
    puts("      end\n");


    /////////////////////////////////////////////// port map dos CSAs  - linha a linha
    for (X=0; X<ver_size; X++)  {
        int cont1=0, cont2=0;

        // Conta as parcelas válidas de cada matriz
        for (Y=0; Y<hor_size; Y++)
            for (depth=0; depth<pow; depth++) {
                if (matriz1[depth][X][Y] == 1)    cont1++;
                if (matriz2[depth][X][Y] == 1)    cont2++;
            }

        // Imprime a linha correspondente à primeira matriz
        if(cont1) {
           printf("        CSA_%d s%c%d (",  cont1, filename1[1], X);
           for (Y=0; Y<hor_size; Y++)
               for (depth=0; depth<pow; depth++)
                   if (matriz1[depth][X][Y] == 1) {
                       if (!depth)
                           printf("P[%d], ", Y);
                       else
                           printf("s%dP%d, ", depth, Y);
                   }
           printf(" %s[%d]);\n", filename1, X);
        }

        // Imprime a linha correspondente à segunda matriz
        if(cont2) {
           printf("        CSA_%d s%c%d (",  cont2, filename2[1], X);
           for (Y=0; Y<hor_size; Y++)
               for (depth=0; depth<pow; depth++)
                   if (matriz2[depth][X][Y] == 1) {
                       if (!depth)
                           printf("P[%d], ", Y);
                       else
                           printf("s%dP%d, ", depth, Y);
                   }
           printf("%s[%d] );\n", filename2, X);
        }

        if(!cont1)
            printf("        assign soma[%d] =  - %s[%d];\n\n",  X, filename2, X);
        else if (!cont2)
            printf("        assign soma[%d] =  %s[%d];\n\n",  X, filename1, X);
        else 
            printf("        assign soma[%d] =  %s[%d] - %s[%d];\n\n",  X, filename1, X, filename2, X);
    }

    printf("\nendmodule");
}

////////////////////////////////////////////////////////////////////////////////
// Função principal
////////////////////////////////////////////////////////////////////////////////
int main(int argc, char *argv[]) {
    unsigned int ***matriz1, ***matriz2;
    char buffer[TAM];
    int x, y, pow;

    time_t t = time(NULL);
    struct tm *tm_info = localtime(&t);
    strftime(buffer, TAM, "%d/%m/%Y %H:%M:%S", tm_info);

    if (argc != 3) {
        printf("%s  <arquivos com as 2 matrizes>\n", argv[0]);
        return 0;
    }

    // Encontra os parâmetros x, y, pow
    find_parameters(argv[1], &x, &y, &pow);  
    printf("// Date: %s\n", buffer);

    // Aloca dinamicamente matriz1 e matriz2
    matriz1=(unsigned int ***)malloc(pow * sizeof(unsigned int **));
    matriz2=(unsigned int ***)malloc(pow * sizeof(unsigned int **));
    for (int i=0; i<pow; i++) {
        matriz1[i]=(unsigned int **)malloc(x * sizeof(unsigned int *));
        matriz2[i]=(unsigned int **)malloc(x * sizeof(unsigned int *));
        for (int j=0; j<x; j++) {
            matriz1[i][j]=(unsigned int *)malloc(y * sizeof(unsigned int));
            matriz2[i][j]=(unsigned int *)malloc(y * sizeof(unsigned int));
        }
    }

    // Inicializa as matrizes
    initialize_matrix(matriz1, pow, x, y);
    initialize_matrix(matriz2, pow, x, y);


    // Ler as duas matrizes
    read_matrix(argv[1], matriz1, pow, x, y);
    read_matrix(argv[2], matriz2, pow, x, y);


    // Gerar a saída 
    generate_output(argv[1], argv[2], matriz1, matriz2, pow, x, y);

    // Libera memória alocada
    for (int i=0; i<pow; i++) {
        for (int j=0; j<x; j++) {
            free(matriz1[i][j]);
            free(matriz2[i][j]);
        }
        free(matriz1[i]);
        free(matriz2[i]);
    }
    free(matriz1);
    free(matriz2);

    puts("\n\n");
    return 1;
}
