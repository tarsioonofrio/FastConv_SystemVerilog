module Control
  import pack_def::*;
  import pack_typedef::*;
  import pack_param::*;
#(
    parameter int NADDR            = 16,
    parameter int NBITS            = 20,
    parameter int LATENCY          = 1,
    parameter int ROM              = 0,
    parameter int QUANT            = 8,
    parameter int N_WINDOW         = 10,
    parameter int N_CHANNEL_IN     = 1,
    parameter int N_CHANNEL_OUT    = 1,
    parameter int FEAT_INPUT_SIZE  = 32,
    parameter int FEAT_OUTPUT_SIZE = 30,
    parameter int LAST_WINDOW      = 0
) (
    input  logic clk,
    input  logic reset,

    input  logic p_start,
    output logic p_end,
    output logic p_conv_start,
    input  logic p_conv_end,

    output type_input  p_input,
    output type_weight p_weight,
    input  type_output p_output,

    output logic p_read_en,
    output logic[NADDR-1:0] p_read_addr,
    input  logic_vector p_read_data,
    input  logic p_read_valid,

    output logic p_write_en,
    output logic[NADDR-1:0] p_write_addr,
    output logic_vector p_write_data
);

  timeunit 1ns; timeprecision 1ps;

  typedef enum {
    IDLE_CONTROL,
    BIAS,
    WEIGHT,
    FEAT_INPUT,
    END_CONTROL
  } state_input_type;

  typedef enum {
    IDLE_OUTPUT,
    FEAT_OUTPUT
  } state_output_type;

  state_input_type current_st_input, next_st_input;
  state_output_type current_st_output, next_st_output;

  // contador de leitura de pesos
  logic [$clog2(M1_SIZE*M2_SIZE)-1:0] r_count_wh;
  // contador de leitura de features de entrada
  logic [$clog2(C1_SIZE*C2_SIZE)-1:0] r_count_fin;
  // contador de leitura de features de saída
  logic [$clog2(A1_SIZE*A2_SIZE)-1:0] r_count_fout;
  // contador de leitura de bias, como o bias é 1 o tamanho de memória zera e por isso ele não será usado por enquanto
  // logic [$clog2(N_CHANNEL_OUT)-1:0] r_addr_bias;
  //  dummy version of r_addr_bias
  logic [2:0] r_addr_bias;
  // registrador de endereço base dos pesos
  logic [$clog2(M1_SIZE * M2_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT)-1:0] r_addr_wh;  
  // registrador de endereço base das features de entrada
  logic [$clog2(N_CHANNEL_IN * FEAT_INPUT_SIZE * FEAT_INPUT_SIZE)-1:0] r_addr_fin;
  // registrador de endereço base das features de saída
  logic [$clog2(N_CHANNEL_OUT * FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE)-1:0] r_addr_fout;
  // contador total de janelas processadas (na leitura)
  logic [$clog2(N_WINDOW * N_WINDOW * N_CHANNEL_OUT * N_CHANNEL_IN)-1:0] r_window;

  // Contador de janelas lidas na linhas, usado para indicar a mudança na atualização dos endereços de leitura e para o fim do reuso 
  logic [$clog2(N_WINDOW):0] r_window_in;
  // Contador de janelas escritas na linhas, usado para indicar a mudança na atualização dos endereços de escrita 
  logic [$clog2(N_WINDOW):0] r_window_out;

  // Fio que indica o fim da linha na memória de leitura
  logic w_end_line_in;
  // Fio que indica o fim da linha na memória de escrita
  logic w_end_line_out;
  // Fio de fim de leitura de pesos
  logic w_end_fin;
  // Fio que indica que o buffer de entrada foi totalmente preenchido 
  logic w_end_fout;
  // Fio com o endereço atual das features de entrada
  logic[NADDR-1:0] w_addr_fin;

  logic r_read_en;
  
  // banco de registradores das features de entrada
  type_input  r_feat_in;
  // banco de registradores do kernel (pesos)
  type_weight r_weight;
  // banco de registradores das features de saída
  type_output r_feat_out;

  // lógica sequencial que atualiza as máquinas de estados
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      current_st_input  <= IDLE_CONTROL;
      current_st_output <= IDLE_OUTPUT;
    end else begin
      current_st_input  <= next_st_input;
      current_st_output <= next_st_output;
    end
  end

  // lógica combinacional que redireciona fios ou registradores para as portas de saída 
  always_comb begin
    p_input      = r_feat_in;
    p_weight     = r_weight;
    p_write_data = r_feat_out[r_count_fout];
    p_end        = (current_st_input == END_CONTROL) ? 1'b1 : 1'b0;
    p_conv_start = w_end_fin;
  end

  // lógica combinacional que detecta o fim da linha de leitura (entrada) e escrita (saída)
  always_comb begin
    if (r_window_in < N_WINDOW - 1)
      w_end_line_in = 1'b0;
    else
      w_end_line_in = 1'b1;

    if (r_window_out < N_WINDOW - 1)
      w_end_line_out = 1'b0;
    else
      w_end_line_out = 1'b1;
  end

  // lógica combinacional que detecta que o buffer de entrada foi totalmente preenchido e a convolução pode ser iniciada.
  always_comb begin
    if (r_count_fin == (C1_SIZE * C2_SIZE))
      w_end_fin = 1'b1;
    else
      w_end_fin = 1'b0;
  end

  // lógica combinacional que atualiza a máquina de estados de entrada (leitura)
  always_comb begin
    next_st_input  = current_st_input;
    unique case (current_st_input)
      // IDLE_CONTROL
      // Fica parado aguardando o start para iniciar a leitura dos dados dos pesos e depois os dados de entrada, nesse momento viés não está sendo usado
      default: begin
        if (p_start)
          next_st_input = WEIGHT;
          // next_st_input = BIAS;
      end
      BIAS: begin
        next_st_input = WEIGHT;
      end
      // Aguarda o fim da leitura dos dados do kernel (pesos) referentes ao canal de entrada e saída necessários para fazer a convolução, e depois muda para o estado onde inicia a leitura dos dados de entrada.
      WEIGHT: begin
        if (r_count_wh == (M1_SIZE * M2_SIZE) - 1) begin
          next_st_input = FEAT_INPUT;
        end
      end
      // Aguarda o sinal alertando que o banco de registrados dos dados de entrada está cheio, dependendo de quantas janelas já foram lidas a máquina de estados continua lendo dados de entrada, lê pesos, viés, ou encerra o processamento.
      FEAT_INPUT: begin
        if (w_end_fin) begin
          // caso tenha lido todas as janelas dos canais de entrada e saída encerra o processamento
          if (r_window == N_WINDOW * N_WINDOW * N_CHANNEL_OUT * N_CHANNEL_IN)
            next_st_input = END_CONTROL;
          else
          // caso tenha lido as janelas dos canais de saída carrega o bias
          // if (r_window == N_WINDOW * N_WINDOW * N_CHANNEL_OUT)
          //  next_st_input = BIAS;
          // else
          // caso todas as janelas de um canal de entrada então carrega novos pesos
          if (r_window == N_WINDOW * N_WINDOW)
            next_st_input = WEIGHT;
          else
          // caso nenhuma dessas situações tenha se verificado então continua lendo dados de entrada
            next_st_input = FEAT_INPUT;
        end
      end
    endcase
  end

  // lógica combinacional que atualiza a máquina de estados de saída (escrita)
  always_comb begin
    next_st_output = current_st_output;
    unique case (current_st_output)
      // Fica parado aguardando o sinal que a convolução terminou.
      IDLE_OUTPUT: begin
        w_end_fout = 1'b0;
        p_write_en = 1'b0;
        if (p_conv_end)
          next_st_output = FEAT_OUTPUT;
      end
      // Avisa que vai iniciar a escrita dos dados de saída, aguarda o fim da escrita, quando chegar na última escrita avisa que terminou a escrita de dados.
      FEAT_OUTPUT: begin
        p_write_en = 1'b1;
        if (r_count_fout == (A1_SIZE * A2_SIZE) - 1) begin
          next_st_output = IDLE_OUTPUT;
          w_end_fout = 1'b1;
        end else
          w_end_fout = 1'b0;
      end
    endcase
  end

  // lógica combinacional que atualiza os endereços de escrita conforme o contador dos dados de saída 
  always_comb begin
    unique case (r_count_fout)
      default: p_write_addr = r_addr_fout + 0;
      1: p_write_addr = r_addr_fout + 1;
      2: p_write_addr = r_addr_fout + 2;

      3: p_write_addr = r_addr_fout + FEAT_OUTPUT_SIZE + 0;
      4: p_write_addr = r_addr_fout + FEAT_OUTPUT_SIZE + 1;
      5: p_write_addr = r_addr_fout + FEAT_OUTPUT_SIZE + 2;

      6: p_write_addr = r_addr_fout + FEAT_OUTPUT_SIZE * 2 + 0;
      7: p_write_addr = r_addr_fout + FEAT_OUTPUT_SIZE * 2 + 1;
      8: p_write_addr = r_addr_fout + FEAT_OUTPUT_SIZE * 2 + 2;
    endcase
  end

  // lógica combinacional que atualiza os endereços de leitura dos dados de entrada conforme seu contador 
  always_comb begin
    unique case (r_count_fin)
      default: w_addr_fin = r_addr_fin + 0; // 00
      01: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE + 0; // 05
      02: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 2 + 0; // 10
      03: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 3 + 0; // 15
      04: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 4 + 0; // 20

      05: w_addr_fin = r_addr_fin + 1; // 01
      06: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE + 1; // 06
      07: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 2 + 1; // 11
      08: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 3 + 1; // 16
      09: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 4 + 1; // 21

      10: w_addr_fin = r_addr_fin + 2; // 02
      11: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE + 2; // 07
      12: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 2 + 2; // 12
      13: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 3 + 2; // 17
      14: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 4 + 2; // 22

      15: w_addr_fin = r_addr_fin + 3; // 03
      16: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE + 3; // 08
      17: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 2 + 3; // 13
      18: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 3 + 3; // 18
      19: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 4 + 3; // 23

      20: w_addr_fin = r_addr_fin + 4; // 04
      21: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE + 4; // 09
      22: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 2 + 4; // 14
      23: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 3 + 4; // 19
      24: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 4 + 4; // 24
    endcase
  end

  // lógica combinacional que faz um mux para selecionar quais dados devem ser lidos: se kernel, bias, ou feature input, ou nada conforme máquina de estados de entrada
  always_comb begin
    unique case (current_st_input)
      BIAS: begin
        p_read_addr = r_addr_bias;
        p_read_en = 1'b0;
      end
      WEIGHT: begin
        p_read_addr = r_addr_wh;
        p_read_en = r_read_en;
      end
      FEAT_INPUT: begin
        p_read_addr = w_addr_fin;
        p_read_en = r_read_en;
      end
      default: begin
        p_read_addr = 0;
        p_read_en = 1'b0;
      end
    endcase
  end

  // lógica sequêncial que atualiza os registradores da maquina de estados de entrada (leitura)
  always_ff @(posedge clk) begin
    if (reset) begin
      r_read_en    <= 1'b0;
      // posição inicial do bias na memória é 0
      r_addr_bias  <= 0;
      // posição inicial do kernel na memória é logo após o bias
      r_addr_wh    <= N_CHANNEL_OUT;
      // posição inicial das features de entrada na memória é logo após o kernel
      r_addr_fin   <= N_CHANNEL_OUT + M1_SIZE * M2_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT;
      r_count_wh   <= 0;
      r_count_fin  <= 0;
      r_window     <= 0;
      r_window_in  <= 0;
      r_weight     <= '{default: '0};
      r_feat_in    <= '{default: '0};
    end else begin
      unique case (current_st_input)
        default: begin end
        IDLE_CONTROL: begin
          r_read_en   <= 1'b0;
          r_addr_bias <= 0;
          r_addr_wh   <= N_CHANNEL_OUT;
          r_addr_fin  <= N_CHANNEL_OUT + M1_SIZE * M2_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT;
          r_count_wh  <= 0;
          r_count_fin <= 0;
          r_window    <= 0;
          r_window_in <= 0;
          r_weight    <= '{default: '0};
          r_feat_in   <= '{default: '0};
        end
        // Cada vez que estiver no bias lê somente um endereço e avança
        BIAS: begin
          r_addr_bias <= r_addr_bias + 1;
        end
        // A cada ciclo avança um endereço do kernel e do contador, e armazena o valor retornado pela memória na posição correta do vetor conforme o contador
        WEIGHT: begin
          r_read_en   <= 1'b1;
          r_count_fin <= 0;
          if (p_read_valid) begin
            r_addr_wh            <= r_addr_wh + 1;
            r_count_wh           <= r_count_wh + 1;
            r_weight[r_count_wh] <= p_read_data;
          end
        end
        // A cada ciclo avança um endereço dos dados de entrada e do contador, armazena o valor retornado pela memória na posição correta do vetor conforme o contador
        FEAT_INPUT: begin
          r_read_en  <= 1'b1;
          r_count_wh <= 0;
          if (p_read_valid) begin
            r_count_fin                     <= r_count_fin + 1;
            r_feat_in[c_index[r_count_fin]] <= p_read_data;
          end
          
          // Caso o buffer dos dados de entrada esteja cheio incrementa o contador de janelas totais
          if(w_end_fin)
            r_window <= r_window + 1;

          // Caso o buffer dos dados de entrada esteja cheio e tenha chegado até o final da linha dos dados de entrada, então:
          // - reseta o contador de janelas de entrada, 
          // - reseta o contador de features de entrada (que serão lidas) para zero, indicando que não haverá reaproveitamento
          // - Pula verticalmente o endereço base da memória para o primeiro endereço da primeira janela duas ou mais linhas abaixo, há sobreposição de linhas entre essa janela e as anteriores, sem reaproveitamento vertical
          if (w_end_fin && w_end_line_in) begin
            r_window_in <= 0;
            r_count_fin <= 0;
            r_addr_fin  <= r_addr_fin + C1_SIZE + FEAT_INPUT_SIZE * (A1_SIZE - 1);
          // Caso o buffer dos dados de entrada esteja cheio e não tenha chegado até o final da linha dos dados de entrada, então:
          // - incrementa o contador de janelas de entrada, 
          // -posiciona o contador de features de entrada (que serão lidas) para a coluna correspondente (no mínimo segunda coluna), indicando que haverá reaproveitamento
          // - posiciona ponteiro de entrada para o início da próxima linha            
          end else if (w_end_fin && !w_end_line_in) begin
            r_window_in <= r_window_in + 1;
            // r_count_fin <= 10;
            r_count_fin <= C1_SIZE * (C1_SIZE - A1_SIZE);
            r_addr_fin  <= r_addr_fin + A1_SIZE;

            // TODO perform test using an index table
            r_feat_in[00] <= r_feat_in[03];
            r_feat_in[01] <= r_feat_in[04];

            r_feat_in[05] <= r_feat_in[08];
            r_feat_in[06] <= r_feat_in[09];

            r_feat_in[10] <= r_feat_in[13];
            r_feat_in[11] <= r_feat_in[14];

            r_feat_in[15] <= r_feat_in[18];
            r_feat_in[16] <= r_feat_in[19];

            r_feat_in[20] <= r_feat_in[23];
            r_feat_in[21] <= r_feat_in[24];
          end
        end
      endcase
    end
  end

  // lógica sequêncial que atualiza os registradores da máquina de estados de saída (escrita)
  always_ff @(posedge clk) begin
    if (reset) begin
      r_addr_fout  <= 0;
      r_count_fout <= 0;
      r_window_out <= 0;
      r_feat_out   <= '{default: '0};
    end else begin
      unique case (current_st_output)
        // Mantem o contador de dados de saída em zero e aguarda sinal que a convolução acabou, caso positivo direciona dados das features de saída para o banco de registradores correspondentes
        IDLE_OUTPUT: begin
          r_count_fout <= 0;
          if (p_conv_end)
            r_feat_out <= p_output;
        end
        // Escreve dados de saída na memória
        FEAT_OUTPUT: begin
          //  A cada ciclo incrementa o contador de dados de saída que indica qual posição do banco de registradores de saída deve ser escrito na memória
          r_count_fout <= r_count_fout + 1;
          // Se todos os dados de saída foram escritos na memória e a linha chegou ao fim, então: 
          // - Zera o contador de dados de saída
          // - Pula verticalmente o endereço base da memória para o primeiro endereço da primeira janela duas ou mais linhas abaixo, sem sobreposição de linhas entre essa janela e as anteriores
          if (w_end_fout && w_end_line_out) begin
            r_window_out <= 0;
            r_addr_fout  <= r_addr_fout + A1_SIZE + FEAT_OUTPUT_SIZE * (A1_SIZE - 1);
          // Se todos os dados de saída foram escritos na memória e a linha não chegou ao fim, então: 
          // - incrementa o contador de dados de saída
          // - Pula horizontalmente o endereço base dos dados de escrita (saída) para o primeiro endereço da próxima janela.
          end else if (w_end_fout && !w_end_line_out) begin
            r_window_out <= r_window_out + 1;
            r_addr_fout  <= r_addr_fout + A1_SIZE;
          end
        end
      endcase
    end
  end
endmodule
