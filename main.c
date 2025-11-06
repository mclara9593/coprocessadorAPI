/*
 * ==================================================================
 * main_unificado.c
 * Lógica principal em C com menu para controle da FPGA.
 *
 * VERSÃO ATUALIZADA: Adicionadas opções de controle de zoom.
 * ==================================================================
 */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h> // Para usleep

// --- Protótipos das Funções em Assembly (de api_pio_unificado.s) ---
// Funções de gerenciamento de memória
extern int init_memory(void);
extern void cleanup_memory(void);

// Funções do barramento de imagem/comando (bits 9:0)
extern void escrever_bus_0_9(uint16_t valor);

// --- NOVOS PROTÓTIPOS ADICIONADOS ---
extern void set_zoom_4x(void);
extern void set_zoom_8x(void);

// Funções do barramento de LEDs (bits 17:10)
extern void funcao_enviar_1(void);
extern void funcao_enviar_2(void);
extern void funcao_enviar_4(void);
extern void funcao_enviar_8(void);
extern void funcao_apagar_tudo(void);
extern void carregar_imagem(void);

// --- Constantes e Estruturas (sem alterações) ---
#define PIXEL_WRITE_ENABLE (1 << 9)

typedef struct {
    uint8_t blue;
    uint8_t green;
    uint8_t red;
    uint8_t reserved;
} ColorPaletteEntry;

static uint32_t read_int(const unsigned char* buffer, int offset) {
    return buffer[offset] | (buffer[offset+1] << 8) | (buffer[offset+2] << 16) | (buffer[offset+3] << 24);
}
static uint16_t read_short(const unsigned char* buffer, int offset) {
    return buffer[offset] | (buffer[offset+1] << 8);
}


// --- Funções de Lógica da Aplicação (sem alterações, exceto pelo menu) ---

void handle_image_mode() {
    char filename[256];
    FILE *image_file = NULL;
    unsigned char bmp_header[54];
    uint32_t data_offset, width, height;
    uint16_t bits_per_pixel;
    long pixel_count = 0;
    long row_padded_size, pixel_data_size;
    unsigned char* pixel_buffer = NULL;
    ColorPaletteEntry color_palette[256];
    int y, x;

    printf("\n--- MODO DE PROCESSAMENTO DE IMAGEM ---\n");
    printf("Digite o nome do arquivo .bmp: ");
    if (!fgets(filename, sizeof(filename), stdin)) return;
    filename[strcspn(filename, "\n")] = 0;

    image_file = fopen(filename, "rb");
    if (image_file == NULL) {
        perror("Erro ao abrir o arquivo de imagem");
        return;
    }
    printf("Arquivo '%s' aberto com sucesso.\n", filename);
    
    if (fread(bmp_header, 1, 54, image_file) != 54) {
        fprintf(stderr, "Erro: Nao foi possivel ler o cabecalho do BMP.\n");
        fclose(image_file); return;
    }
    if (bmp_header[0] != 'B' || bmp_header[1] != 'M') {
        fprintf(stderr, "Erro: O arquivo nao parece ser um BMP valido.\n");
        fclose(image_file); return;
    }

    data_offset = read_int(bmp_header, 10);
    width = read_int(bmp_header, 18);
    height = read_int(bmp_header, 22);
    bits_per_pixel = read_short(bmp_header, 28);
    
    if (bits_per_pixel != 8 && bits_per_pixel != 24) {
        fprintf(stderr, "Erro: Formato de BMP nao suportado (%u bpp).\n", bits_per_pixel);
        fclose(image_file);
        return;
    }

    printf("Info da Imagem: %u x %u, %u bpp.\n", width, height, bits_per_pixel);
    
    fseek(image_file, data_offset, SEEK_SET);
    row_padded_size = (width * bits_per_pixel / 8 + 3) & ~3;
    pixel_data_size = row_padded_size * height;
    
    pixel_buffer = (unsigned char*) malloc(pixel_data_size);
    if (!pixel_buffer) {
        fprintf(stderr, "Erro: Falha ao alocar memoria para a imagem.\n");
        fclose(image_file); return;
    }
    
    if (fread(pixel_buffer, 1, pixel_data_size, image_file) != pixel_data_size) {
        fprintf(stderr, "Erro: Falha ao ler os dados dos pixels da imagem.\n");
        free(pixel_buffer); fclose(image_file); return;
    }
    
    if (bits_per_pixel == 8) {
        fseek(image_file, 54, SEEK_SET);
        if (fread(color_palette, sizeof(ColorPaletteEntry), 256, image_file) != 256) {
             fprintf(stderr, "Erro: Falha ao ler a paleta de cores do arquivo.\n");
             free(pixel_buffer); fclose(image_file); return;
        }
    }
    
    fclose(image_file);
    printf("Enviando pixels para a FPGA na ordem correta...\n");

    for (y = height - 1; y >= 0; y--) {
        for (x = 0; x < width; x++) {
            uint8_t gray_pixel = 0;
            if (bits_per_pixel == 8) {
                uint8_t pixel_index = pixel_buffer[y * row_padded_size + x];
                ColorPaletteEntry color = color_palette[pixel_index];
                gray_pixel = (uint8_t)((color.red * 77 + color.green * 151 + color.blue * 28) >> 8);
            } else {
                long pixel_pos = y * row_padded_size + (x * 3);
                uint8_t blue  = pixel_buffer[pixel_pos];
                uint8_t green = pixel_buffer[pixel_pos + 1];
                uint8_t red   = pixel_buffer[pixel_pos + 2];
                gray_pixel = (uint8_t)((red * 77 + green * 151 + blue * 28) >> 8);
            }
            uint16_t data_to_send = PIXEL_WRITE_ENABLE | gray_pixel;
            escrever_bus_0_9(data_to_send);
            usleep(1);
            escrever_bus_0_9(0);
            pixel_count++;
        }
    }

    free(pixel_buffer);
    printf("\nEnvio concluido!\n");
    printf("Total de pixels enviados: %ld (Esperado: %u)\n", pixel_count, width * height);
}

void handle_algo_select() {
    printf("\n--- MODO INTERATIVO DE CONTROLE DE LEDS ---\n");
    funcao_apagar_tudo();
    char buffer[50];
    while (1) {
        printf("\nDigite o (COMANDO) para selecionar o algoritmo de zoom\n");
        printf("(1) - Replicação de Pixels\n");
        printf("(2) - Zoom In com vizinho mais próximo (abre sub-menu)\n");
        printf("(4) - Zoom Out com vizinho mais próximo\n");
        printf("(8) - Média de blocos\n");
        printf("(c) - Apagar tudo (resetar)\n");
        printf("(q) - Voltar ao menu principal\n");
        printf("Comando: ");
        
        if (!fgets(buffer, sizeof(buffer), stdin)) break;
        
        if (strncmp(buffer, "1", 1) == 0) { 
            printf("C: Chamando funcao_enviar_1()...\n"); 
            funcao_enviar_1(); 
        }
        // --- INÍCIO DA MODIFICAÇÃO REQUISITADA ---
        else if (strncmp(buffer, "2", 1) == 0) {
            
            // 1. Seleciona o algoritmo na FPGA (conforme lógica original)
            printf("C: Chamando funcao_enviar_2() (Algoritmo: Vizinho Mais Próximo)...\n"); 
            funcao_enviar_2(); 
            
            // 2. Pergunta o fator de zoom (nova lógica)
            printf("\n  -> Escolha o FATOR de zoom para 'Vizinho Mais Próximo':\n");
            printf("     (4) - Aplicar Zoom 4x\n");
            printf("     (8) - Aplicar Zoom 8x\n");
            printf("     (v) - Voltar sem alterar fator\n");
            printf("  -> Opcao: ");

            char choice_buffer[10]; // Buffer para a sub-escolha
            if (!fgets(choice_buffer, sizeof(choice_buffer), stdin)) break; // Trata EOF

            if (strncmp(choice_buffer, "4", 1) == 0) {
                printf("C: Chamando set_zoom_4x() do Assembly...\n");
                set_zoom_4x();
                printf("Comando de Zoom 4x enviado.\n");
            } else if (strncmp(choice_buffer, "8", 1) == 0) {
                printf("C: Chamando set_zoom_8x() do Assembly...\n");
                set_zoom_8x();
                printf("Comando de Zoom 8x enviado.\n");
            } else {
                printf("Opcao de zoom invalida ou 'voltar' selecionado. Retornando ao menu de algoritmos...\n");
            }
        }
        // --- FIM DA MODIFICAÇÃO REQUISITADA ---
        else if (strncmp(buffer, "4", 1) == 0) { 
            printf("C: Chamando funcao_enviar_4()...\n"); 
            funcao_enviar_4(); 
        }
        else if (strncmp(buffer, "8", 1) == 0) { 
            printf("C: Chamando funcao_enviar_8()...\n"); 
            funcao_enviar_8(); 
        }
        else if (strncmp(buffer, "c", 1) == 0) { 
            printf("C: Chamando funcao_apagar_tudo()...\n"); 
            funcao_apagar_tudo(); 
        }
        else if (strncmp(buffer, "q", 1) == 0) { 
            printf("Voltando ao menu principal...\n"); 
            break; 
        }
        else { 
            printf("Comando desconhecido.\n"); 
        }
    }
}

/**
 * @brief Mostra o menu principal. (Atualizado com novas opções)
 */
void show_main_menu() {
    // --- MENU ATUALIZADO ---
    printf("\n===== MENU DE CONTROLE HPS-FPGA =====\n");
    printf("1. Enviar Imagem BMP para a FPGA\n");
    printf("2. Entrar no modo de controle de Algoritmos\n");
    printf("3. Carregar imagem de teste (via Assembly)\n");
    printf("4. Sair\n");
    printf("=======================================\n");
    printf("Escolha uma opcao: ");
}

// --- Função Main ---
int main() {
    int choice = 0;
    char input_buffer[10];

    printf("Iniciando programa de controle HPS-FPGA...\n");

    if (init_memory() != 0) {
        perror("Falha ao inicializar a memoria com mmap. Execute como superusuario (sudo)");
        return EXIT_FAILURE;
    }
    printf("Hardware (ponte HPS-FPGA) mapeado com sucesso.\n");
    
    // --- LOOP DO MENU ATUALIZADO ---
    while (choice != 6) { // A opção de sair agora é 6
        show_main_menu();
        if (!fgets(input_buffer, sizeof(input_buffer), stdin)) break;
        choice = atoi(input_buffer);

        switch (choice) {
            case 1:
                handle_image_mode();
                break;
            case 2:
                handle_algo_select();
                break;
            case 3:
                printf("C: Chamando carregar_imagem() do Assembly...\n");
                carregar_imagem();
                printf("Comando enviado.\n");
                break;

            case 4: // Opção de sair atualizada
                printf("Saindo...\n");
                break;
            default:
                printf("Opcao invalida. Tente novamente.\n");
                break;
        }
    }

    printf("\nLimpando e finalizando...\n");
    funcao_apagar_tudo();
    cleanup_memory();
    printf("Recursos liberados. Programa finalizado.\n");

    return EXIT_SUCCESS;
}


