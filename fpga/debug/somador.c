#include <stdio.h>

/* * Protótipo da função Assembly.
 * Deve ser 'int', para corresponder aos registradores 'r0' e 'r1'.
 */
extern int simple_sum(int a, int b);

int main() {
    int num1 = 15;
    int num2 = 30;
    
    // Chama a função Assembly
    int result = simple_sum(num1, num2);
    
    // Imprime o resultado
    printf("O resultado da soma de %d e %d é: %d\n", num1, num2, result);
    
    return 0;
}
