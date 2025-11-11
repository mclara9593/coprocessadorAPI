# ==================================================================
# Makefile para Projeto HPS-FPGA (C + Assembly ARM Thumb)
#
# O alvo padrão (all) compila o executável 'fpga_control'.
# O alvo 'clean' remove todos os arquivos gerados.
# ==================================================================

# --- Configurações de Ferramentas e Flags ---

# Compilador C (pode ser 'arm-linux-gnueabihf-gcc' se for cross-compiling)
CC = gcc
# Montador Assembly (pode ser 'arm-linux-gnueabihf-as' se for cross-compiling)
AS = as

# Arquitetura alvo (Cortex-A9, Thumb mode)
ARCH_FLAGS = -mthumb -march=armv7-a

# Flags para o compilador C
CFLAGS = -Wall -Wextra -std=c99 -g $(ARCH_FLAGS)

# Flags para o montador Assembly
AFLAGS = -g $(ARCH_FLAGS)

# Flags para o linker (link-edição)
LDFLAGS = $(ARCH_FLAGS)

# Nome do executável final
TARGET = fpga_control

# Lista de arquivos objeto
OBJECTS = main.o api.o

# --- Regras Principais ---

# Alvo padrão: 'all' compila o executável.
all: $(TARGET)

# 1. Regra para o Executável Final
# Depende de todos os arquivos objeto.
$(TARGET): $(OBJECTS)
	@echo "LNK: Linking $^ to create $(TARGET)..."
	$(CC) $(LDFLAGS) $^ -o $@

# 2. Regra para o Código C (main.c)
# Depende de 'api.h' (para garantir a recompilação se o cabeçalho mudar).
main.o: main.c api.h
	@echo "CC: Compiling $<..."
	$(CC) $(CFLAGS) -c $< -o $@

# 3. Regra para o Código Assembly (api.s)
# Usa o montador 'as' para gerar o arquivo objeto.
api.o: api.s
	@echo "AS: Assembling $<..."
	$(AS) $(AFLAGS) $< -o $@

# --- Alvos Falsos (Phony Targets) ---
# Alvos que não representam um arquivo real, mas sim uma ação.

.PHONY: clean all

# Alvo 'clean': Remove todos os arquivos gerados.
clean:
	@echo "CLN: Cleaning up build files..."
	rm -f $(TARGET) $(OBJECTS)
```
eof

### Como Usar o Makefile

1.  **Salve** o conteúdo acima em um arquivo chamado `Makefile` no mesmo diretório que `main.c`, `api.s` e `api.h`.
2.  **Para compilar o projeto:**
    ```bash
    make
    ```
    Isso executará a montagem de `api.s` para `api.o`, a compilação de `main.c` para `main.o`, e finalmente, a link-edição para criar o executável **`fpga_control`**.

3.  **Para limpar os arquivos gerados:**
    ```bash
    make clean