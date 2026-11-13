# Machado: integração ao SystemFailure

O machado foi integrado **só com arquivos novos**. Nenhum arquivo que já existia no repositório foi alterado (`main.s`, `Makefile`, `nes.cfg`, os `.chr`, os mapas e o `README.md` continuam como estavam).

## O que o machado faz

| Situação | O que aparece |
|---|---|
| **Parado** | Machado no chão do Quarto 2, no canto superior esquerdo (x=32, y=32). |
| **Pegar** | Ao chegar perto dele (menos de 12 pixels em X e em Y), o machado sai do chão. |
| **Acompanha o personagem** | Parado: machado na mão. Andando: balança, no mesmo ritmo do passo do personagem. |
| **Botão A** | Prepara, golpeia e recupera: 3 fases de 4 quadros de tela cada, somando os 12 do `ATTACK_FRAMES`. |
| **Esquerda** | É o desenho da direita espelhado (atributo `$40`), igual ao que o personagem já faz. |

Imagens: `docs/machado/1_machado_parado_no_chao.png`, `docs/machado/2_machado_golpeando.png` e `docs/machado/3_machado_acompanha_folha.png`. A folha tem uma direção por linha (baixo, cima, direita, esquerda). Nas colunas: andando (2 passos), parado, e o ataque (início, meio e fim).

## Arquivos adicionados (todos novos)

| Arquivo | Para quê |
|---|---|
| `src/machado.s` | Módulo do machado (código em ca65, cada instrução comentada com A/X/Y). |
| `src/main_machado.s` | Cópia do `main.s` com 4 pontos de integração (ver o diff abaixo). |
| `assets/Tiles/TitleSprites_machado.chr` | `TitleSprites.chr` + machado nos tiles `$C0-$FF` (que estavam vazios). |
| `assets/Machado/machado_slots.chr` | Arte original do machado (fonte para gerar o CHR acima). |
| `tools/mesclar_machado.py` | Gera o CHR novo. Recusa e não grava nada se algum tile de destino já tiver desenho. |
| `Makefile.machado` | Compila para `build/machado.nes`, sem tocar no `Makefile`. |
| `docs/machado/*.png` | Imagens do resultado. |
| `MACHADO-INTEGRACAO.md` | Este arquivo. |

## Como compilar e abrir

```bash
make -f Makefile.machado          # gera build/machado.nes
make -f Makefile.machado run      # gera e abre no Mesen
```

O jogo original continua compilando com o `make` de sempre. O `.nes` do machado tem outro nome (`build/machado.nes`), então um não sobrescreve o outro. O `assets/Tiles/TitleSprites_machado.chr` já está pronto; para regerá-lo, use `make -f Makefile.machado chr`.

## O que mudou no main (diff completo)

São 4 pontos: uma chamada em `start_game`, uma em `state_game`, o `.include` e o `.incbin` do CHR novo.

```diff
@@ state_game:
     jsr update_player       ; le o controle e move o personagem
     jsr draw_player         ; escreve os 4 sprites na copia da OAM
+    jsr machado_update      ; MACHADO: pega o machado do chao e desenha (chao ou mao)
     jmp main_loop

@@ start_game:
     jsr draw_player
+    jsr machado_init        ; MACHADO: comeca parado no chao do quarto

@@ antes de "Dados":
+.include "machado.s"

@@ CHARS:
-.incbin "assets/Tiles/TitleSprites.chr"      ; $0000: tela inicial + sprites
+.incbin "assets/Tiles/TitleSprites_machado.chr"   ; MACHADO: $0000 = tela inicial + sprites + machado ($C0-$FF)
```

Para ver o diff completo a qualquer momento: `diff -u src/main.s src/main_machado.s`.

**Se vocês quiserem usar o machado no `main.s` de verdade**, é só repetir essas 4 mudanças nele (e trocar o nome do `.incbin`). O módulo não precisa de nenhuma outra alteração.

## Decisões e detalhes

- **Formato dos tiles:** cada quadro do machado é um bloco 2x2 na grade do NEXXT (`T`, `T+1`, `T+$10`, `T+$11`), igual ao personagem. Os 16 quadros (15 da mão + 1 do chão) ocupam as linhas `$C0-$DF` (quadros 0 a 7) e `$E0-$FF` (quadros 8 a 15) da grade, cada quadro em 2 colunas e 2 linhas de tiles. Os tiles da tela inicial (`$00-$6F`) e do personagem (`$80-$AC`) não foram tocados.
- **Tabela de sprites:** o jogo usa a pattern table `$0000` para sprites (`PPUCTRL_GAME = %10010000`), por isso o machado está no `TitleSprites`, não no `Rooms`.
- **OAM:** personagem em `$0200-$020F` (como antes), machado na mão em `$0210-$021F`, machado no chão em `$0220-$022F`.
- **Paleta:** o machado usa a paleta de sprite 3 que já existe no `main.s` (`$0F,$07,$10,$28`, "itens"). O aço fica cinza e o cabo amarelado. Para mudar a cor sem mexer no `main.s`, é só trocar `AX_PALETA` em `src/machado.s`. Para um cabo marrom de verdade, alguém precisaria ajustar uma paleta de sprite no `main.s`.
- **Zero Page:** o módulo usa mais 9 bytes (`ax_have`, `ax_idx`, `ax_tile`, `ax_x`, `ax_y`, `ax_attr`, `ax_flip`, `ax_vdx`, `ax_vdy`). Todos começam com `ax_` para não colidir com os de vocês.
- **Posição na mão:** os deslocamentos (`ax_tab_dx` e `ax_tab_dy`) foram desenhados para um personagem de 16x16. Nas imagens, o machado fica na mão do seu personagem nas 4 direções. Se vocês redesenharem o personagem, ajustem só essas duas tabelas.

## O que ainda não existe (de propósito)

- O machado **não causa dano**: o jogo ainda não tem inimigos. Quando o Enzo tiver os inimigos, o golpe pode ser detectado com `attack_timer` e a direção do personagem (`player_dir`).
- O machado do chão **não é um objetivo de pontuação** (é do Jacques). Ele só some do chão quando pego.
- A colisão com as paredes é a "provisória" do `main.s` (só limites da tela). O machado herda isso.

## O que foi verificado e o que NÃO foi

**Verificado, num simulador de NES e montador que eu mesmo escrevi (em Python):**

- O montador de teste, aplicado ao `main.s` **original**, gera uma ROM **idêntica byte a byte** ao `build/teste.nes` que veio no repositório (40976 bytes, 0 diferenças). Isso valida o montador para este projeto.
- O `main_machado.s` monta sem erros.
- Em 4800 quadros com botões aleatórios (4 sementes), o personagem fica **idêntico ao do jogo original**: variáveis e OAM, quadro a quadro. O machado bate com um modelo independente (escrito a partir da especificação) em todos os quadros: chão, pegar, as 4 direções, andar, parado e atacar.
- Nenhum arquivo rastreado pelo git foi modificado (conferido por `git status` e por SHA-256 de todos os 17 arquivos originais).

**NÃO verificado:**

- Não rodei `ca65`, `ld65` nem o Mesen de verdade (não existem no ambiente onde eu trabalho). Se o `ca65` real reclamar de alguma linha, me mande a mensagem exata que eu corrijo.
- As cores finais do Mesen podem diferir um pouco das das minhas imagens (cada emulador tem sua paleta NTSC).

## Um problema que já existia no `Makefile` original

O alvo do `Makefile` se chama `build/teste.nes`, mas o `ld65` grava `build/SystemFailure.nes`. Por isso o `make` pode achar que o alvo nunca está pronto e recompilar sempre. Não mexi nisso. O `Makefile.machado` não tem esse problema (o alvo e o arquivo gerado têm o mesmo nome).
