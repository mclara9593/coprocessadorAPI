# 📝 Relatório Técnico - Coprocessador em FPGA

## 📑 Sumário
-  [Introdução](#introdução)
- 🎯 [Objetivos e Requisitos do Problema](#objetivos-e-requisitos-do-problema)
- 🛠️ [Recursos Utilizados](#recursos-utilizados)
- 🚀 [Desenvolvimento e Descrição em Alto Nível](#desenvolvimento-e-descrição-em-alto-nível)
- [📚 Funcionamento da API](funcionamento_da_api)
- 🧪 [Testes,resultados e discussões](#testes_resultados_e_discussões)


Aqui está a seção do sumário formatada e atualizada para incluir todos os tópicos principais do seu relatório, conforme os cabeçalhos `##` presentes no documento:

Entendido. Peço desculpas pelo mal-entendido. Você quer que todos os itens do sumário sigam o mesmo padrão de formatação, usando o emoji `🎯` no início.

Aqui está o sumário corrigido, mantendo o formato solicitado para todos os tópicos principais do relatório:



4.2.3.
 Especificação dos hardwares usados nos testes;     FALTA
4.2.4.
 Descrição detalhada do processo para instalação e configuração de
ambiente para uso da solução;                     FALTA
4.2.6.
 Análise dos resultados alcançados.             FALTTA

projeto falta o makefile e falta ajeitar esse indice



## Introdução
O desenvolvimento de um módulo embarcado para redimensionamento de imagens é crucial para sistemas de vigilância e exibição em tempo real, demandando soluções que unam a eficiência do hardware reconfigurável à flexibilidade do software de controle.Neste contexto, o projeto visa concluir um sistema capaz de aplicar zoom (ampliação) ou *downscale* (redução) de imagens, simulando interpolação visual, com foco nas etapas de interface e aplicação.

O presente projeto insere-se no âmbito do desenvolvimento de uma **API (Application Programming Interface)** e de um **driver de software** para o coprocessador gráfico executando na FPGA da plataforma DE1-SoC.A API, que constitui a segunda etapa, deve ser implementada em **linguagem Assembly** e deve traduzir um repertório de instruções (ISA) para o coprocessador, utilizando comandos que replicam as operações previamente implementadas via chaves e botões.O objetivo é permitir que o controlador gráfico seja integrado a um sistema computacional, com a imagem sendo lida a partir de um arquivo BITMAP, transferida e processada pelo coprocessador
.
Além da implementação em Assembly, o projeto exige o desenvolvimento de uma **aplicação principal em linguagem C**, que é a **terceira etapa**.Esta aplicação deverá carregar o arquivo BITMAP, ligar-se ao driver (biblioteca Assembly) e controlar as operações de redimensionamento através dO terminal.A solução deve ser compatível com o processador **ARM (HPS)** e utilizar as interfaces da placa DE1-SoC.

Este relatório detalha o processo de desenvolvimento e os requisitos técnicos para as etapas 2 e 3, abrangendo aspectos como mapeamento de memória em arquitetura ARM, programação em Assembly e link-edição de módulos objeto.Através da criação de um *script* de compilação (*Makefile*) e de uma documentação detalhada no `README`, busca-se não apenas cumprir os objetivos técnicos, mas também fornecer uma solução completa para a interface hardware-software na DE1-SoCs.

## 📋 Requisitos do Projeto
* O código da API deve ser escrito em linguagem **Assembly**
* O sistema só poderá utilizar os **componentes disponíveis na placa DE1-SoC**.
* Deverão ser implementados na API os **comandos da ISA** (Instruction Set Architecture) do coprocessador, utilizando operações que foram implementadas anteriormente via chaves e botões
* As imagens são representadas em **escala de cinza*.
* Cada pixel deverá ser representado por um número inteiro de **8 bits**
* A imagem deve ser lida a partir de um arquivo e **transferida para o coprocessador**.
* O coprocessador deve ser **compatível com o processador ARM (HPS)** para viabilizar o desenvolvimento da solução.
* O código da aplicação deve ser escrito em **linguagem C**.
* O driver do processador (biblioteca Assembly) deve ser **ligado ao código da aplicação principal**.
* Um **arquivo *header*** deve armazenar os protótipos dos métodos da API da controladora.
* A aplicação deverá ter as seguintes operações através de uma **interface texto**:
    * Carregar arquivo **BITMAP**
    * Selecionar **algoritmo de zoom**


## 🛠️ Recursos Utilizados

### 🔧 Ferramentas

#### 💻 Quartus Prime

- Síntese e Compilação:

O Quartus Prime é utilizado para compilar o projeto em Verilog, convertendo a descrição HDL em uma implementação física adequada para a FPGA. Durante esse processo, o compilador realiza a síntese lógica, o mapeamento e o ajuste de layout (place and route), otimizando as rotas lógicas e a alocação dos recursos internos da FPGA, conforme as recomendações descritas no User Guide: Compiler.

- Referência oficial:
[**Quartus Prime Guide**](https://www.intel.com/content/www/us/en/support/programmable/support-resources/design-software/user-guides.html)

#### 💻 FPGA DE1-SoC

- Especificações Técnicas:

A placa DE1-SoC, baseada no FPGA Cyclone V SoC (modelo 5CSEMA5F31C6N), conta com aproximadamente 85K elementos lógicos (LEs), 4.450 Kbits de memória embarcada e 6 blocos DSP de 18x18 bits. Essas características permitem a implementação de designs complexos e o processamento paralelo de dados.

- Periféricos Utilizados:
- Acesso à Chip Memory:
O design utiliza diretamente a memória embarcada na FPGA para armazenamento temporário de dados e matrizes, eliminando a necessidade de interfaces externas para memória DDR3.

- Referência oficial:
[**Manual da Placa**](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&No=836&PartNo=4)

### 🔧 Recursos

#### 🔌 VGA module
Módulo responsável pela comunicação entre o monitor e a memória (no caso, On Chip memory),utilizado para exibir as imagens processadas ou não através do conector VGA.

As saídas next_x e next_y do módulo VGA definem o endereço de leitura para a memória e acessa as informações de cor dos pixels.

Controlar uma tela VGA requer a manipulação de dois pinos de sincronização digital e três pinos analógicos coloridos (VERMELHO, VERDE e AZUL). Um dos pinos de sincronização, HSYNC, informa à tela quando mover para uma nova linha de pixels. O outro pino de sincronização, VSYNC, informa à tela quando iniciar um novo quadro. O protocolo é descrito abaixo, tanto textualmente quanto visualmente.


- Referência oficial:
[**Verilog VGA module**](https://vanhunteradams.com/DE1/VGA_Driver/Driver.html)

#### 🧑‍💻 Plataform Designer
Ferramenta de integração de sistemas do software Intel® Quartus® Prime,que captura projetos de hardware em nível de sistema com alto nível de abstração e automatiza a tarefa de definir e integrar componentes personalizados da Linguagem de Descrição de Hardware (HDL).Ele empacota e integra seus componentes personalizados com componentes IP da Intel e de terceiros e cria automaticamente a lógica de interconexão eliminando assim a tarefa demorada e propensa a erros de escrever HDL para especificar conexões em nível de sistema.

- Referência oficial:
[**Plataform Designer**](https://www.intel.com/content/www/us/en/docs/programmable/683738/current/platform-designer.html)

## 🚀  Descrição de alto nível

Esta seção descreve a arquitetura de software e hardware utilizada para permitir que o processador HPS (Hard Processor System), rodando um sistema operacional Linux, controle periféricos customizados (PIOs - Parallel Input/Output) implementados na lógica da FPGA. A interação é feita através de uma API (Application Programming Interface) de baixo nível escrita em Assembly ARMv7-a.

###  🌉 Ponte HPS-FPGA (Interface Hardware-Software)

A comunicação fundamental entre o HPS e a FPGA ocorre através de **pontes (bridges) AXI**. Neste projeto, utilizamos a **Lightweight HPS-to-FPGA (LWH2F) Bridge**.

  * **Mapeamento em Memória:** Esta ponte funciona como uma interface **mapeada em memória**. Isso significa que, do ponto de vista do HPS, os registradores dos periféricos na FPGA (como os PIOs `pio_in`  e `pio_out` ) aparecem como se fossem posições de memória comuns.
  * **Endereço Base:** O Qsys/Platform Designer atribui um **endereço físico base** para esta ponte. No nosso caso, é `0xFF000000`. Todos os periféricos conectados a esta ponte terão seus registradores acessíveis em **offsets** (deslocamentos) relativos a este endereço base.
  

### 📁Método de linkagem (Definição do Hardware para o Software)

 Saber *onde* encontrar os registradores de cada periférico


1.  **`main.c`**:

      * Chama `init_memory()` no início 
      * Quando quer enviar dados, ele chama `escrever_bus_0_9(valor_de_10_bits);`. 
2.  **`api.s`**:

      * **Define a constante internamente**: O offset está "hard-coded" (fixo) dentro do próprio Assembly:
        ```assembly
        .equ PIO_DATA_OFFSET,   0x00000000
        ```
      * `init_memory()`: Mapeia o `LW_BRIDGE_BASE` (`0xFF200000`) e salva o ponteiro virtual na variável global `asm_lw_virtual_base`.
      * `escrever_bus_0_9(r0)`: Esta função (e a `write_pio_masked` que ela chama) faz o trabalho que o C fazia antes:
        1.  Lê o ponteiro base de `asm_lw_virtual_base`.
        2.  Adiciona o offset: `add r4, r4, #PIO_DATA_OFFSET`.
        3.  Escreve o valor (`str r3, [r4]`).


### 📚 A Biblioteca Assembly 

A API em Assembly (`api.s`) atua como um driver de baixo nível, encapsulando o acesso direto ao hardware.

  * **Mapeamento de Memória via Syscalls:** A função `iniciarCoprocessor` é responsável por tornar o endereço físico da ponte (`0xFF000000`) acessível ao programa. Ela faz isso **diretamente**, usando **chamadas de sistema (syscalls)** do Linux:
      * **`open` (syscall \#5):** Abre o arquivo `/dev/mem`, que representa a memória física do sistema.
      * **`mmap2` (syscall \#192):** Pede ao Kernel para mapear o endereço físico da ponte (`FPGA_BRIDGE`) em um **endereço virtual** que o programa pode usar. Esse ponteiro virtual é armazenado na variável global `FPGA_ADDRS`.
  * **Funções Primitivas (`write_pio`, `read_pio`):** Estas funções recebem um **offset** (como `PIO_IN_OFFSET` ou `PIO_OUT_OFFSET`, definidos com `.equ` baseados no `.h`) e, opcionalmente, um valor. Elas calculam o endereço virtual final (`FPGA_ADDRS + offset`) e usam as instruções ARM `STR` (Store Register) ou `LDR` (Load Register) para escrever ou ler diretamente no endereço mapeado, controlando assim os PIOs.
* **Funções Auxiliares** instruções de nome`funcao_enviar` que usam uma **função helper interna** `write_pio_helper`, `write_to_pio`  e `cleanup_memory`.


### ✴️ Main 

O programa C (`.c`) contém a lógica principal da aplicação e utiliza a API Assembly para interagir com o hardware.

  * **Declarações `extern`:** O C utiliza declarações `extern` (ex: `extern void* iniciarCoprocessor(void);`, `extern void write_pio(unsigned int offset, unsigned int value);` - adaptando a assinatura se necessário) para informar ao compilador que essas funções existem, mesmo que sua implementação esteja em outro arquivo (o `.s`).
  * **Chamada de Funções:** O código C chama as funções Assembly como se fossem funções C normais (ex: `lw_virtual = iniciarCoprocessor();`, `funcao_apagar_tudo(led_ptr);`). O compilador C gera o código de máquina apropriado para passar os parâmetros (nos registradores corretos, conforme a convenção de chamada ARM EABI) e pular para o endereço da função Assembly.
  * **Lógica de Controle:** O C decide *quando* e *com quais valores* chamar as funções da API Assembly, implementando a lógica desejada (ler botões, acender LEDs, processar dados, etc.). No exemplo `pograma.c`, ele lê a entrada do usuário e chama a função Assembly correspondente.


### 🏗️ Montagem e Linkagem

O processo para criar o programa final que roda no HPS envolve três etapas principais:

1.  **Montagem (Assembly `.s` -\> `.o`):** O **Montador** (Assembler - `as`) lê o arquivo da API Assembly (`.s`) e o traduz para código de máquina binário específico da arquitetura ARMv7-a. O resultado é um **arquivo objeto** (`.o`). Este arquivo contém o código de máquina das funções Assembly e uma tabela de símbolos indicando quais funções são globais (`.global`).
2.  **Compilação (C `.c` -\> `.o`):** O **Compilador C** (`gcc -c`) lê o arquivo C (`.c`) e o traduz para código de máquina ARMv7-a, criando outro **arquivo objeto** (`.o`). Este arquivo contém o código de máquina da função `main` e outras funções C, além de referências (na tabela de símbolos) às funções Assembly declaradas como `extern`.
3.  **Linkagem (`.o` + `.o` -\> Executável):** O **Linker** (geralmente invocado pelo `gcc` quando não se usa `-c`) pega todos os arquivos objeto (`.o`). Sua principal tarefa é **resolver as referências**: ele encontra a chamada para `iniciarCoprocessor` no `.o` do C e a conecta à definição de `iniciarCoprocessor` no `.o` do Assembly. Ele combina todo o código de máquina, organiza as seções de dados e código, e produz um **arquivo executável** final que o Linux pode carregar e rodar.



### Esquema do projeto visão Top-Down 

![Texto Alternativo da Imagem](assets/exemplo.png)

https://mermaid.live/edit#pako:eNpVjbFugzAQhl_FuqmVSAQxBPBQqSFtlkjtkKmQwQoHRg02MkZpCrx7DVHU9qY7fd__Xw8nlSMwKM7qchJcG3LYZpLYeU4ToavW1Lw9ksXiadihIbWSeB3I5mGnSCtU01SyfLz5m0kiSb-fNCRGVPJzvKFkzr9JHMg23fPGqOb4lxwuaiAvafUubP1_IjTa1GtacFbwxYlrknA9K-BAqascmNEdOlCjrvl0Qj_RDIzAGjNgds2x4N3ZZJDJ0cYaLj-Uqu9JrbpSgK0_t_bqmpwb3Fa81PxXQZmjTlQnDTCPzhXAevgCRt1o6Qer2PNouI4D6jlwBRa4y3UU-vHaiwLqrkLqjw58z0_d5QTsRG4c-6Hv0fEHO2p3Ag

---

## 📚 Funcionamento da API

- O arquivo `api.s` implementa uma **API de baixo nível** para controlar periféricos PIO (Parallel Input/Output) na FPGA através da ponte HPS-FPGA da placa DE1-SoC. Ele funciona como uma **camada de abstração** entre o software (`main.c`) e o hardware (FPGA).

### 📐 Arquitetura e Diretivas Iniciais

```assembly
.syntax unified
.thumb
.text
```

- **`.syntax unified`**: Usa sintaxe ARM moderna (unificada)
- **`.thumb`**: Gera código Thumb-2 (instruções de 16/32 bits, mais compactas)
- **`.text`**: Indica início da seção de código executável

---

### 🔢 Constantes Globais (`.equ`)

```assembly
.equ LW_BRIDGE_BASE,    0xFF200000
.equ LW_BRIDGE_SPAN,    0x00020000
.equ PIO_DATA_OFFSET,   0x00000000
.equ PIO_BUS_0_9_MASK,  0x000003FF
.equ PIO_BUS_10_17_MASK, 0x0003FC00
```

#### **LW_BRIDGE_BASE** (0xFF200000)
- **Endereço físico** da ponte Lightweight HPS-to-FPGA
- É onde o hardware da FPGA está "mapeado" na memória do processador ARM
- Pense nisso como o "endereço inicial" de todos os periféricos FPGA

#### **LW_BRIDGE_SPAN** (0x00020000 = 128KB)
- Tamanho da região de memória da ponte
- Define quanto espaço será mapeado via `mmap`

#### **PIO_DATA_OFFSET** (0x00000000)
- Deslocamento (offset) do registrador de dados do PIO dentro da ponte
- Neste caso, está no início (offset 0)

#### **Máscaras de Bits**
- **`PIO_BUS_0_9_MASK`** = `0x000003FF` = `0b0000001111111111`
  - Seleciona os 10 bits inferiores (bits 0-9)
  - Usado para controlar **dados de imagem/pixel**

- **`PIO_BUS_10_17_MASK`** = `0x0003FC00` = `0b0000001111111100000000`
  - Seleciona os bits 10-17 (8 bits)
  - Usado para controlar **LEDs/comandos de algoritmo**

---

### 🗃️ Variáveis Globais (`.data`)

```assembly
.data
dev_mem_path:      .asciz "/dev/mem"
.align 4
asm_lw_virtual_base: .word 0
asm_mem_fd:          .word -1
asm_pio_current_state: .word 0
```

#### **dev_mem_path**
- String terminada em zero (`\0`) com o caminho `/dev/mem`
- **`/dev/mem`** é um arquivo especial do Linux que representa a **memória física** do sistema

#### **asm_lw_virtual_base**
- Armazena o **ponteiro virtual** retornado pelo `mmap`
- Inicialmente 0, será preenchido por `init_memory()`
- É o endereço que o programa usa para acessar o hardware

#### **asm_mem_fd**
- Armazena o **file descriptor** de `/dev/mem`
- Inicialmente -1 (inválido)

#### **asm_pio_current_state**
- **Cache do estado atual** dos PIOs
- Permite fazer escritas parciais sem perder bits de outros barramentos

---
#### Funções

*  `init_memory` Mapeia o hardware da FPGA na memória virtual do processo.

#### Abrir `/dev/mem`**
- **`open()`** é uma syscall que retorna um **file descriptor**
- **`O_RDWR`** (0x0002): Leitura e escrita
- **`O_SYNC`** (0x00101000): Operações síncronas (sem cache)
- Resultado em `r0`: fd se sucesso, -1 se erro

#### **`mmap` - Mapeamento de Memória**
**Sintaxe**: `void* mmap(void *addr, size_t length, int prot, int flags, int fd, off_t offset)`

**Parâmetros**:
- `r0` (addr): `NULL` → kernel escolhe o endereço virtual
- `r1` (length): `0x20000` → mapeia 128KB
- `r2` (prot): `PROT_READ | PROT_WRITE` → permite ler e escrever
- `r3` (flags): `MAP_SHARED` → mudanças são visíveis no hardware
- Pilha: `fd` (r4) e `offset` (LW_BRIDGE_BASE)

**Retorno**: Endereço virtual onde o hardware foi mapeado (ou -1 em caso de erro)

####  `cleanup_memory` Libera os recursos alocados.


#### `write_pio_masked` **Função interna** que faz escritas **parciais** nos PIOs (preserva outros bits).


#### **`escrever_bus_0_9`** Escreve valores de 10 bits (dados de pixel/imagem).



#### **`set_zoom_4x`** - Zoom 4x
```
0x8400 = 0b100001000000000
         │││││││││└─────────── Bit 10: 0
         │└──────────────────── Bits 11-16: diversos
         └───────────────────── Bit 17: 1 (comando de zoom)
```

#### Funções de Controle de Algoritmos (LEDs)

Enviam valores específicos para o barramento de LEDs (bits 10-17).

#### **`funcao_enviar_1`**
**Padrão**: `(valor << 10)` desloca o valor para os bits 10-17.

- `funcao_enviar_2`: `(2 << 10)` = `0x800`
- `funcao_enviar_4`: `(4 << 10)` = `0x1000`
- `funcao_enviar_8`: `(8 << 10)` = `0x2000`


---

#### 🔗 Integração C ↔ Assembly

```c
extern void set_zoom_4x(void);  // Declara função Assembly

// Chamada:
set_zoom_4x();  // r0, r1, r2, r3 podem ser usados livremente
```

### **Convenção ARM EABI**:
- **Parâmetros**: `r0-r3` (primeiros 4 parâmetros)
- **Retorno**: `r0`
- **Preservados**: `r4-r11, sp, lr`
- **Temporários**: `r0-r3, r12`



## 🏁 Testes


A etapa de testes foi crucial para validar a complexa interação entre o software de alto nível (Aplicação C), o driver de baixo nível (API Assembly) e o hardware (lógica Verilog na FPGA). Os testes foram divididos em duas categorias principais: testes de software (compilação, linkagem) e testes de integração hardware-software (execução na placa).

### Especificação dos Hardwares e Softwares Usados
---

Para garantir a reprodutibilidade dos testes, o ambiente foi padronizado da seguinte forma:

* Hardware (Plataforma Alvo):
  * Placa de Desenvolvimento Terasic DE1-SoC.
  * Processador (HPS): Dual-core ARM Cortex-A9 (executando o software).

  * FPGA: Cyclone V SoC (executando o hardware Verilog).

* Periféricos: Monitor VGA, Chaves (Switches) da placa.

* Software (Ambiente de Desenvolvimento Host - PC):

  * Intel Quartus Prime: Utilizado para a síntese, compilação e geração do arquivo de programação (.rbf) a partir dos módulos Verilog (ghrd_top.v, processo_imagem.v).

  * Software (Ambiente de Execução Alvo - DE1-SoC):

  * Sistema Operacional: Linux embarcado (distribuição Linaro/Ubuntu).

* Toolchain GNU ARM:

  * gcc (GNU Compiler Collection): Usado para compilar a aplicação C (main.c) e para linkar o executável final.

  * as (GNU Assembler): Usado (implicitamente pelo gcc) para montar a API Assembly (api.s).

  * libc (Biblioteca C Padrão): Essencial, pois a API Assembly (api.s) chama funções da libc como open, mmap, close e munmap.

### Execução 
---

O processo de teste de integração da solução completa seguiu um fluxo rigoroso de 3 etapas, executado a cada nova iteração do software ou hardware:

+ Etapa 1: Programação da FPGA (Hardware)

O projeto Verilog (ghrd_top.v, processo_imagem.v, etc.) foi compilado no Quartus Prime no PC host.


+ Etapa 2: Compilação e Linkagem do Software (Software)

Os arquivos-fonte `main.c` e `api.s` foram colocados no mesmo diretório na DE1-SoC.

O comando de compilação e linkagem unificado foi executado:

gcc -o meu_programa main.c api.s -lm

gcc: Invoca o toolchain.

-o meu_programa: Define o nome do executável de saída.

main.c: O gcc compila o código C.

api.s: O gcc automaticamente invoca o montador (as) para api.s e, crucialmente, linka as chamadas (bl open, bl mmap  com as implementações reais na libc.

-lm: Linka a biblioteca matemática (necessária para usleep ou outras funções C).

  + Etapa 3: Execução e Teste Funcional

Configuração do Hardware: As chaves físicas SW[9] (Reset) e SW[5:2] (Modo de Processamento) foram colocadas na posição 0 (desligado), conforme a lógica do Verilog, para habilitar o modo de "Carregamento de Imagem" pelo HPS.

Execução do Software: O programa foi executado com privilégios de superusuário (necessário para init_memory acessar /dev/mem):

sudo ./meu_programa


### Resultados Alcançados

O processo de teste revelou diversos pontos críticos sobre a arquitetura HPS-FPGA.

+ Teste 1: Validação da API de Memória (init_memory)

Procedimento: Execução do programa compilado (sudo ./meu_programa).

Resultado: O terminal exibiu a mensagem "Hardware (ponte HPS-FPGA) mapeado com sucesso." 

Análise: Este resultado confirmou que o método de linkagem híbrido foi bem-sucedido. A API em Assembly (api.s) conseguiu chamar com sucesso as funções open e mmap da libc, e o ponteiro virtual para a ponte 0xFF200000 foi obtido e armazenado corretamente na variável global asm_lw_virtual_base. Falhas neste teste (como esquecer o sudo) resultaram em erro imediato, validando a robustez da checagem de erro.

+ Teste 2: Validação da Escrita no PIO (Carregamento do Bitmap)

Procedimento: Após a inicialização bem-sucedida, selecionar a "Opção 1: Enviar Imagem BMP" e fornecer um arquivo .bmp válido.

Resultado Inicial (Falha): Conforme discutido no desenvolvimento, a primeira tentativa resultou no "piscar" do monitor VGA. A saída do terminal mostrava o C enviando os pixels, mas o VGA não exibia a imagem.

Análise da Falha (Depuração): Esta falha foi a mais importante da integração. A análise cruzada do software Assembly (api.s antigo) e do hardware Verilog (processo_imagem.v) revelou uma incompatibilidade de interface (contrato de bits):

O Software (baseado em um projeto anterior) estava enviando um pacote de 32 bits contendo endereço, dados e WREN (ex: 0x0807FF05).

O Hardware (processo_imagem.v) esperava um pacote de 10 bits ([bit 9: WREN | bits 7:0: DADO]) e gerava seu próprio endereço internamente com um contador (hps_write_addr_counter).

Correção e Resultado Final: Os arquivos main.c e api.s foram corrigidos para enviar apenas o pacote de 10 bits (uint16_t data_to_send = PIO_WRITE_ENABLE | gray_pixel;). Após esta correção, a repetição do Teste 2 (com as chaves SW[5:2] em 0000) resultou no sucesso do carregamento: a imagem BMP foi corretamente lida, convertida para escala de cinza pelo C, enviada pela API Assembly e exibida no monitor VGA.

+ Teste 3: Validação dos Barramentos Independentes (Lógica write_pio_masked)

Procedimento: Com a imagem carregada, entrar na "Opção 2: Entrar no modo de controle de Algoritmos".

Resultado: Foi possível selecionar comandos (funcao_enviar_1, set_zoom_4x, etc.) sem afetar ou corromper a imagem que estava sendo enviada pelo barramento de bits 0-9.

Análise: Este teste validou a eficácia da função write_pio_masked e da variável asm_pio_current_state . A lógica "Read-Modify-Write" implementada em Assembly permitiu que o HPS tratasse um único PIO de 18 bits como dois barramentos virtuais independentes (um de 10 bits para imagem, outro de 8 bits para comandos), cumprindo um requisito-chave do readme.md de forma eficiente.

	
## ✍️ Colaboradores

Este projeto foi desenvolvido por:

- [**Julia Santana**](https://github.com/)
- [**Maria Clara**](https://github.com/)
- [**Vitor Dórea**](https://github.com/)

Agradecimentos ao professor **Angelo Duarte** e aos tutores **Wesley** e **Alan**.
