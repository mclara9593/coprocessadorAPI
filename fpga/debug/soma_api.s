@ Arquivo: soma_api.s
.global simple_sum
.text

simple_sum:
    @ Argumentos: r0 = a, r1 = b
    add r0, r0, r1   @ Resultado (a+b) fica em r0
    bx lr            @ Retorna para o C (usando o Link Register)
