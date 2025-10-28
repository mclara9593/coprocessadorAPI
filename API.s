@Definições da ISA
.syntax unified
.cpu cortex-a9
.arch armv7-a

@ Declaração de endereçamento
DEV_MEM:         .asciz "/dev/mem"
FPGA_SPAN:       .word 0x00005000         @ tamanho mapeado 20KB
FPGA_ADDRS:      .word 0               @var globais pra fazer syscall (open e mmap)
FPGA_BRIDGE:     .word 0xFF200000     @ base bridge LWHPS2FPGA (ponte)



@ --- OFFSETS DOS PIOS REAIS (Baseado em hps_0.h e Qsys Address Map) ---
.equ PIO_LED_OFFSET,  0x00      @ Confirmado por hps_0.h 
.equ PIO_SW_OFFSET,   0x??      @ !!! CONFIRME ESTE VALOR NO QSYS ADDRESS MAP !!! 
                                @ (Exemplo: 0x10)
@ --- FIM DOS OFFSETS ---

@ --- Funções Globais (Mantenha as que você precisa) ---
.global iniciarCoprocessor     @ Mantém - essencial para mmap
.global encerrarCoprocessor    @ Mantém - essencial para munmap/close
.global write_pio              @ Mantém - primitiva de escrita
.global read_pio               @ Mantém - primitiva de leitura
.global main                   @ Mantém (ou adapte conforme sua necessidade)
@ Adicione outras funções que você queira criar (ex: acender_led_especifico, ler_switch_especifico)

@ --- Implementação das Funções (Mantenha iniciar, encerrar, write, read como no exemplo anterior) ---

iniciarCoprocessor:
    @ Código original para open() e mmap() via syscalls
    @ ... (igual ao exemplo anterior)
    bx lr

encerrarCoprocessor:
    @ Código original para munmap() e close() via syscalls
    @ ... (igual ao exemplo anterior)
    bx lr

@ write_pio(r0=offset, r1=valor)
@ Escreve 'valor' no endereço (ponteiro_base + offset)
write_pio:
    push {r2, lr}
    movw  r2, #:lower16:FPGA_ADDRS @ Carrega endereço da variável FPGA_ADDRS
    movt  r2, #:upper16:FPGA_ADDRS
    ldr   r2, [r2]             @ Carrega o PONTEIRO VIRTUAL base (salvo por iniciarCoprocessor)
    add   r2, r2, r0           @ Adiciona o offset (passado em r0) ao ponteiro base
    str   r1, [r2]             @ Escreve o valor (passado em r1) no endereço final
    pop {r2, lr}
    bx lr

@ read_pio(r0=offset) -> retorna valor em r0
@ Lê do endereço (ponteiro_base + offset)
read_pio:
    push {r2, lr}
    movw  r2, #:lower16:FPGA_ADDRS @ Carrega endereço da variável FPGA_ADDRS
    movt  r2, #:upper16:FPGA_ADDRS
    ldr   r2, [r2]             @ Carrega o PONTEIRO VIRTUAL base
    add   r2, r2, r0           @ Adiciona o offset (passado em r0)
    ldr   r0, [r2]             @ Lê o valor do endereço final para r0
    pop {r2, lr}
    bx lr

@ --- Função de Teste Principal (Adapte conforme necessário) ---
main:
    bl iniciarCoprocessor @ Primeiro, mapeia a memória

    @ Exemplo: Ler switches e acender LEDs correspondentes
loop_principal:
    push {r0, r1, lr}      @ Salva registradores que vamos usar
    ldr  r0, =PIO_SW_OFFSET @ Passa o offset do pio_sw para r0
    bl   read_pio          @ Chama read_pio, resultado (valor dos switches) volta em r0
                           @ (Assumindo que read_pio retorna em r0)
    mov  r1, r0            @ Copia o valor lido (switches) para r1 (será o valor a escrever)
    ldr  r0, =PIO_LED_OFFSET @ Passa o offset do pio_led para r0
    bl   write_pio         @ Chama write_pio(offset_led, valor_switches)
    pop  {r0, r1, lr}      @ Restaura registradores

    b loop_principal       @ Loop infinito

    @ (Nunca chega aqui no exemplo de loop infinito)
    @ bl encerrarCoprocessor 
    @ bx lr @ (ou syscall para exit)






