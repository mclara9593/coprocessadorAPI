# --- Variáveis de Configuração ---

# O nome do compilador (cross-compiler para ARM)
# Mude para "gcc" se estiver compilando para seu PC local
CC = arm-linux-gnueabihf-gcc

# O nome do seu programa executável final
TARGET = program

# Flags de compilação:
# -g = Inclui símbolos de debug (para usar o gdb)
# -Wall = Mostra todos os warnings (boas práticas)
CFLAGS = -g -Wall

# Lista de arquivos-objeto. O Makefile vai automaticamente
# procurar por .c e .s para criar os .o
OBJS = main.o api.o

# --- Regras do Makefile ---

# Regra padrão (o que fazer ao digitar "make")
all: $(TARGET)

# Regra de "Linkagem":
# Depende dos arquivos-objeto.
# Junta main.o e api.o para criar o $(TARGET)
$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJS)

# Regra genérica para compilar arquivos .c para .o
# (Compilação)
%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

# Regra genérica para compilar arquivos .s para .o
# (Montagem/Assembly)
%.o: %.s
	$(CC) $(CFLAGS) -c -o $@ $<

# Regra de "Limpeza"
# (O que fazer ao digitar "make clean")
clean:
	rm -f $(TARGET) $(OBJS)

.PHONY: all clean