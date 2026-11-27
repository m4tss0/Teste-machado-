# Chaves (verde e azul): tiles

Esta pasta tem **só os tiles** das duas chaves. Posição, pegar a chave e abrir portas ficam para depois.

| Chave | Onde fica | O que abre | Cor |
|---|---|---|---|
| 1 | Quarto 2 | Sala de Máquinas | verde |
| 2 | Sala de Máquinas | saída na Recepção | azul |

## Arquivos

| Arquivo | Para quê |
|---|---|
| `TitleSprites.chr` | O `TitleSprites.chr` atual da `main` do AOC (commit `b736bb2`, já com o machado) **mais a chave**. Só 4 tiles mudaram: `$30`, `$31`, `$40`, `$41`. |
| `gerar_chaves.py` | Gera esse arquivo. Tem o desenho da chave em texto (16 linhas), fácil de editar. Recusa gravar se o lugar já tiver desenho. |
| `chave_verde_e_azul.png` | Como a chave fica, em verde e em azul, sobre chão preto e sobre parede cinza. |
| `chaves_no_jogo_teste.png` | Captura do jogo com as duas chaves (posições e paletas de **teste**, não são as finais). |

## Um desenho, duas cores

O HUD já faz assim: a chave verde e a azul são **o mesmo tile** (`$37` do `Rooms.chr`) e só a paleta muda. Fiz igual para a chave no chão: **um desenho de 16x16 (4 tiles)**, usado com uma paleta verde e outra azul. Isso gasta 4 tiles, e não 8, o que importa porque os tiles livres são poucos.

O desenho segue o ícone do HUD: argola vazada em cima, haste e dois dentes à esquerda.

## Tiles usados

O desenho é um bloco 2x2 da grade do NEXXT, no mesmo formato do personagem e do machado:

```
$30  $31        sprite 0 = cima/esquerda  = $30
$40  $41        sprite 1 = cima/direita   = $31
                sprite 2 = baixo/esquerda = $40
                sprite 3 = baixo/direita  = $41
```

Indices de cor do desenho: `1` contorno, `2` corpo da chave, `3` brilho (`0` é transparente).

Tiles que continuam livres em `TitleSprites.chr` (vazios e não usados como fundo pela tela inicial): `$07-$0F`, `$26-$2F`, `$32-$3F`, `$42-$43`, `$70-$7F`, `$AE-$AF` e `$BE-$BF`. O personagem ocupa `$80-$AD` e o machado `$C0-$FF` (os buracos `$DB`, `$E1` e `$F4` fazem parte do desenho do machado). A tela inicial não usa os tiles `$30`, `$31`, `$40` e `$41` da chave.

## Paletas: decisão pendente do grupo

As cores que combinam com o HUD (o corpo da chave usa a mesma cor do ícone do HUD):

| Chave | Paleta (índices 1, 2, 3) | Observação |
|---|---|---|
| verde | `$0F, $19, $29` | corpo `$19` = verde do HUD |
| azul | `$0F, $21, $31` | corpo `$21` = azul do HUD |

O problema: as **4 paletas de sprite** do `ppu.s` já têm dono (0 personagem, 1 inimigo parado, 2 inimigo que persegue, 3 itens e machado). Para as chaves aparecerem verde e azul, o grupo precisa decidir quais duas paletas liberar ou mudar. Isso mexe no `ppu.s` e pode colidir com as cores dos inimigos do Enzo, por isso não alterei nada lá.

Cada sprite escolhe a paleta pelos 2 últimos bits do byte de atributo (`0` a `3`). Para a chave, os 4 sprites usam a mesma paleta.

## Para mudar o desenho

1. Edite o texto `CHAVE` em `gerar_chaves.py` (16 linhas de 16 caracteres: `.` transparente, `1` contorno, `2` corpo, `3` brilho).
2. Rode `python3 gerar_chaves.py ENTRADA.chr SAIDA.chr` (a entrada é o `TitleSprites.chr` atual do jogo).
3. Se o `TitleSprites.chr` do jogo mudar (inimigos, itens), gere de novo a partir do atual, para não apagar o trabalho dos outros.

O jogo não foi alterado: esta pasta não é usada por nenhum arquivo `.s`.
