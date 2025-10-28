@Definições da ISA
.syntax unified
.cpu cortex-a9
.arch armv7-a

@ --- Seção de Dados Globais ---
.section .data
.balign 4 @ Garante alinhamento de 4 bytes para as palavras

@ Variáveis globais exportadas (visíveis para o C, se necessário)
.global DEV_MEM
.global FPGA_SPAN
.global FPGA_ADDRS
.global FILE_DESCRIPTOR     @ Adicionada global para clareza (syscall usa)
.global FPGA_BRIDGE

@ Constantes e Variáveis
DEV_MEM:         .asciz "/dev/mem"      @ String para abrir a memória física
FPGA_SPAN:       .word 0x00005000      @ !!! ATUALIZADO !!! Tamanho mapeado (20KB, igual pograma.c)
FPGA_ADDRS:      .word 0               @ Variável para armazenar o ponteiro virtual mapeado
FILE_DESCRIPTOR: .word 0               @ Variável para armazenar o file descriptor de /dev/mem
FPGA_BRIDGE:     .word 0xFF200000      @ Endereço físico base da ponte LWHPS2FPGA

@ --- Seção de Código Executável ---
.section .text
.balign 4 @ Garante alinhamento de 4 bytes para instruções

@ --- OFFSETS DOS PIOS REAIS (Baseado em hps_0.h e Qsys Address Map) ---
.equ PIO_LED_OFFSET,  0x00      @ Confirmado por hps_0.h
@ .equ PIO_SW_OFFSET,   0x10      @ !!! Exemplo - CONFIRME ESTE VALOR NO QSYS ADDRESS MAP !!!
@ --- FIM DOS OFFSETS ---

@ --- Funções Globais (Exportadas para o Linker/C) ---
.global iniciarCoprocessor
.type iniciarCoprocessor, %function @ Define como função para o linker
.global encerrarCoprocessor
.type encerrarCoprocessor, %function
.global write_pio
.type write_pio, %function
.global read_pio
.type read_pio, %function
.global main
.type main, %function


@ --------------------------------------------------------------------------
@ iniciarCoprocessor() -> Retorna ponteiro virtual em r0 ou -1 (MAP_FAILED)
@ Abre /dev/mem e mapeia a ponte FPGA na memória virtual.
@ Salva o file descriptor em FILE_DESCRIPTOR e o ponteiro em FPGA_ADDRS.
@ --------------------------------------------------------------------------
iniciarCoprocessor:
    push {r4, r5, r6, r7, lr} @ Salva registradores que serão modificados e o link register

    @ --- Syscall OPEN (/dev/mem) ---
    @ Argumentos para open(pathname, flags, mode)
    movw  r0, #:lower16:DEV_MEM    @ r0 = Endereço da string "/dev/mem"
    movt  r0, #:upper16:DEV_MEM
    mov   r1, #2                   @ r1 = flags = O_RDWR (2). O_SYNC não é estritamente necessário aqui.
    mov   r2, #0                   @ r2 = mode (ignorado ao abrir device existente)
    mov   r7, #5                   @ r7 = Número da syscall open
    svc   0                        @ Chama o Kernel

    @ Checa por erro no open (retorna valor < 0)
    cmp   r0, #0
    blt   iniciar_falha          @ Se r0 < 0, pula para o tratamento de falha

    @ Salva o file descriptor retornado em r0
    movw  r1, #:lower16:FILE_DESCRIPTOR @ Carrega endereço de FILE_DESCRIPTOR
    movt  r1, #:upper16:FILE_DESCRIPTOR
    str   r0, [r1]               @ Armazena o file descriptor (em r0) na variável global
    mov   r4, r0                 @ Guarda o file descriptor em r4 para usar no mmap

    @ --- Syscall MMAP2 ---
    @ Argumentos para mmap2(addr, length, prot, flags, fd, pgoffset)
    mov   r0, #0                   @ r0 = addr = 0 (deixa o Kernel escolher o endereço virtual)

    movw  r1, #:lower16:FPGA_SPAN  @ Carrega endereço de FPGA_SPAN
    movt  r1, #:upper16:FPGA_SPAN
    ldr   r1, [r1]               @ r1 = length = Carrega o valor de FPGA_SPAN (0x5000)

    mov   r2, #3                   @ r2 = prot = PROT_READ | PROT_WRITE (1 | 2 = 3)
    mov   r3, #1                   @ r3 = flags = MAP_SHARED (1)
    @ r4 já contém o file descriptor (fd)

    movw  r5, #:lower16:FPGA_BRIDGE @ Carrega endereço de FPGA_BRIDGE
    movt  r5, #:upper16:FPGA_BRIDGE
    ldr   r5, [r5]               @ Carrega o endereço físico base (0xFF200000)
    lsr   r5, r5, #12            @ r5 = pgoffset = Desloca 12 bits para direita (divide por 4096) para obter offset em páginas

    @ Nota: A syscall mmap2 espera os argumentos nos registradores r0-r5.
    @ O file descriptor está em r4, pgoffset em r5.
    @ O syscall number vai em r7.

    mov   r7, #192                 @ r7 = Número da syscall mmap2
    svc   0                        @ Chama o Kernel

    @ r0 agora contém o ponteiro virtual mapeado ou um valor de erro (ex: -1)

    @ Salva o ponteiro virtual (ou erro) retornado em r0 na variável global
    movw  r1, #:lower16:FPGA_ADDRS @ Carrega endereço de FPGA_ADDRS
    movt  r1, #:upper16:FPGA_ADDRS
    str   r0, [r1]               @ Armazena o ponteiro/erro (em r0) na variável global

    @ O valor de retorno (ponteiro ou erro) já está em r0, pronto para retornar ao C

iniciar_fim:
    pop {r4, r5, r6, r7, lr}     @ Restaura registradores salvos
    bx lr                        @ Retorna para o chamador (C)

iniciar_falha:
    @ Se open falhou, r0 já contém um código de erro negativo.
    @ O mmap não foi chamado, então FPGA_ADDRS não foi definido.
    @ Apenas retornamos o erro do open.
    @ (Poderíamos opcionalmente setar FPGA_ADDRS para -1 aqui também)
    mov r0, #-1                 @ Garante retorno de -1 (similar a MAP_FAILED)
    b iniciar_fim              @ Pula para o final para restaurar registradores e retornar


@ --------------------------------------------------------------------------
@ encerrarCoprocessor()
@ Libera os recursos mapeados (munmap) e fecha o /dev/mem (close).
@ Lê o ponteiro e o fd das variáveis globais.
@ --------------------------------------------------------------------------
encerrarCoprocessor:
    push {r0, r1, r7, lr}      @ Salva registradores que serão modificados

    @ --- Syscall MUNMAP ---
    @ Argumentos para munmap(addr, length)
    movw  r0, #:lower16:FPGA_ADDRS @ Carrega endereço de FPGA_ADDRS
    movt  r0, #:upper16:FPGA_ADDRS
    ldr   r0, [r0]               @ r0 = addr = Carrega o ponteiro virtual salvo

    movw  r1, #:lower16:FPGA_SPAN  @ Carrega endereço de FPGA_SPAN
    movt  r1, #:upper16:FPGA_SPAN
    ldr   r1, [r1]               @ r1 = length = Carrega o valor de FPGA_SPAN

    mov   r7, #91                  @ r7 = Número da syscall munmap
    svc   0                        @ Chama o Kernel
    @ Ignora valor de retorno do munmap por simplicidade

    @ --- Syscall CLOSE ---
    @ Argumentos para close(fd)
    movw  r0, #:lower16:FILE_DESCRIPTOR @ Carrega endereço de FILE_DESCRIPTOR
    movt  r0, #:upper16:FILE_DESCRIPTOR
    ldr   r0, [r0]               @ r0 = fd = Carrega o file descriptor salvo

    mov   r7, #6                   @ r7 = Número da syscall close
    svc   0                        @ Chama o Kernel
    @ Ignora valor de retorno do close por simplicidade

    pop {r0, r1, r7, lr}       @ Restaura registradores salvos
    bx lr                        @ Retorna para o chamador (C)


@ --------------------------------------------------------------------------
@ write_pio(r0=offset, r1=valor)
@ Escreve 'valor' no endereço (ponteiro_base + offset)
@ --------------------------------------------------------------------------
write_pio:
    push {r2, lr}              @ Salva r2 (usado para endereço) e lr
    movw  r2, #:lower16:FPGA_ADDRS @ Carrega endereço da variável FPGA_ADDRS
    movt  r2, #:upper16:FPGA_ADDRS
    ldr   r2, [r2]               @ r2 = Carrega o PONTEIRO VIRTUAL base (salvo por iniciarCoprocessor)
    add   r2, r2, r0             @ r2 = ponteiro_base + offset (passado em r0)
    str   r1, [r2]               @ Escreve o valor (passado em r1) no endereço final
    pop {r2, lr}               @ Restaura registradores
    bx lr                        @ Retorna


@ --------------------------------------------------------------------------
@ read_pio(r0=offset) -> retorna valor em r0
@ Lê do endereço (ponteiro_base + offset)
@ --------------------------------------------------------------------------
read_pio:
    push {r2, lr}              @ Salva r2 e lr
    movw  r2, #:lower16:FPGA_ADDRS @ Carrega endereço da variável FPGA_ADDRS
    movt  r2, #:upper16:FPGA_ADDRS
    ldr   r2, [r2]               @ r2 = Carrega o PONTEIRO VIRTUAL base
    add   r2, r2, r0             @ r2 = ponteiro_base + offset (passado em r0)
    ldr   r0, [r2]               @ Lê o valor do endereço final para r0 (valor de retorno)
    pop {r2, lr}               @ Restaura registradores
    bx lr                        @ Retorna


@ --- Função de Teste Principal (Adapte conforme necessário) ---
@ Exemplo simples que inicializa, pisca LED 0 e encerra.
@ Para usar o loop interativo, compile com o main.c
main:
    push {lr}                   @ Salva lr pois chamaremos sub-rotinas

    bl iniciarCoprocessor       @ Chama a inicialização
    cmp r0, #0                  @ Verifica se iniciarCoprocessor retornou erro (<0 ou -1)
    blt main_fim                @ Se erro, pula para o fim

    @ Exemplo simples: Acende LED 0 (valor 1)
    mov r1, #1                  @ Valor 1 em r1
    ldr r0, =PIO_LED_OFFSET     @ Offset 0 em r0
    bl write_pio                @ Escreve nos LEDs

    @ (Aqui poderia ter um delay ou outra lógica)

    @ Apaga LEDs antes de encerrar
    mov r1, #0                  @ Valor 0 em r1
    ldr r0, =PIO_LED_OFFSET     @ Offset 0 em r0
    bl write_pio                @ Escreve nos LEDs

    bl encerrarCoprocessor      @ Libera os recursos

main_fim:
    pop {lr}                    @ Restaura lr
    mov r0, #0                  @ Código de saída 0 (sucesso) para o Linux
    mov r7, #1                  @ Número da syscall exit
    svc 0                       @ Termina o programa


@ --- Loop Infinito (Alternativa para main, se não quiser encerrar) ---
@loop_principal:
@    push {r0, r1, lr}
@    ldr  r0, =PIO_SW_OFFSET   @ !! PRECISA CONFIRMAR OFFSET !!
@    bl   read_pio
@    mov  r1, r0
@    ldr  r0, =PIO_LED_OFFSET
@    bl   write_pio
@    pop  {r0, r1, lr}
@    b loop_principal
