/* main.c */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>   // Para strncmp()
#include <fcntl.h>    // Define O_RDWR, O_SYNC (Usado internamente pelo Assembly)
#include <sys/mman.h> // Define MAP_FAILED, PROT_READ/WRITE, MAP_SHARED (Usado internamente e para checagem)
#include <unistd.h>   // Define close() (Usado internamente pelo Assembly)
#include "./hps_0.h"  // Essencial! Deve conter PIO_LED_BASE (e PIO_SW_BASE se existir)

/* --- Protótipos da nossa API em Assembly --- */

/**
 * @brief Inicializa o acesso à ponte FPGA via Assembly.
 * Mapeia a memória física (LW_BRIDGE_BASE) para um espaço virtual.
 * @return Retorna o ponteiro virtual base mapeado em caso de sucesso,
 * ou um ponteiro inválido (comparável a MAP_FAILED) em caso de erro.
 */
extern void* iniciarCoprocessor(void);

/**
 * @brief Libera os recursos (memória mapeada, file descriptor) alocados por iniciarCoprocessor.
 */
extern void encerrarCoprocessor(void);

/**
 * @brief (Função Primitiva Assembly - Opcional para C) Escreve um valor num offset da ponte.
 * Nota: A API Assembly `api_hps_fpga.s` define esta função, mas este C
 * usa funções de mais alto nível (funcao_enviar_X) que chamam write_pio internamente.
 * extern void write_pio(unsigned int offset, unsigned int value);
 */

/**
 * @brief (Função Primitiva Assembly - Opcional para C) Lê um valor de um offset da ponte.
 * Nota: A API Assembly `api_hps_fpga.s` define esta função.
 * extern unsigned int read_pio(unsigned int offset);
 */


/* --- Protótipos das funções de controle de LED (DEFINIDAS EM ASSEMBLY) --- */
/* Estas funções devem ser implementadas em api_hps_fpga.s, usando write_pio */

extern void funcao_enviar_1(volatile int* pio_ptr); // Envia 1 para pio_led
extern void funcao_enviar_2(volatile int* pio_ptr); // Envia 2 para pio_led
extern void funcao_enviar_4(volatile int* pio_ptr); // Envia 4 para pio_led
extern void funcao_enviar_8(volatile int* pio_ptr); // Envia 8 para pio_led
extern void funcao_apagar_tudo(volatile int* pio_ptr); // Envia 0 para pio_led

// ------------------------------------------

int main(void) {
    volatile int* led_ptr = NULL; // Ponteiro para o PIO de LEDs
    // volatile int* sw_ptr  = NULL; // Ponteiro para o PIO de Switches (se existir no .h)
    void* lw_virtual;             // Ponteiro virtual base retornado pela API Assembly

    printf("Iniciando API HPS-FPGA via Assembly...\n");

    // --- Etapa 1: Chamar a função Assembly para mapear a memória ---
    lw_virtual = iniciarCoprocessor();

    // --- Etapa 2: Verificar se o mapeamento foi bem-sucedido ---
    // A função Assembly deve retornar um ponteiro válido ou algo comparável a MAP_FAILED
    if (lw_virtual == MAP_FAILED || lw_virtual == NULL || (long)lw_virtual < 0) {
        printf("ERRO: iniciarCoprocessor() falhou (mmap ou open provavelmente falhou internamente).\n");
        printf("Verifique se o programa foi executado com 'sudo'.\n");
        // Não chamar encerrarCoprocessor aqui, pois a inicialização falhou.
        return (-1);
    } else {
        printf("Sucesso! iniciarCoprocessor() executado.\n");
        printf("Ponteiro virtual base mapeado: %p\n", lw_virtual);
    }

    // --- Etapa 3: Calcular os ponteiros específicos para os PIOs ---
    // Usa o ponteiro base retornado pelo Assembly e os offsets definidos no hps_0.h
    led_ptr = (volatile int*)(lw_virtual + PIO_LED_BASE); // [cite: hps_0.h]
    printf("Ponteiro PIO LED calculado: %p (Offset: 0x%X)\n", led_ptr, PIO_LED_BASE); // [cite: hps_0.h]

    // --- Verificação e cálculo do ponteiro para PIO_SW (se existir) ---
    // !!! Descomente e ajuste esta seção após confirmar o PIO_SW_BASE no seu hps_0.h ou Qsys !!!
    /*
    #ifdef PIO_SW_BASE
        sw_ptr = (volatile int*)(lw_virtual + PIO_SW_BASE);
        printf("Ponteiro PIO SW calculado: %p (Offset: 0x%X)\n", sw_ptr, PIO_SW_BASE);
    #else
        printf("AVISO: PIO_SW_BASE não definido em hps_0.h. Funcionalidade dos switches desabilitada.\n");
    #endif
    */

    // Zera os LEDs ao iniciar, chamando a função Assembly correspondente
    printf("Apagando LEDs...\n");
    funcao_apagar_tudo(led_ptr);

    // --- Etapa 4: Loop de Comandos (Interação com o usuário) ---
    char buffer[50];
    while (1) {
        printf("\nDigite o comando para LED (1, 2, 4, 8, 'c' para apagar, 'q' para sair): ");

        if (!fgets(buffer, sizeof(buffer), stdin)) {
            // Se fgets falhar (ex: Ctrl+D), sai do loop
            printf("Encerrando entrada...\n");
            break;
        }

        // Remove a nova linha (\n) que fgets geralmente adiciona
        buffer[strcspn(buffer, "\n")] = 0;

        if (strcmp(buffer, "1") == 0) {
            printf("Chamando 'funcao_enviar_1'...\n");
            funcao_enviar_1(led_ptr);
        }
        else if (strcmp(buffer, "2") == 0) {
            printf("Chamando 'funcao_enviar_2'...\n");
            funcao_enviar_2(led_ptr);
        }
        else if (strcmp(buffer, "4") == 0) {
            printf("Chamando 'funcao_enviar_4'...\n");
            funcao_enviar_4(led_ptr);
        }
        else if (strcmp(buffer, "8") == 0) {
            printf("Chamando 'funcao_enviar_8'...\n");
            funcao_enviar_8(led_ptr);
        }
        else if (strcmp(buffer, "c") == 0) {
            printf("Chamando 'funcao_apagar_tudo'...\n");
            funcao_apagar_tudo(led_ptr);
        }
        else if (strcmp(buffer, "q") == 0) {
            printf("Saindo do loop de comandos...\n");
            break; // Sai do while(1)
        }
        // --- Leitura dos Switches (Exemplo, se PIO_SW existir) ---
        /*
        #ifdef PIO_SW_BASE
            else if (strcmp(buffer, "s") == 0 && sw_ptr != NULL) {
                 // Implementar a função read_pio na API Assembly se precisar ler
                 // unsigned int switch_value = read_pio(PIO_SW_BASE);
                 // printf("Valor lido dos switches (via read_pio): 0x%X\n", switch_value);

                 // Alternativamente, se tiver uma função Assembly específica:
                 // extern unsigned int ler_switches(volatile int* sw_pio_base_ptr);
                 // unsigned int switch_value = ler_switches(sw_ptr);
                 // printf("Valor lido dos switches (via ler_switches): 0x%X\n", switch_value);

                 printf("Funcionalidade de leitura de switches ainda não implementada na API Assembly chamada pelo C.\n");
            }
        #endif
        */
        else {
            printf("Comando '%s' desconhecido.\n", buffer);
        }
    }

    // --- Etapa 5: Limpeza ---
    printf("Desligando LEDs e liberando recursos via Assembly...\n");
    if (led_ptr != NULL) { // Garante que o ponteiro é válido antes de usar
      funcao_apagar_tudo(led_ptr); // Desliga ao sair
    }

    // Chama a função Assembly para fazer munmap e close via syscalls
    encerrarCoprocessor();

    printf("Recursos liberados. Programa encerrado.\n");

    return 0;
}
