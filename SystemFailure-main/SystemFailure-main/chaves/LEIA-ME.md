# Chaves (verde e azul): tiles e cores finais

Esta pasta tem **só os tiles** das duas chaves, para o grupo ver e aprovar antes de entrar no projeto. Posição, pegar a chave e abrir portas ficam para depois.

| Chave | Onde fica | O que abre | Cor |
|---|---|---|---|
| 1 | Quarto 2 | Sala de Máquinas | verde |
| 2 | Sala de Máquinas | saída na Recepção | azul (claro) |

**As chaves usam as paletas de sprite que o jogo já tem. O `ppu.s` não muda.**

## Para ver as cores finais

Abra **`demo_chaves.nes`** no Mesen (não precisa compilar). É o jogo atual do AOC (commit `ebe0801`, com HUD e névoa) com as duas chaves desenhadas em posições de teste, perto de onde o personagem começa. Aperte START: as chaves já aparecem (são sprites, a névoa de guerra só esconde o fundo). Para vê-las junto das paredes e do chão, ande até perto delas, em x=112 a 150 e y=64.

As chaves ficam fixas na tela, e o machado continua onde estava. **Esta ROM é só para conferir as cores.** O código que desenha as chaves nela é o `demo_chaves.s` (uma tabela de 8 sprites), e não faz parte do jogo.

Imagens:
- `chaves_cores_finais.png`: as duas chaves ampliadas, dentro do jogo.
- `chaves_no_jogo.png`: tela do jogo com as chaves.
- `chaves_outras_cores.png`: o mesmo desenho com todas as combinações possíveis das paletas atuais (verde, azul claro, vermelha, amarela, cinza e bege), caso o grupo prefira outra cor.

## Cores

| Chave | Paleta (atributo) | Corpo | Contorno | Brilho |
|---|---|---|---|---|
| verde | **1** (`$0F,$0B,$2A,$10`, a do "inimigo parado") atributo `$01` | `$2A` verde vivo | `$0B` verde escuro | `$10` cinza |
| azul | **0** (`$0F,$07,$37,$31`, a do personagem) atributo `$00` | `$31` azul claro | `$07` marrom | `$37` bege |

O azul é mais claro que o do HUD (`$21`), porque `$31` é o único azul das paletas atuais. As paletas 2 e 3 não têm azul.

**Se alguém mudar as cores da paleta 0 ou da paleta 1 no `ppu.s`, as chaves mudam de cor junto**, porque usam essas paletas. Isso vale também para o personagem (paleta 0) e para os inimigos parados (paleta 1).

## Tiles

Cada chave é um bloco 2x2 da grade do NEXXT, no mesmo formato do personagem e do machado:

```
chave VERDE      chave AZUL
$30  $31         $32  $33        sprite 0 = cima/esquerda   sprite 1 = cima/direita
$40  $41         $42  $43        sprite 2 = baixo/esquerda  sprite 3 = baixo/direita
```

São **dois desenhos de 4 tiles** porque o azul `$31` está na posição 3 da paleta 0, e não na 2: a chave azul tem o corpo pintado com o índice de cor 3 e a verde com o índice 2. O formato do desenho é o mesmo, só a cor de cada região muda.

## Como usar na OAM (quando for a hora)

Para cada chave, 4 sprites. Exemplo da chave verde em (x, y):

| Sprite | Y | Tile | Atributo | X |
|---|---|---|---|---|
| cima/esquerda | y | `$30` | `$01` | x |
| cima/direita | y | `$31` | `$01` | x + 8 |
| baixo/esquerda | y + 8 | `$40` | `$01` | x |
| baixo/direita | y + 8 | `$41` | `$01` | x + 8 |

A chave azul é igual, com os tiles `$32`, `$33`, `$42`, `$43` e atributo `$00`. Veja `demo_chaves.s`.

## Arquivos

| Arquivo | Para quê |
|---|---|
| `TitleSprites.chr` | O `TitleSprites.chr` atual do AOC (já com o machado) **mais as 2 chaves**. Só 8 tiles mudaram: `$30-$33` e `$40-$43`. Para usar, copie por cima de `assets/Tiles/TitleSprites.chr` do AOC. |
| `demo_chaves.nes` | ROM de teste para ver as cores no Mesen. |
| `demo_chaves.s` | O código de teste que desenha as chaves na ROM acima. |
| `gerar_chaves.py` | Gera o `TitleSprites.chr`. O desenho está em texto (16 linhas), fácil de editar. Recusa gravar se algum tile de destino já tiver desenho. |
| `*.png` | Imagens de conferência. |

## Tiles que continuam livres

Em `TitleSprites.chr` (vazios e não usados pela tela inicial): `$07-$0F`, `$26-$2F`, `$34-$3F`, `$70-$7F`, `$AE-$AF` e `$BE-$BF`. O personagem ocupa `$80-$AD` e o machado `$C0-$FF` (`$DB`, `$E1` e `$F4` são buracos dentro do desenho do machado, não use). A tela inicial não usa nenhum tile das chaves.

## Para mudar o desenho ou as cores

1. Edite o texto `CHAVE` em `gerar_chaves.py` (16 linhas de 16 caracteres: `.` transparente, `1` contorno, `2` corpo, `3` brilho). Para trocar a cor, troque o atributo ou o mapa de índices (`VERDE_MAPA` e `AZUL_MAPA`).
2. Rode `python3 gerar_chaves.py ENTRADA.chr SAIDA.chr` (a entrada é o `TitleSprites.chr` atual do jogo).
3. Se o `TitleSprites.chr` do jogo mudar (inimigos, itens), gere de novo a partir do atual, para não apagar o trabalho dos outros.

## O que foi verificado

- A ROM `demo_chaves.nes` foi compilada com o `ca65`/`ld65` reais (versão 2.19) e o `make` do AOC, e rodada num simulador de NES meu. As paletas lidas da PPU na execução são as originais do `ppu.s`.
- Os 8 tiles gravados decodificam de volta para o desenho. O machado e o personagem continuam intactos.
- **Não foi testado no Mesen.** As cores podem variar um pouco, porque cada emulador tem sua paleta NTSC. Por isso a ROM está aqui: se algo ficar diferente no Mesen, me mande um print.

O jogo não foi alterado: nenhum arquivo `.s` do projeto usa esta pasta.
