#ifndef API_FPGA_H
#define API_FPGA_H

#include <stdint.h> // Necessário para uint16_t e void

/**
 * ==================================================================
 * PROTÓTIPOS DAS FUNÇÕES DE API EM ASSEMBLY
 * Implementados em api_pio_unificado.s
 * ==================================================================
 */

// --- Funções de gerenciamento de memória ---
/**
 * @brief Inicializa o mapeamento de memória para comunicação HPS-FPGA.
 * @return 0 em caso de sucesso, ou -1 em caso de falha.
 */
extern int init_memory(void);

/**
 * @brief Limpa e desmapeia a memória de comunicação HPS-FPGA.
 */
extern void cleanup_memory(void);

// --- Funções de controle do barramento de imagem/comando (bits 9:0) ---
/**
 * @brief Escreve um valor de 10 bits (pixel/comando) no barramento de dados para a FPGA.
 * @param valor O valor de 10 bits (uint16_t) a ser escrito.
 */
extern void escrever_bus_0_9(uint16_t valor);

// --- Funções de controle de Zoom (NOVOS) ---
/**
 * @brief Envia o comando para configurar o zoom para 4x.
 */
extern void set_zoom_4x(void);

/**
 * @brief Envia o comando para configurar o zoom para 8x.
 */
extern void set_zoom_8x(void);

// --- Funções de controle do barramento de LEDs/Algoritmos (bits 17:10) ---
/**
 * @brief Envia o comando para selecionar o Algoritmo 1 (Replicação de Pixels).
 */
extern void funcao_enviar_1(void);

/**
 * @brief Envia o comando para selecionar o Algoritmo 2 (Zoom In - Vizinho Mais Próximo).
 */
extern void funcao_enviar_2(void);

/**
 * @brief Envia o comando para selecionar o Algoritmo 4 (Zoom Out - Vizinho Mais Próximo).
 */
extern void funcao_enviar_4(void);

/**
 * @brief Envia o comando para selecionar o Algoritmo 8 (Média de blocos).
 */
extern void funcao_enviar_8(void);

/**
 * @brief Envia o comando para apagar/resetar todos os indicadores (LEDs/Algoritmo).
 */
extern void funcao_apagar_tudo(void);

/**
 * @brief Carrega uma imagem de teste pré-definida via lógica Assembly.
 */
extern void carregar_imagem(void);

#endif // API_FPGA_H