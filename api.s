@ ==================================================================
@ api_pio_unificado.s
@ Biblioteca Assembly unificada para controlar dois barramentos
@ de um mesmo periférico PIO na ponte HPS-FPGA.
@ ==================================================================
.syntax unified
.thumb
.text

@ ========== CONSTANTES GLOBAIS ==========
.equ LW_BRIDGE_BASE,    0xFF200000    
.equ LW_BRIDGE_SPAN,    0x00020000    
.equ PIO_DATA_OFFSET,   0x00000000
.equ PIO_BUS_0_9_MASK,  0x000003FF
.equ PIO_BUS_10_17_MASK, 0x0003FC00
.equ O_RDWR,            0x0002
.equ O_SYNC,            0x00101000
.equ PROT_READ,         0x1
.equ PROT_WRITE,        0x2
.equ MAP_SHARED,        0x01

@ ========== DADOS GLOBAIS ==========
.data
dev_mem_path:      .asciz "/dev/mem"
.align 4
asm_lw_virtual_base: .word 0
asm_mem_fd:          .word -1
asm_pio_current_state: .word 0

@ ==================================================================
@ SEÇÃO DE INICIALIZAÇÃO E LIMPEZA DA MEMÓRIA

@ ==================================================================
.global init_memory
.type init_memory, %function
init_memory:
    push {r4, r5, lr}
    ldr r0, =dev_mem_path
    ldr r1, =(O_RDWR | O_SYNC)
    bl open
    cmp r0, #0
    blt init_error
    mov r4, r0
    ldr r1, =asm_mem_fd
    str r0, [r1]
    mov r0, #0
    ldr r1, =LW_BRIDGE_SPAN
    ldr r2, =(PROT_READ | PROT_WRITE)
    ldr r3, =MAP_SHARED
    ldr r5, =LW_BRIDGE_BASE
    push {r4, r5}
    bl mmap
    add sp, sp, #8
    cmn r0, #1
    beq init_error_mmap
    ldr r1, =asm_lw_virtual_base
    str r0, [r1]
    mov r0, #0
    b init_exit
init_error_mmap:
    ldr r0, =asm_mem_fd
    ldr r0, [r0]
    bl close
init_error:
    mov r0, #-1
init_exit:
    pop {r4, r5, lr}
    bx lr
.size init_memory, .-init_memory

.global cleanup_memory
.type cleanup_memory, %function
cleanup_memory:
    push {lr}
    ldr r0, =asm_lw_virtual_base
    ldr r0, [r0]
    ldr r1, =LW_BRIDGE_SPAN
    bl munmap
    ldr r0, =asm_mem_fd
    ldr r0, [r0]
    bl close
    pop {lr}
    bx lr
.size cleanup_memory, .-cleanup_memory

@ ==================================================================
@ FUNÇÃO HELPER INTERNA PARA ESCRITA NO PIO

@ ==================================================================
write_pio_masked:
    push {r2, r3, r4, lr}
    ldr r2, =asm_pio_current_state
    ldr r3, [r2]
    bic r3, r3, r1
    and r0, r0, r1
    orr r3, r3, r0
    str r3, [r2]
    ldr r4, =asm_lw_virtual_base
    ldr r4, [r4]
    add r4, r4, #PIO_DATA_OFFSET
    str r3, [r4]
    pop {r2, r3, r4, lr}
    bx lr

@ ==================================================================
@ FUNÇÕES DE CONTROLE DO BARRAMENTO 1 (Bits 9:0)
@ ==================================================================
.global escrever_bus_0_9
.type escrever_bus_0_9, %function
escrever_bus_0_9:
    push {r4, lr}
    ldr r1, =PIO_BUS_0_9_MASK
    bl write_pio_masked
    pop {r4, lr}
    bx lr
.size escrever_bus_0_9, .-escrever_bus_0_9

@ --- FUNÇÕES DE ZOOM COM A CORREÇÃO ---
@ ------------------------------------------------------------------
@ void set_zoom_4x(void) -> Envia 0b0100000001 (0x101)
@ ------------------------------------------------------------------
.global set_zoom_4x
.type set_zoom_4x, %function
set_zoom_4x:
    push {r4, lr}
    ldr r0, =0x8400            
    ldr r1, =PIO_BUS_10_17_MASK
    bl write_pio_masked
    pop {r4, lr}
    bx lr
.size set_zoom_4x, .-set_zoom_4x

@ ------------------------------------------------------------------
@ void set_zoom_8x(void) -> Envia 0b0110000001 (0x181)
@ ------------------------------------------------------------------
.global set_zoom_8x
.type set_zoom_8x, %function
set_zoom_8x:
    push {r4, lr}
    ldr r0, =0x10400           
    ldr r1, =PIO_BUS_10_17_MASK
    bl write_pio_masked
    pop {r4, lr}
    bx lr
.size set_zoom_8x, .-set_zoom_8x

@ ==================================================================
@ FUNÇÕES DE CONTROLE DO BARRAMENTO 2 (Bits 17:10)

@ ==================================================================
.global funcao_enviar_1
.type funcao_enviar_1, %function
funcao_enviar_1:
    push {r4, lr}
    mov r0, #(1 << 10)
    ldr r1, =PIO_BUS_10_17_MASK
    bl write_pio_masked
    pop {r4, lr}
    bx lr
.size funcao_enviar_1, .-funcao_enviar_1

.global funcao_enviar_2
.type funcao_enviar_2, %function
funcao_enviar_2:
    push {r4, lr}
    mov r0, #(2 << 10)
    ldr r1, =PIO_BUS_10_17_MASK
    bl write_pio_masked
    pop {r4, lr}
    bx lr
.size funcao_enviar_2, .-funcao_enviar_2

.global funcao_enviar_4
.type funcao_enviar_4, %function
funcao_enviar_4:
    push {r4, lr}
    mov r0, #(4 << 10)
    ldr r1, =PIO_BUS_10_17_MASK
    bl write_pio_masked
    pop {r4, lr}
    bx lr
.size funcao_enviar_4, .-funcao_enviar_4

.global funcao_enviar_8
.type funcao_enviar_8, %function
funcao_enviar_8:
    push {r4, lr}
    mov r0, #(8 << 10)
    ldr r1, =PIO_BUS_10_17_MASK
    bl write_pio_masked
    pop {r4, lr}
    bx lr
.size funcao_enviar_8, .-funcao_enviar_8

.global carregar_imagem
.type carregar_imagem, %function
carregar_imagem:
    push {r4, lr}
    mov r0, #0b10101010
    lsl r0, r0, #10
    ldr r1, =PIO_BUS_10_17_MASK
    bl write_pio_masked
    pop {r4, lr}
    bx lr
.size carregar_imagem, .-carregar_imagem

.global funcao_apagar_tudo
.type funcao_apagar_tudo, %function
funcao_apagar_tudo:
    push {r4, lr}
    mov r0, #0
    ldr r1, =(PIO_BUS_0_9_MASK | PIO_BUS_10_17_MASK)
    bl write_pio_masked
    pop {r4, lr}
    bx lr
.size funcao_apagar_tudo, .-funcao_apagar_tudo
