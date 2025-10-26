/* api_asm.s */
/* API em Assembly com funções dedicadas para o PIO de LED */

    .syntax unified  @ Usa a sintaxe moderna
    .arm             @ Estamos compilando para modo ARM (32 bits)
    .text            @ Indica que é código


@TESTE OK A API É O OUTRO ARQUIVO

/* -------------------------------------------
 * void funcao_enviar_1(volatile int* pio_ptr)
 * Envia o valor 1 (0b0001)
 * r0 chega com o ponteiro 'pio_ptr'
 * ------------------------------------------- */
    .global funcao_enviar_1    @ Torna a função visível para o C
    .func funcao_enviar_1      @ Define o início da função
funcao_enviar_1:
    push {r1, lr}      @ Salva r1 (que vamos usar) e lr (retorno)
    
    mov r1, #1         @ Coloca o valor 1 (binário 0001) em r1
    
    str r1, [r0]       @ Escreve o valor (r1) no endereço (r0)
    
    pop {r1, lr}       @ Restaura os registradores
    bx lr              @ Retorna para o C
    .endfunc

/* -------------------------------------------
 * void funcao_enviar_2(volatile int* pio_ptr)
 * Envia o valor 2 (0b0010)
 * ------------------------------------------- */
    .global funcao_enviar_2
    .func funcao_enviar_2
funcao_enviar_2:
    push {r1, lr}
    mov r1, #2         @ Coloca o valor 2 (binário 0010) em r1
    str r1, [r0]
    pop {r1, lr}
    bx lr
    .endfunc

/* -------------------------------------------
 * void funcao_enviar_4(volatile int* pio_ptr)
 * Envia o valor 4 (0b0100)
 * ------------------------------------------- */
    .global funcao_enviar_4
    .func funcao_enviar_4
funcao_enviar_4:
    push {r1, lr}
    mov r1, #4         @ Coloca o valor 4 (binário 0100) em r1
    str r1, [r0]
    pop {r1, lr}
    bx lr
    .endfunc
    
/* -------------------------------------------
 * void funcao_enviar_8(volatile int* pio_ptr)
 * Envia o valor 8 (0b1000)
 * ------------------------------------------- */
    .global funcao_enviar_8
    .func funcao_enviar_8
funcao_enviar_8:
    push {r1, lr}
    mov r1, #8         @ Coloca o valor 8 (binário 1000) em r1
    str r1, [r0]
    pop {r1, lr}
    bx lr
    .endfunc
    
/* -------------------------------------------
 * void funcao_apagar_tudo(volatile int* pio_ptr)
 * Envia o valor 0 (0b0000)
 * ------------------------------------------- */
    .global funcao_apagar_tudo
    .func funcao_apagar_tudo
funcao_apagar_tudo:
    push {r1, lr}
    mov r1, #0         @ Coloca o valor 0 (zero) em r1
    str r1, [r0]
    pop {r1, lr}
    bx lr
    .endfunc