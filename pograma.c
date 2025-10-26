/* main.c */
#include <stdio.h>
#include <stdlib.h>   // Para atoi()
#include <string.h>   // Para strncmp()
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include "./hps_0.h"  // Deve conter 'PIO_LED_BASE'

// Constantes da Ponte (Light-Weight Bridge)
#define LW_BRIDGE_BASE 0xFF200000
#define LW_BRIDGE_SPAN 0x00005000 

// --- Protótipos da nossa API em Assembly ---
// Dizemos ao C que estas funções existem em outro lugar.
// Todas elas recebem o ponteiro para o PIO de LED.

/**
 * @brief Função 1: Envia o valor 1 (0b0001) para os LEDs.
 */
extern void funcao_enviar_1(volatile int* pio_ptr);

/**
 * @brief Função 2: Envia o valor 2 (0b0010) para os LEDs.
 */
extern void funcao_enviar_2(volatile int* pio_ptr);

/**
 * @brief Função 4: Envia o valor 4 (0b0100) para os LEDs.
 */
extern void funcao_enviar_4(volatile int* pio_ptr);

/**
 * @brief Função 8: Envia o valor 8 (0b1000) para os LEDs.
 */
extern void funcao_enviar_8(volatile int* pio_ptr);

/**
 * @brief Função Apagar: Envia o valor 0 para os LEDs.
 */
extern void funcao_apagar_tudo(volatile int* pio_ptr);

// ------------------------------------------

int main(void) {
    volatile int* led_ptr; // Ponteiro para o PIO de LEDs
    int fd = -1;
    void* lw_virtual;

    // --- Etapa 1 e 2: Mapear a memória (open e mmap) ---
    printf("Iniciando API HPS-FPGA...\n");
    if ((fd = open("/dev/mem", (O_RDWR | O_SYNC))) == -1) {
        printf("ERRO: Nao foi possivel abrir /dev/mem...\n");
        return (-1);
    }

    lw_virtual = mmap(NULL, LW_BRIDGE_SPAN, (PROT_READ | PROT_WRITE),
                      MAP_SHARED, fd, LW_BRIDGE_BASE);
                      
    if (lw_virtual == MAP_FAILED) {
        printf("ERRO: mmap() falhou...\n");
        close(fd);
        return (-1);
    }

    // --- Etapa 3: Calcular o ponteiro específico para o LED ---
    led_ptr = (volatile int*)(lw_virtual + PIO_LED_BASE);

    printf("Ponteiro de LED mapeado. (Base Qsys: 0x%X)\n", PIO_LED_BASE);
    
    // Zera os LEDs ao iniciar
    funcao_apagar_tudo(led_ptr);

    // --- Etapa 4: Loop de Comandos ---
    char buffer[50];
    while (1) {
        printf("\nDigite o COMANDO (1, 2, 4, 8, 'c' para apagar, 'q' para sair): ");

        if (!fgets(buffer, sizeof(buffer), stdin)) {
            break; 
        }

        // --- Aqui está a lógica que você pediu ---
        if (strncmp(buffer, "1", 1) == 0) {
            printf("Chamando 'funcao_enviar_1' da API Assembly...\n");
            funcao_enviar_1(led_ptr);
        } 
        else if (strncmp(buffer, "2", 1) == 0) {
            printf("Chamando 'funcao_enviar_2' da API Assembly...\n");
            funcao_enviar_2(led_ptr);
        }
        else if (strncmp(buffer, "4", 1) == 0) {
            printf("Chamando 'funcao_enviar_4' da API Assembly...\n");
            funcao_enviar_4(led_ptr);
        }
        else if (strncmp(buffer, "8", 1) == 0) {
            printf("Chamando 'funcao_enviar_8' da API Assembly...\n");
            funcao_enviar_8(led_ptr);
        }
        else if (strncmp(buffer, "c", 1) == 0) {
            printf("Chamando 'funcao_apagar_tudo' da API Assembly...\n");
            funcao_apagar_tudo(led_ptr);
        }
        else if (strncmp(buffer, "q", 1) == 0) {
            printf("Saindo...\n");
            break; // Sai do loop
        } 
        else {
            printf("Comando desconhecido.\n");
        }
    }

    // --- Etapa 5: Limpeza ---
    funcao_apagar_tudo(led_ptr); // Desliga ao sair
    munmap(lw_virtual, LW_BRIDGE_SPAN);
    close(fd);

    return 0;
}
