# AOC — Jogo para NES em Assembly

Projeto desenvolvido para a disciplina de Arquitetura e Organização de Computadores (AOC). O objetivo é desenvolver um jogo para o Nintendo Entertainment System (NES) utilizando Assembly do processador 6502.

## Tecnologias e ferramentas

- **Assembly 6502:** linguagem utilizada no desenvolvimento do jogo.
- **cc65:** conjunto de ferramentas utilizado para montar e gerar a ROM.
- **ca65:** assembler responsável por transformar os arquivos Assembly em arquivos objeto.
- **ld65:** linker responsável por gerar a ROM a partir dos arquivos objeto e da configuração de memória.
- **Mesen:** emulador utilizado para executar e testar o jogo.
- **Make:** ferramenta utilizada para automatizar a compilação.

## Requisitos

Para compilar e executar o projeto, é necessário ter:

- [cc65](https://cc65.github.io/) instalado.
- [Mesen](https://www.mesen.ca/) instalado.
- `make` instalado.
- Git instalado para clonar o repositório.

Os comandos abaixo consideram um ambiente Linux. A instalação das ferramentas pode variar conforme o sistema operacional.

## Como executar

### 1. Clonar o repositório

```bash
git clone https://github.com/joaovitorbertolino/AOC.git
cd AOC
```

### 2. Compilar o projeto

Na raiz do repositório, execute:

```bash
make
```

O comando monta o código Assembly e gera a ROM do jogo.

Após a compilação, o arquivo gerado estará em:

```text
build/teste.nes
```

### 3. Executar o jogo

Se o Mesen estiver disponível no PATH do sistema, execute:

```bash
make run
```

Caso o comando não funcione, abra o Mesen manualmente e carregue o arquivo:

```text
build/teste.nes
```

### 4. Limpar os arquivos gerados

Para remover os arquivos presentes na pasta `build/`, execute:

```bash
make clean
```

Depois, basta executar `make` novamente para recompilar o projeto.

## Estrutura do projeto

```text
AOC/
├── assets/
├── build/
├── cfg/
│   └── nes.cfg
├── src/
│   └── main.s
├── Makefile
└── README.md
```

### `assets/`

Pasta destinada aos recursos utilizados pelo jogo.

Conforme o desenvolvimento avançar, ela poderá armazenar recursos como:

- **Tiles:** dados gráficos utilizados para construir os elementos visuais.
- **Mapas:** dados que definem a disposição dos tiles no cenário.
- **Paletas:** dados referentes às cores utilizadas pelo NES.

A organização e a inclusão desses recursos na ROM dependerão de como forem implementados no código e no processo de compilação.

### `build/`

Pasta destinada aos arquivos gerados durante a compilação.

Entre os arquivos gerados estão:

- `main.o`: arquivo objeto produzido pelo assembler.
- `teste.nes`: ROM que pode ser executada no emulador.

Esses arquivos são gerados a partir do código-fonte e da configuração do projeto.

### `cfg/`

Contém os arquivos de configuração utilizados na compilação.

#### `nes.cfg`

Arquivo de configuração do linker `ld65`.

Define a organização da memória e os segmentos utilizados para gerar a ROM do NES, incluindo o cabeçalho, o código e os vetores de interrupção.

### `src/`

Contém os arquivos-fonte Assembly do jogo.

#### `main.s`

Arquivo Assembly principal do projeto.

Atualmente, contém a configuração inicial do sistema, a inicialização básica do NES e um laço de execução. Ele serve como ponto de partida para a implementação das funcionalidades do jogo.

Conforme o projeto crescer, outros arquivos Assembly poderão ser adicionados para organizar funcionalidades específicas.

### `Makefile`

Automatiza as etapas de compilação do projeto.

Os comandos disponíveis são:

| Comando | Função |
|---|---|
| `make` | Compila o projeto e gera a ROM. |
| `make run` | Tenta executar a ROM utilizando o Mesen. |
| `make clean` | Remove os arquivos presentes em `build/`. |

## Como funciona a compilação

O processo de compilação está dividido em duas etapas principais.

**1. Montagem do código Assembly**

O `ca65` transforma o arquivo `src/main.s` em um arquivo objeto:

```text
src/main.s → build/main.o
```

**2. Geração da ROM**

O `ld65` utiliza o arquivo objeto e a configuração `cfg/nes.cfg` para gerar a ROM:

```text
build/main.o + cfg/nes.cfg → build/teste.nes
```

O arquivo `teste.nes` pode então ser carregado no Mesen para testar o jogo.

## Organização do código Assembly

O arquivo `main.s` utiliza segmentos para separar diferentes partes do programa.

| Segmento | Função |
|---|---|
| `HEADER` | Contém o cabeçalho iNES, que identifica o formato da ROM e informa características da configuração do jogo. |
| `ZEROPAGE` | Reservado para variáveis que utilizam o endereçamento da página zero. |
| `CODE` | Contém as instruções executáveis do programa. |
| `VECTORS` | Contém os vetores utilizados pelo processador para identificar os pontos de entrada de interrupções e inicialização. |

A organização dos segmentos é definida em `cfg/nes.cfg`.

## Desenvolvimento

Para contribuir com o projeto:

1. Obtenha a versão mais recente do repositório.
2. Faça as alterações nos arquivos correspondentes.
3. Execute `make` para verificar se a compilação funciona.
4. Teste a ROM no Mesen.
5. Envie suas alterações para o repositório.

Ao adicionar novos arquivos Assembly, também será necessário atualizar o `Makefile` e, quando aplicável, a configuração do linker para incluí-los na compilação.

## Estado atual

O projeto possui a estrutura inicial de compilação e geração de uma ROM para NES.

O código atual estabelece uma base para o desenvolvimento das funcionalidades do jogo. Os recursos gráficos, os mapas e as mecânicas serão implementados progressivamente.

---

Projeto acadêmico desenvolvido para a disciplina de Arquitetura e Organização de Computadores (AOC).
