# Chaves (verde e azul): sprites que flutuam

Esta pasta tem as duas chaves como **sprites animados**, para o grupo ver e aprovar antes de entrar no projeto. Posição final, pegar a chave e abrir portas ficam para depois.

| Chave | Onde fica | O que abre | Cor |
|---|---|---|---|
| 1 | Quarto 2 | Sala de Máquinas | verde |
| 2 | Sala de Máquinas | saída na Recepção | azul (claro) |

**As chaves usam as paletas de sprite que o jogo já tem. O `ppu.s` não muda.**

## A animação

Estilo de jogo antigo: a chave **sobe e desce de 1 em 1 pixel, em degraus**, sem movimento suave.

```
passo:      0  1  2  3  4  5  6  7        cada passo dura 8 quadros
sobe (px):  0  1  2  3  3  2  1  0        0 = no chão, 3 = no alto
```

- Um ciclo completo dura **64 quadros** (um pouco mais de 1 segundo) e sobe no máximo 3 pixels.
- A chave **azul começa no meio do ciclo** (32 quadros adiante), então as duas nunca se mexem juntas.
- O relógio é o `anim_timer` que o jogo já tem, o mesmo do passo do personagem. Como ele dá a volta em 256 (múltiplo de 64), o ciclo nunca dá um salto.
- Para ficar mais rápida, tire um `lsr a` de `chave_desenha`. Para mudar a altura, edite a tabela `ck_tab_sobe`.

`chaves_ciclo.png` mostra os 8 passos (a linha vermelha marca a altura da chave no chão).

## Para ver

Abra **`demo_chaves.nes`** no Mesen (não precisa compilar). É o jogo atual do AOC (commit `ebe0801`, com HUD e névoa) com as duas chaves flutuando perto de onde o personagem começa. Aperte START: as chaves já aparecem, porque são sprites e a névoa de guerra só esconde o fundo. Para vê-las junto das paredes e do chão, ande até perto delas (x=112 a 150, y=64). As chaves também aparecem, na mesma posição, no Quarto 2.

**Esta ROM é só para conferir.** As posições são de teste, e a chave ainda não pode ser pega.

Imagens: `chaves_ciclo.png` (os 8 passos), `chaves_cores_finais.png` (as duas chaves ampliadas), `chaves_no_jogo.png` (tela do jogo) e `chaves_outras_cores.png` (o mesmo desenho com as outras cores possíveis das paletas atuais, caso o grupo prefira).

## Como colocar no jogo (2 linhas no `main.s`)

1. Copie `chaves.s` para `src/` e `TitleSprites.chr` por cima de `assets/Tiles/TitleSprites.chr` (ele é o atual de vocês, já com o machado, mais as chaves).
2. No `main.s`:
```asm
.include "chaves.s"          ; junto dos outros .include de rotinas (depois de "machado.s")

state_game:
    ...
    jsr machado_update
    jsr chaves_update        ; CHAVES
    jmp main_loop
```

O módulo usa **1 byte da Zero Page** (`ck_y`) e a OAM de `$0230` a `$024F`. O personagem usa `$0200-$020F` e o machado `$0210-$022F`, então não há conflito. Mais de 8 sprites na mesma linha da tela fazem o NES apagar o excesso: com personagem, machado e as duas chaves alinhados na mesma altura são exatamente 8. Se o Enzo colocar inimigos, vale conferir.

## Posições (de teste)

As posições estão nas tabelas do fim de `chaves.s`: `ck_tab_x` e `ck_tab_y` (o valor é a posição da chave **no chão**, e ela sobe até 3 pixels a partir dali).

| Chave | X | Y |
|---|---|---|
| verde | 112 | 64 |
| azul | 140 | 64 |

São posições de chão livre nas duas salas (Spawn e Quarto 2). A posição final de cada chave depende do mapa e fica para depois.

## Cores

| Chave | Paleta (atributo) | Corpo | Contorno | Brilho |
|---|---|---|---|---|
| verde | **1** (`$0F,$0B,$2A,$10`, a do "inimigo parado") atributo `$01` | `$2A` verde vivo | `$0B` verde escuro | `$10` cinza |
| azul | **0** (`$0F,$07,$37,$31`, a do personagem) atributo `$00` | `$31` azul claro | `$07` marrom | `$37` bege |

O azul é mais claro que o do HUD (`$21`), porque `$31` é o único azul das paletas atuais.

**Se alguém mudar as cores da paleta 0 ou da paleta 1 no `ppu.s`, as chaves mudam de cor junto**, porque usam essas paletas. Isso vale também para o personagem (paleta 0) e para os inimigos parados (paleta 1).

## Tiles

Cada chave é um bloco 2x2 da grade do NEXXT, no mesmo formato do personagem e do machado:

```
chave VERDE      chave AZUL
$30  $31         $32  $33        sprite 0 = cima/esquerda   sprite 1 = cima/direita
$40  $41         $42  $43        sprite 2 = baixo/esquerda  sprite 3 = baixo/direita
```

São **dois desenhos de 4 tiles** porque o azul `$31` está na posição 3 da paleta 0, e não na 2: a chave azul tem o corpo pintado com o índice de cor 3 e a verde com o índice 2.

## Arquivos

| Arquivo | Para quê |
|---|---|
| `chaves.s` | O módulo: desenha as duas chaves flutuando. Cada instrução está comentada com A/X/Y. |
| `TitleSprites.chr` | O `TitleSprites.chr` atual do AOC (já com o machado) **mais as 2 chaves**. Só 8 tiles mudaram: `$30-$33` e `$40-$43`. |
| `demo_chaves.nes` | ROM de teste para ver a animação e as cores no Mesen. |
| `gerar_chaves.py` | Gera o `TitleSprites.chr`. O desenho está em texto (16 linhas), fácil de editar. Recusa gravar se algum tile de destino já tiver desenho. |
| `*.png` | Imagens de conferência. |

## Tiles que continuam livres

Em `TitleSprites.chr` (vazios e não usados pela tela inicial): `$07-$0F`, `$26-$2F`, `$34-$3F`, `$70-$7F`, `$AE-$AF` e `$BE-$BF`. O personagem ocupa `$80-$AD` e o machado `$C0-$FF` (`$DB`, `$E1` e `$F4` são buracos dentro do desenho do machado, não use).

## Para mudar o desenho ou as cores

1. Edite o texto `CHAVE` em `gerar_chaves.py` (16 linhas de 16 caracteres: `.` transparente, `1` contorno, `2` corpo, `3` brilho). Para trocar a cor, troque o atributo em `ck_tab_attr` e o mapa de índices (`VERDE_MAPA` e `AZUL_MAPA`).
2. Rode `python3 gerar_chaves.py ENTRADA.chr SAIDA.chr` (a entrada é o `TitleSprites.chr` atual do jogo).
3. Se o `TitleSprites.chr` do jogo mudar (inimigos, itens), gere de novo a partir do atual, para não apagar o trabalho dos outros.

## O que foi verificado

Tudo com o `ca65`/`ld65` reais (versão 2.19) e o `make` do AOC, rodando a ROM num simulador de NES meu:

- **A animação:** 300 quadros comparados com um modelo escrito à parte: 0 diferenças. A chave sobe de 61 a 64 (3 pixels), nunca salta mais de 1 pixel por vez, tem período de 64 quadros e a azul está 32 quadros adiante.
- **O resto do jogo não muda:** em 4 partidas de 500 quadros com botões aleatórios, comparando o AOC sem as chaves e com elas, personagem, machado, paletas, fundo e HUD ficaram idênticos.
- **Troca de sala:** atravessar a porta para o Quarto 2, atacar, andar e voltar deu 0 diferenças, e as chaves continuam flutuando nas duas salas.
- `chaves.s` compila sem erro e sem aviso.
- **Não foi testado no Mesen.** As cores podem variar um pouco, porque cada emulador tem sua paleta NTSC. Se algo ficar diferente, me mande um print.

O jogo não foi alterado: nenhum arquivo `.s` do projeto usa esta pasta.
