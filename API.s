@Definições da ISA
.syntax unified
.cpu cortex-a9
.arch armv7-a

@ Declaração de endereçamento
DEV_MEM:         .asciz "/dev/mem"
FPGA_SPAN:       .word 0x00005000         @ tamanho mapeado 20KB
FPGA_ADDRS:      .word 0               @var globais pra fazer syscall
FPGA_BRIDGE:     .word 0xFF200000     @ base bridge LWHPS2FPGA


@
#define PIO_DATA_IN_BASE 0x0      // Ou qualquer outro offset
#define PIO_DATA_OUT_BASE 0x10   // Ou qualquer outro offset
#define PIO_CONTROL_IN_BASE 0x20  // Ou qualquer outro offset



@ Funções

acessarMEM :

