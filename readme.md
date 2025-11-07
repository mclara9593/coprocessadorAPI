# 📝 Relatório Técnico - Coprocessador em FPGA

## 📑 Sumário
- 🎯 [Introdução](#introdução)
- 🎯 [Objetivos e Requisitos do Problema](#objetivos-e-requisitos-do-problema)
- 🛠️ [Recursos Utilizados](#recursos-utilizados)
- 🚀 [Desenvolvimento e Descrição em Alto Nível](#desenvolvimento-e-descrição-em-alto-nível)
- 🧪 [Testes, Simulações, Resultados e Discussões](#testes-simulações-resultados-e-discussões)
- [Requisitos do Projeto](#-requisitos-do-projeto)
  


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

#### Plataform Designer
Ferramenta de integração de sistemas do software Intel® Quartus® Prime,que captura projetos de hardware em nível de sistema com alto nível de abstração e automatiza a tarefa de definir e integrar componentes personalizados da Linguagem de Descrição de Hardware (HDL).Ele empacota e integra seus componentes personalizados com componentes IP da Intel e de terceiros e cria automaticamente a lógica de interconexão eliminando assim a tarefa demorada e propensa a erros de escrever HDL para especificar conexões em nível de sistema.

- Referência oficial:
[**Plataform Designer**](https://www.intel.com/content/www/us/en/docs/programmable/683738/current/platform-designer.html)

## 🚀  Descrição de alto nível

Esta seção descreve a arquitetura de software e hardware utilizada para permitir que o processador HPS (Hard Processor System), rodando um sistema operacional Linux, controle periféricos customizados (PIOs - Parallel Input/Output) implementados na lógica da FPGA. A interação é feita através de uma API (Application Programming Interface) de baixo nível escrita em Assembly ARMv7-a.

###  🌉 Ponte HPS-FPGA (Interface Hardware-Software)

A comunicação fundamental entre o HPS e a FPGA ocorre através de **pontes (bridges) AXI**. Neste projeto, utilizamos a **Lightweight HPS-to-FPGA (LWH2F) Bridge**.

  * **Mapeamento em Memória:** Esta ponte funciona como uma interface **mapeada em memória**. Isso significa que, do ponto de vista do HPS, os registradores dos periféricos na FPGA (como os PIOs `pio_in`  e `pio_out` ) aparecem como se fossem posições de memória comuns.
  * **Endereço Base:** O Qsys/Platform Designer atribui um **endereço físico base** para esta ponte. No nosso caso, é `0xFF000000`. Todos os periféricos conectados a esta ponte terão seus registradores acessíveis em **offsets** (deslocamentos) relativos a este endereço base.

### 📁 O Arquivo de Cabeçalho `.h` (Definição do Hardware para o Software)

Para que o software (seja C ou Assembly) saiba *onde* encontrar os registradores de cada periférico, o Qsys/Platform Designer gera automaticamente um arquivo de cabeçalho (geralmente `hps_0.h` ou similar).

  * **Mapa de Endereços:** Este arquivo `.h` contém diretivas `#define` que mapeiam os nomes dos componentes do Qsys para seus **offsets** relativos ao endereço base da ponte.
  * **Exemplo:** O arquivo `hps_0.h` do nosso projeto define:
    ```c
    #define PIO_LED_BASE 0x0
    ```
    Isso informa ao software que os registradores do `pio_led` começam no offset `0` a partir do endereço base da ponte (`0xFF200000`). **É crucial que os offsets usados no software correspondam exatamente aos definidos neste arquivo.** (Nota: Precisamos confirmar o offset do `pio_sw` neste arquivo ou no Qsys).


1.  **(`main.c`)**:

      * **Não** inclui `hps_0.h` (ele não precisa saber `PIO_DATA_OFFSET`).
      * **Não** calcula nenhum ponteiro.
      * Ele apenas chama `init_memory()` no início [cite: main.c].
      * Quando quer enviar dados, ele chama `escrever_bus_0_9(valor_de_10_bits);` [cite: main.c]. O C não sabe onde esse valor vai parar, ele apenas confia na API.

2.  **(`api.s`)**:

      * **Define a constante internamente**: O offset está "hard-coded" (fixo) dentro do próprio Assembly:
        ```assembly
        .equ PIO_DATA_OFFSET,   0x00000000
        ```
      * `init_memory()`: Mapeia o `LW_BRIDGE_BASE` (`0xFF200000`) e salva o ponteiro virtual na variável global `asm_lw_virtual_base` [cite: api.s].
      * `escrever_bus_0_9(r0)`: Esta função (e a `write_pio_masked` que ela chama) faz o trabalho que o C fazia antes:
        1.  Lê o ponteiro base de `asm_lw_virtual_base`.
        2.  Adiciona o offset: `add r4, r4, #PIO_DATA_OFFSET`.
        3.  Escreve o valor (`str r3, [r4]`) [cite: api.s].
















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

## 📚 Funcionamento da API

### Constantes
* LW_BRIDGE_BASE  = 0xFF200000   `Corresponde ao endereço físico da ponte na FPGA`
* LW_BRIDGE_SPAN  = 0x00020000   `Tamanho da janela (128KB ou 20KB)`
* PIO_DATA_OFFSET = 0x00000000    `Onde está o PIO dentro da ponte`

###  Variáveis globais exlcusivas
* asm_lw_virtual_base: .word 0   `Corresponde ao ponteiro virtual após mmap`
* asm_mem_fd:          .word -1  `File descriptor de /dev/mem`

### 
*




![Texto Alternativo da Imagem](assets/api.png)





## 📈 Análise dos Resultados



## 🏁 Conclusão

	
## ✍️ Colaboradores

Este projeto foi desenvolvido por:

- [**Julia Santana**](https://github.com/)
- [**Maria Clara**](https://github.com/)
- [**Vitor Dórea**](https://github.com/)

Agradecimentos ao professor **Angelo Duarte** e aos tutored **Wesley** e **Alan**.
