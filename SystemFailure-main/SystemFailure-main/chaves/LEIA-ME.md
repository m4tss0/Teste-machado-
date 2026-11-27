# Chaves (verde e azul): lugar sorteado e flutuando

Cada chave **sorteia 1 entre 3 lugares possíveis** (os círculos vermelhos dos mapas) e flutua no lugar sorteado.

| Chave | Sala | O que abre | Cor | Lugares possíveis |
|---|---|---|---|---|
| verde | Quarto 2 | Sala de Máquinas | verde | 3 (círculos do Quarto 2) |
| azul | Sala de Máquinas | saída na Recepção | azul claro | 3 (círculos da Sala de Máquinas) |

Cada chave **só aparece na sala dela** e fica escondida nas outras. O sorteio é feito **uma vez por partida**, quando o jogador aperta START, e não muda mais.

**Ainda não existe:** pegar a chave e abrir as portas (próxima etapa). A chave só flutua no lugar sorteado.

## Testar o jogo do AOC com as chaves, sem fazer commit

Nada abaixo cria commit nem altera o repositório de vocês.

### Jeito 1: só abrir a ROM (não precisa instalar nada)

Abra no Mesen o **`jogo_AOC_com_chaves.nes`**. É o jogo atual do AOC (commit `ebe0801`) **com as chaves**, exatamente o que o passo "O que alterar para incluir no jogo final" (abaixo) produz.

- A chave **verde** aparece no Quarto 2, num dos 3 lugares sorteados.
- A chave **azul não aparece**: a Sala de Máquinas ainda não está ligada ao jogo, e a chave azul só aparece nela. É o esperado.

Para ver as **duas chaves**, abra o `demo_chaves.nes`, que tem uma ligação provisória da Sala de Máquinas (porta no corredor da direita do Quarto 2).

### Jeito 2: compilar no seu AOC

1. **Faça uma cópia da pasta do AOC** (por exemplo `AOC-teste`). Assim o seu AOC original nunca é tocado, e para desfazer é só apagar a pasta de teste.
2. Na cópia, copie `chaves.s` para `src/` e o `TitleSprites.chr` desta pasta por cima de `assets/Tiles/TitleSprites.chr`.
3. Faça as 4 linhas no `src/main.s`. Duas opções:
   - com o git instalado, na pasta da cópia: `git apply CAMINHO\chaves_main.patch` (o arquivo `chaves_main.patch` está nesta pasta);
   - ou à mão, com as 4 linhas mostradas abaixo.
4. Compile e abra: `make` (gera `build/SystemFailure.nes`) e abra esse arquivo no Mesen, ou `make run`.

O patch foi feito para o AOC no commit `ebe0801`, e eu conferi que ele aplica sem conflito e que o jogo compila e roda. Se o `main.s` de vocês já tiver mudado nessas linhas, o `git apply` pode recusar: nesse caso faça as 4 linhas à mão.

Se você fizer no AOC original em vez de numa cópia, para desfazer: `git restore src/main.s assets/Tiles/TitleSprites.chr` e apague `src/chaves.s`.

### Depois de testar e aprovar (aí sim o commit)

No AOC de vocês, numa branch nova (não direto na `main`):

```
git checkout -b chaves
git add src/chaves.s src/main.s assets/Tiles/TitleSprites.chr
git commit -m "Chaves verde e azul: lugar sorteado e flutuando"
git push -u origin chaves
```

E abra um Pull Request da branch `chaves` para a `main` no GitHub. Quem aceitar o PR coloca na `main`.

## O que alterar para incluir no jogo final

### 1. Copiar 2 arquivos

| Arquivo (desta pasta) | Onde colocar no AOC |
|---|---|
| `chaves.s` | `src/chaves.s` (arquivo novo) |
| `TitleSprites.chr` | por cima de `assets/Tiles/TitleSprites.chr` |

O `TitleSprites.chr` desta pasta é o atual do AOC (já com o machado) mais os desenhos das chaves: só os tiles `$30-$33` e `$40-$43` mudaram. Se o `TitleSprites.chr` de vocês mudar antes de entrar (inimigos, itens), gere de novo com o `gerar_chaves.py` a partir do atual, para não apagar o trabalho dos outros.

### 2. Alterar o `src/main.s` (4 linhas)

Este é o diff exato que eu testei (as linhas com `+` são as novas):

```diff
 state_title:
+    jsr chaves_tick         ; CHAVES: conta o tempo na tela inicial (semente do sorteio)
     lda pad1
     and #BTN_START
```
```diff
     jsr draw_player         ; escreve os 4 sprites na copia da OAM
     jsr machado_update
+    jsr chaves_update       ; CHAVES: desenha as chaves da sala atual, flutuando
     jmp main_loop
```
```diff
     jsr machado_init        ; machado comeca no chao
     jsr hud_init            ; vida cheia, sem itens, 0 pontos
+    jsr chaves_init         ; CHAVES: sorteia o lugar de cada chave
 
     lda #1
```
```diff
 .include "machado.s"
+.include "chaves.s"
 .include "hud.s"
```

Mais nada no `main.s`. Não precisa mudar o `Makefile`, o `ppu.s`, o `variaveis.s` nem o `constantes.inc`.

### 3. Quando a Sala de Máquinas entrar no jogo

A Sala de Máquinas **ainda não está ligada ao jogo** (não existe `ROOM_MAQUINAS`, nem as tabelas `room_*`, nem portas). Enquanto isso, o `chaves.s` define `ROOM_MAQUINAS = 2` sozinho, e a chave azul simplesmente nunca aparece.

Quando vocês ligarem a sala, **ela precisa ser a sala número 2** (a terceira nas tabelas `room_*` de `salas.s`), ou então definam a constante no `constantes.inc`:

```asm
ROOM_QUARTO2  = 1
ROOM_MAQUINAS = 2        ; o chaves.s passa a usar esta constante, sem mudar nada nele
```

Se for outro número, é só definir `ROOM_MAQUINAS` com o número certo. O `chaves.s` só define a constante quando ela ainda não existe.

## Como funciona o sorteio

O NES não tem número aleatório. A solução é a clássica dos jogos de NES:

1. **Semente:** na tela inicial, a cada quadro, o contador `ck_rng` sobe 1 (`chaves_tick`). Quando o jogador aperta START, o valor depende de quanto tempo ele esperou.
2. **Embaralhar:** `chaves_init` passa a semente por um LFSR de 8 bits (8 passos, o gerador padrão de 255 valores) e tira o resto da divisão por 3, que dá 0, 1 ou 2. Faz isso duas vezes, uma para cada chave. Os dois lugares são independentes.

Por isso, **não é preciso mexer em nada para "ligar" a aleatoriedade**: ela já vem do tempo que o jogador leva para apertar START. Se o jogador apertar START sempre no mesmo quadro (um robô, ou um emulador com gravação de teclas), a partida sai igual. Com uma pessoa jogando, varia.

O resultado fica em `ck_spot` (2 bytes na Zero Page): `ck_spot+0` é o lugar da chave verde e `ck_spot+1` o da azul (0, 1 ou 2). A próxima etapa (pegar a chave) pode usar esses mesmos bytes.

## Os lugares (para mudar de lugar ou trocar quantidade)

Os lugares estão no fim de `chaves.s`, nas duas tabelas `ck_tab_x` e `ck_tab_y` (3 da chave verde, depois 3 da azul). Cada par X/Y é o canto de cima e da esquerda da chave **no chão**, em pixels:

| | lugar 0 | lugar 1 | lugar 2 |
|---|---|---|---|
| **verde** (Quarto 2) | (112, 96) | (16, 208) | (112, 208) |
| **azul** (Sala de Máquinas) | (192, 64) | (192, 128) | (96, 176) |

`chaves_lugares.png` mostra os 6 lugares como o jogo os desenha (3 em cada sala).

**Eu estimei estas posições a partir das suas imagens com os círculos**, e não por medida exata. Confira em `chaves_lugares.png` se cada uma está onde você queria. Se alguma estiver fora, é só trocar o par X/Y dela na tabela (X e Y múltiplos de 16 deixam a chave certinha no quadrado de chão).

- **Mudar a quantidade** de lugares por chave: troque `CK_LUGARES` no topo de `chaves.s` e acrescente ou tire um par X/Y em cada tabela (a mesma quantidade para as duas chaves). Testei com 2, 3 e 4 lugares.
- **Conferir um lugar novo:** as paredes são tiles `>= $80`. Confira se o quadrado de 16x16 é chão livre e se o personagem consegue chegar nele (a hitbox dele tem 12x12).

## Para ver

Abra **`demo_chaves.nes`** no Mesen (não precisa compilar). É o jogo atual do AOC (commit `ebe0801`) com as chaves, **mais uma ligação provisória da Sala de Máquinas** só para esta demonstração: uma porta no corredor da direita do Quarto 2 leva para ela, e uma porta à esquerda da Sala de Máquinas volta. Essa ligação não é a de vocês e não está no código do `chaves.s`.

Aperte START (quanto você espera na tela inicial muda o sorteio), vá para o Quarto 2 pela porta de baixo do Spawn e ande até o corredor da direita. Cada vez que você abrir a ROM e apertar START em outro momento, as chaves ficam em outros lugares.

Com a névoa de guerra (no Spawn e no Quarto 2), só se vê o que está perto do personagem, mas as chaves (sprites) aparecem sempre dentro da sala delas. Na demonstração, a Sala de Máquinas está sem névoa, só para você ver a sala inteira.

## A animação

A chave sobe e desce de 1 em 1 pixel, em degraus, como nos jogos antigos:

```
passo:      0  1  2  3  4  5  6  7        cada passo dura 8 quadros
sobe (px):  0  1  2  3  3  2  1  0        ciclo de 64 quadros; a azul começa 4 passos adiante
```

Para ficar mais rápida, tire um `lsr a` de `chave_desenha`. Para mudar a altura, edite `ck_tab_sobe`. Veja `chaves_ciclo.png`.

## Cores e tiles

As chaves usam **as paletas de sprite que o jogo já tem**: verde = paleta 1 (`$0F,$0B,$2A,$10`) e azul = paleta 0 (`$0F,$07,$37,$31`). Se alguém mudar essas paletas no `ppu.s`, as chaves mudam de cor junto (e o personagem e os inimigos parados também, que usam as mesmas).

Tiles (blocos 2x2, o mesmo formato do personagem e do machado): chave verde `$30 $31 / $40 $41`, chave azul `$32 $33 / $42 $43`.

## Uso de memória

| Recurso | Uso |
|---|---|
| Zero Page | 5 bytes: `ck_rng`, `ck_spot` (2), `ck_x`, `ck_y` |
| OAM | `$0230` a `$024F` (personagem `$00-$0F`, machado `$10-$2F`) |
| Tiles de sprite | `$30-$33` e `$40-$43` |

Lembrete: o NES mostra no máximo 8 sprites por linha da tela. Personagem, machado e duas chaves na mesma altura somam exatamente 8; as chaves de salas diferentes nunca aparecem juntas, então na prática são no máximo 6.

## Arquivos desta pasta

| Arquivo | Para quê |
|---|---|
| `chaves.s` | O módulo (sorteio, sala, lugares e animação). Cada instrução está comentada com A/X/Y. |
| `TitleSprites.chr` | O `TitleSprites.chr` do AOC com as 2 chaves. |
| `jogo_AOC_com_chaves.nes` | O jogo atual do AOC com as chaves (sem a Sala de Máquinas ligada). Para testar no Mesen. |
| `chaves_main.patch` | As 4 linhas do `main.s` num arquivo, para `git apply`. |
| `demo_chaves.nes` | ROM de demonstração para o Mesen, com ligação provisória da Sala de Máquinas. |
| `gerar_chaves.py` | Gera o `TitleSprites.chr` com as chaves (o desenho está em texto). |
| `chaves_lugares.png` | Os 6 lugares possíveis, como o jogo os desenha. |
| `chaves_ciclo.png` | Os 8 passos da animação. |
| `chaves_cores_finais.png`, `chaves_outras_cores.png` | Cores escolhidas e alternativas. |

## O que foi verificado

Tudo com o `ca65`/`ld65` reais (versão 2.19) e o `make` do AOC, rodando as ROMs num simulador de NES meu:

- **O sorteio** (na ROM real) bate com um modelo em Python escrito à parte, nas 256 sementes possíveis: 0 diferenças. Cada lugar sai com a mesma frequência (85 de 255 para cada um) e as 9 combinações de lugares entre as duas chaves aparecem.
- **Sala e lugar:** em 10 partidas com tempos diferentes na tela inicial, nenhuma chave aparece no Spawn, a verde só no Quarto 2 e a azul só na Sala de Máquinas, cada uma no lugar sorteado, flutuando. Ao ir e voltar entre as salas, o lugar não muda.
- **O resto do jogo não muda:** em 4 partidas de 400 quadros com botões aleatórios, comparando o AOC original e o com as 4 mudanças, personagem, machado, paletas, fundo, HUD e névoa ficaram idênticos.
- **Os 6 lugares** ficam em chão livre e alcançável a partir das portas, usando a hitbox real do jogo.
- `chaves.s` compila sem erro e sem aviso.
- **Não testado no Mesen.** Eu rodei só no meu simulador. Se algo ficar diferente, me mande um print.
- **A ligação da Sala de Máquinas é provisória** (só na ROM de demonstração): eu não testei com a ligação real de vocês, porque ela ainda não existe.

O jogo não foi alterado: nenhum arquivo do projeto usa esta pasta.
