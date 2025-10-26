# 📝 Relatório Técnico - Coprocessador em FPGA

## 📑 Sumário
- 🎯 [Introdução](#introdução)
- 🎯 [Objetivos e Requisitos do Problema](#objetivos-e-requisitos-do-problema)
- 🛠️ [Recursos Utilizados](#recursos-utilizados)

- 🚀 [Desenvolvimento e Descrição em Alto Nível](#desenvolvimento-e-descrição-em-alto-nível)
- 🎛️ [Ponte de comunicação HPS FPGA](#ponte-de-comunicação-hps-fpga)
- 🧮 [API ()](#api)
- 🧪 [Testes, Simulações, Resultados e Discussões](#testes-simulações-resultados-e-discussões)

---

## Introdução
O desenvolvimento de um módulo embarcado para redimensionamento de imagens é crucial para sistemas de vigilância e exibição em tempo real, demandando soluções que unam a eficiência do hardware reconfigurável à flexibilidade do software de controle.Neste contexto, o projeto visa concluir um sistema capaz de aplicar zoom (ampliação) ou *downscale* (redução) de imagens, simulando interpolação visual, com foco nas etapas de interface e aplicação.

O presente projeto insere-se no âmbito do desenvolvimento de uma **API (Application Programming Interface)** e de um **driver de software** para o coprocessador gráfico executando na FPGA da plataforma DE1-SoC.A API, que constitui a **segunda etapa**, deve ser implementada em **linguagem Assembly** e deve traduzir um repertório de instruções (ISA) para o coprocessador, utilizando comandos que replicam as operações previamente implementadas via chaves e botões.O objetivo é permitir que o controlador gráfico seja integrado a um sistema computacional, com a imagem sendo lida a partir de um arquivo BITMAP, transferida e processada pelo coprocessador
.
Além da implementação em Assembly, o projeto exige o desenvolvimento de uma **aplicação principal em linguagem C**, que é a **terceira etapa**.Esta aplicação deverá carregar o arquivo BITMAP, ligar-se ao driver (biblioteca Assembly) e controlar as operações de redimensionamento através de uma interface de texto.Os comandos de zoom *in* e *zoom out* devem ser acionados pelas teclas '+' (mais) e '-' (menos), respectivamente.A solução deve ser compatível com o processador **ARM (HPS)** e utilizar as interfaces da placa DE1-SoC.

Este relatório detalha o processo de desenvolvimento e os requisitos técnicos para as etapas 2 e 3, abrangendo aspectos como mapeamento de memória em arquitetura ARM, programação em Assembly e link-edição de módulos objeto.Através da criação de um *script* de compilação (*Makefile*) e de uma documentação detalhada no `README`, busca-se não apenas cumprir os objetivos técnicos, mas também fornecer uma solução completa para a interface hardware-software na DE1-SoCs.

## 📋 Requisitos do Projeto
* O código da API deve ser escrito em linguagem **Assembly**
* O sistema só poderá utilizar os **componentes disponíveis na placa DE1-SoC**.
* 
* Deverão ser implementados na API os **comandos da ISA** (Instruction Set Architecture) do coprocessador, utilizando operações que foram implementadas anteriormente via chaves e botões
* As imagens são representadas em **escala de cinza**[cite: 130].
* Cada pixel deverá ser representado por um número inteiro de **8 bits**
* A imagem deve ser lida a partir de um arquivo e **transferida para o coprocessador**.
* O coprocessador deve ser **compatível com o processador ARM (HPS)** para viabilizar o desenvolvimento da solução.
* O código da aplicação deve ser escrito em **linguagem C**.
* O driver do processador (biblioteca Assembly) deve ser **ligado ao código da aplicação principal**.
* Um **arquivo *header*** deve armazenar os protótipos dos métodos da API da controladora.
* A aplicação deverá ter as seguintes operações através de uma **interface texto**:
    * Carregar arquivo **BITMAP**
    * Selecionar **algoritmo de zoom**
    * Utilizar a tecla **'+' (mais) para a operação de zoom *in*** (ampliação)
    * Utilizar a tecla **'-' (menos) para a operação de zoom *out*** (redução)

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

### 🔧 Recurso

#### 🔌 VGA module
Módulo responsável pela comunicação entre o monitor e a memória (no caso, On Chip memory),utilizado para exibir as imagens processadas ou não através do conector VGA.

As saídas next_x e next_y do módulo VGA definem o endereço de leitura para a memória e acessa as informações de cor dos pixels.

Controlar uma tela VGA requer a manipulação de dois pinos de sincronização digital e três pinos analógicos coloridos (VERMELHO, VERDE e AZUL). Um dos pinos de sincronização, HSYNC, informa à tela quando mover para uma nova linha de pixels. O outro pino de sincronização, VSYNC, informa à tela quando iniciar um novo quadro. O protocolo é descrito abaixo, tanto textualmente quanto visualmente.


- Referência oficial:
[**Verilog VGA module**](https://vanhunteradams.com/DE1/VGA_Driver/Driver.html)



## pido e eficiente, o que o torna útil para sistemas com restrições de tempo de processamento.



### 🚀 Desenvolvimento e Descrição em Alto Nível



## 📈 Análise dos Resultados


## 📉 Desempenho e Uso de Recursos


## 💭 Discussões e Melhorias Futuras


## 🏁 Conclusão

	
## ✍️ Colaboradores

Este projeto foi desenvolvido por:

- [**Julia Santana**](https://github.com/)
- [**Maria Clara**](https://github.com/)
- [**Vitor Dórea**](https://github.com/)

Agradecimentos ao(a) professor(a) **Angelo Duarte** pela orientação.
