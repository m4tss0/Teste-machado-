; =============================================================================
;  machado.s - MACHADO do SystemFailure (modulo ADICIONADO, nao altera o jogo)
;
;  Este arquivo e incluido por src/main_machado.s (.include "machado.s").
;  Ele depende dos nomes do main.s: player_x, player_y, player_dir, moving,
;  anim_timer, attack_timer, OAM, DIR_*, ATTACK_FRAMES.
;
;  O que faz:
;    1) PARADO:  o machado fica no chao do Quarto 2, em (AX_ITEM_X, AX_ITEM_Y).
;    2) PEGAR:   quando o personagem chega perto, o machado some do chao.
;    3) ACOMPANHA: depois de pego, o machado e desenhado na mao do personagem:
;         - parado ........ machado na mao (quadro 0)
;         - andando ....... balanca (quadros 0 e 1, troca junto com o passo)
;         - botao A ....... prepara, golpeia e recupera (quadros 2, 3 e 4)
;         - esquerda ...... e o desenho da direita espelhado (atributo $40)
;
;  Entradas do main.s:  chamar  jsr machado_init    uma vez, em start_game
;                       chamar  jsr machado_update  a cada quadro, em state_game
;
;  OAM: personagem = $0200-$020F | machado na mao = $0210-$021F | machado no chao = $0220-$022F
;
;  Convencao dos comentarios: "A <- 5" = o acumulador passa a valer 5; "[x] <- A" = a memoria x
;  recebe A; "A, X, Y intactos" = esses registradores nao mudam nesta linha.
; =============================================================================

; -----------------------------------------------------------------------------
;  CONFIGURACAO (so aqui voce mexe)
; -----------------------------------------------------------------------------
AX_PALETA    = 3            ; paleta de sprite do machado: a 3 do main.s ($0F,$07,$10,$28 = "itens")
AX_OAM_MAO   = $10          ; byte da OAM onde ficam os 4 sprites do machado na mao
AX_OAM_CHAO  = $20          ; byte da OAM onde ficam os 4 sprites do machado no chao
AX_ITEM_X    = 32           ; onde o machado fica parado no chao (canto de cima/esquerda, em pixels)
AX_ITEM_Y    = 32
AX_PERTO     = 12           ; distancia (pixels) para o personagem "pegar" o machado
AX_QUADRO_CHAO = 15         ; numero do quadro do machado no chao (os de 0 a 14 sao os da mao)

; -----------------------------------------------------------------------------
;  Variaveis na Zero Page (9 bytes). Todas comecam com "ax_" para nao colidir com as do jogo.
; -----------------------------------------------------------------------------
.segment "ZEROPAGE"
ax_have:    .res 1          ; 0 = machado ainda no chao | 1 = personagem esta com ele
ax_idx:     .res 1          ; quadro a desenhar (0 a 14) = conjunto * 5 + quadro
ax_tile:    .res 1          ; tile de cima/esquerda do quadro (o 2x2 e T, T+1, T+$10, T+$11)
ax_x:       .res 1          ; X do canto de cima/esquerda do quadro
ax_y:       .res 1          ; Y do canto de cima/esquerda do quadro
ax_attr:    .res 1          ; atributo (paleta) dos 4 sprites
ax_flip:    .res 1          ; 1 = espelhar na horizontal
ax_vdx:     .res 1          ; deslocamento X do quadro em relacao ao personagem (com sinal)
ax_vdy:     .res 1          ; deslocamento Y do quadro em relacao ao personagem (com sinal)

.segment "CODE"

; =============================================================================
; machado_init: chamado uma vez em start_game. Machado comeca no chao.
; Altera A, X.   Y intacto.
; =============================================================================
.proc machado_init
    lda #$00                ; A <- 0. X, Y intactos
    sta ax_have             ; [ax_have] <- A: machado no chao, ninguem esta com ele. A, X, Y intactos
    ldx #AX_OAM_MAO         ; X <- onde ficam os sprites da mao na OAM. A, Y intactos
    jsr ax_hide             ; esconde o machado da mao. Altera A. X, Y intactos
    jmp machado_draw        ; desenha o machado no chao (tail call: o rts de la volta pra quem chamou)
.endproc

; =============================================================================
; machado_update: chamado todo quadro, DEPOIS de draw_player.
; Se o machado ainda esta no chao, testa se o personagem chegou perto.
; Depois desenha. Altera A, X, Y.
; =============================================================================
.proc machado_update
    lda ax_have             ; A <- 1 se o personagem ja esta com o machado. X, Y intactos
    bne @desenha            ; ja pegou? nao precisa testar de novo. A, X, Y intactos

    ; --- perto em X?  |player_x - AX_ITEM_X| < AX_PERTO  (conta em 8 bits, sem sinal) ---
    lda player_x            ; A <- X do personagem. X, Y intactos
    sec                     ; C <- 1, antes de subtrair. A, X, Y intactos
    sbc #AX_ITEM_X          ; A <- player_x - X do machado (pode "dar a volta" se negativo). X, Y intactos
    clc                     ; C <- 0. A, X, Y intactos
    adc #AX_PERTO           ; A <- A + AX_PERTO: perto = resultado entre 0 e 2*AX_PERTO-1. X, Y intactos
    cmp #(AX_PERTO*2)       ; compara com a largura da janela. C = 1 se longe. X, Y intactos
    bcs @desenha            ; longe em X? nao pegou. A, X, Y intactos

    ; --- perto em Y? ---
    lda player_y            ; A <- Y do personagem. X, Y intactos
    sec                     ; C <- 1. A, X, Y intactos
    sbc #AX_ITEM_Y          ; A <- player_y - Y do machado. X, Y intactos
    clc                     ; C <- 0. A, X, Y intactos
    adc #AX_PERTO           ; A <- A + AX_PERTO. X, Y intactos
    cmp #(AX_PERTO*2)       ; C = 1 se longe. X, Y intactos
    bcs @desenha            ; longe em Y? nao pegou. A, X, Y intactos

    lda #$01                ; A <- 1. X, Y intactos
    sta ax_have             ; [ax_have] <- A: PEGOU o machado. A, X, Y intactos

@desenha:
    jmp machado_draw        ; desenha no chao ou na mao (tail call)
.endproc

; =============================================================================
; machado_draw: desenha o machado onde ele esta (chao ou mao). Altera A, X, Y.
; =============================================================================
.proc machado_draw
    lda ax_have             ; A <- 0 (no chao) ou 1 (na mao). X, Y intactos
    bne @na_mao             ; esta com o personagem? desenha na mao. A, X, Y intactos

    ; ---------- machado PARADO no chao ----------
    ldx #AX_QUADRO_CHAO     ; X <- quadro do machado no chao (15). A, Y intactos
    lda ax_tab_tile,x       ; A <- tile de cima/esquerda desse quadro. X, Y intactos
    sta ax_tile             ; [ax_tile] <- A. A, X, Y intactos
    lda #AX_ITEM_X          ; A <- X fixo do machado no chao. X, Y intactos
    sta ax_x                ; [ax_x] <- A. A, X, Y intactos
    lda #AX_ITEM_Y          ; A <- Y fixo do machado no chao. X, Y intactos
    sta ax_y                ; [ax_y] <- A. A, X, Y intactos
    lda #$00                ; A <- 0. X, Y intactos
    sta ax_flip             ; [ax_flip] <- 0: sem espelhar. A, X, Y intactos
    ldx #AX_OAM_CHAO        ; X <- posicao do machado do chao na OAM. A, Y intactos
    jmp ax_draw_final       ; poe a paleta e desenha (tail call). A, X, Y intactos

@na_mao:
    ; o machado do chao some (Y = $FF)
    ldx #AX_OAM_CHAO        ; X <- posicao do machado do chao na OAM. A, Y intactos
    jsr ax_hide             ; esconde os 4 sprites do chao. Altera A. X, Y intactos

    ; ---------- qual quadro? (A <- 0 a 4) ----------
    lda attack_timer        ; A <- quanto falta do ataque (0 = nao ataca). X, Y intactos
    beq @sem_golpe          ; nao esta atacando? A, X, Y intactos
    lda #ATTACK_FRAMES      ; A <- duracao total do ataque. X, Y intactos
    sec                     ; C <- 1, antes de subtrair. A, X, Y intactos
    sbc attack_timer        ; A <- quanto do ataque ja passou (0 a 11). X, Y intactos
    lsr a                   ; A <- A / 2. X, Y intactos
    lsr a                   ; A <- A / 4: fase 0, 1 ou 2 (cada fase dura 4 quadros). X, Y intactos
    cmp #$03                ; fase 3 ou mais? (so se ATTACK_FRAMES for maior que 12). C = 1 se sim. X, Y intactos
    bcc @fase_ok            ; fase de 0 a 2? esta certa. A, X, Y intactos
    lda #$02                ; A <- 2: segura na ultima fase. X, Y intactos
@fase_ok:
    clc                     ; C <- 0. A, X, Y intactos
    adc #$02                ; A <- fase + 2: quadro 2 (preparar), 3 (golpe) ou 4 (recuperar). X, Y intactos
    jmp @tem_quadro         ; A, X, Y intactos

@sem_golpe:
    lda moving              ; A <- 1 se o personagem andou neste quadro, 0 se esta parado. X, Y intactos
    beq @tem_quadro         ; parado? A ja vale 0: quadro 0 (machado na mao, parado). A, X, Y intactos
    lda anim_timer          ; A <- relogio das animacoes. X, Y intactos
    and #%00001000          ; A <- so o bit 3: muda a cada 8 quadros, igual ao passo do personagem. X, Y intactos
    lsr a                   ; A <- A / 2. X, Y intactos
    lsr a                   ; A <- A / 4. X, Y intactos
    lsr a                   ; A <- A / 8: 0 ou 1 (quadro "carregando A" ou "B"). X, Y intactos

@tem_quadro:                ; aqui A = quadro dentro do conjunto (0 a 4)
    ldy player_dir          ; Y <- direcao do personagem (indice da tabela). A, X intactos
    clc                     ; C <- 0. A, X, Y intactos
    adc ax_tab_set,y        ; A <- quadro + 5 * conjunto: indice final (0 a 14). X, Y intactos
    sta ax_idx              ; [ax_idx] <- A. A, X, Y intactos
    tax                     ; X <- indice do quadro, para ler as tabelas. A, Y intactos
    lda ax_tab_tile,x       ; A <- tile de cima/esquerda do quadro. X, Y intactos
    sta ax_tile             ; [ax_tile] <- A. A, X, Y intactos
    lda ax_tab_dx,x         ; A <- deslocamento X do quadro (com sinal). X, Y intactos
    sta ax_vdx              ; [ax_vdx] <- A. A, X, Y intactos
    lda ax_tab_dy,x         ; A <- deslocamento Y do quadro (com sinal). X, Y intactos
    sta ax_vdy              ; [ax_vdy] <- A. A, X, Y intactos

    lda #$00                ; A <- 0. X, Y intactos
    sta ax_flip             ; [ax_flip] <- 0: sem espelhar. A, X, Y intactos
    lda player_dir          ; A <- direcao. X, Y intactos
    cmp #DIR_LEFT           ; olhando para a esquerda? Z = 1 se sim. X, Y intactos
    bne @sem_espelho        ; nao? usa o deslocamento como esta. A, X, Y intactos
    lda #$01                ; A <- 1. X, Y intactos
    sta ax_flip             ; [ax_flip] <- 1: espelha o machado. A, X, Y intactos
    lda ax_vdx              ; A <- dx. X, Y intactos
    eor #$FF                ; A <- NOT dx (inverte todos os bits). X, Y intactos
    clc                     ; C <- 0. A, X, Y intactos
    adc #$01                ; A <- -dx (complemento de dois): o espelho reflete o deslocamento. X, Y intactos
    sta ax_vdx              ; [ax_vdx] <- -dx. A, X, Y intactos
@sem_espelho:
    lda player_x            ; A <- X do personagem. X, Y intactos
    clc                     ; C <- 0. A, X, Y intactos
    adc ax_vdx              ; A <- X + dx (soma com sinal, em 8 bits). X, Y intactos
    sta ax_x                ; [ax_x] <- A: X do machado. A, X, Y intactos
    lda player_y            ; A <- Y do personagem. X, Y intactos
    clc                     ; C <- 0. A, X, Y intactos
    adc ax_vdy              ; A <- Y + dy (soma com sinal, em 8 bits). X, Y intactos
    sta ax_y                ; [ax_y] <- A: Y do machado. A, X, Y intactos
    ldx #AX_OAM_MAO         ; X <- posicao do machado da mao na OAM. A, Y intactos
    ; (os limites MIN_X/MAX_X/MIN_Y/MAX_Y do main.s mantem o machado dentro da tela:
    ;  dx vai de -10 a +12 e dy de -10 a +13)
    jmp ax_draw_final       ; (tail call)
.endproc

; -----------------------------------------------------------------------------
;  ax_draw_final: poe a paleta em ax_attr e desenha. Entrada: X = posicao na OAM
;  (+ ax_tile, ax_x, ax_y, ax_flip).  Altera A, X.   Y intacto.
; -----------------------------------------------------------------------------
.proc ax_draw_final
    lda #AX_PALETA          ; A <- paleta de sprite do machado (3). X, Y intactos
    sta ax_attr             ; [ax_attr] <- A. A, X, Y intactos
    ; (continua em ax_draw16, logo abaixo)
.endproc

; -----------------------------------------------------------------------------
;  ax_draw16: escreve 4 sprites 8x8 (um quadro 2x2) na OAM, a partir de OAM + X.
;  Mesma ordem do draw_player:  T = cima/esq, T+1 = cima/dir, T+$10 = baixo/esq, T+$11 = baixo/dir.
;  Altera A.  X e Y intactos.
; -----------------------------------------------------------------------------
.proc ax_draw16
    lda ax_y                ; A <- Y do topo. X, Y intactos
    sta OAM+0,x             ; [OAM+0] <- A: Y do sprite de cima/esquerda. A, X, Y intactos
    sta OAM+4,x             ; [OAM+4] <- A: Y de cima/direita. A, X, Y intactos
    clc                     ; C <- 0. A, X, Y intactos
    adc #$08                ; A <- Y + 8: a linha de baixo. X, Y intactos
    sta OAM+8,x             ; [OAM+8] <- A: Y de baixo/esquerda. A, X, Y intactos
    sta OAM+12,x            ; [OAM+12] <- A: Y de baixo/direita. A, X, Y intactos

    lda ax_x                ; A <- X da coluna da esquerda. X, Y intactos
    sta OAM+3,x             ; [OAM+3] <- A: X de cima/esquerda. A, X, Y intactos
    sta OAM+11,x            ; [OAM+11] <- A: X de baixo/esquerda. A, X, Y intactos
    clc                     ; C <- 0. A, X, Y intactos
    adc #$08                ; A <- X + 8: a coluna da direita. X, Y intactos
    sta OAM+7,x             ; [OAM+7] <- A: X de cima/direita. A, X, Y intactos
    sta OAM+15,x            ; [OAM+15] <- A: X de baixo/direita. A, X, Y intactos

    lda ax_flip             ; A <- 1 se espelhado. Z = 1 se nao. X, Y intactos
    bne @espelhado          ; espelhado? outro arranjo dos tiles. A, X, Y intactos

    lda ax_attr             ; A <- atributo normal (so a paleta). X, Y intactos
    sta OAM+2,x             ; [OAM+2] <- A. A, X, Y intactos
    sta OAM+6,x             ; [OAM+6] <- A. A, X, Y intactos
    sta OAM+10,x            ; [OAM+10] <- A. A, X, Y intactos
    sta OAM+14,x            ; [OAM+14] <- A. A, X, Y intactos
    lda ax_tile             ; A <- T. X, Y intactos
    sta OAM+1,x             ; [OAM+1] <- A: cima/esquerda = T. A, X, Y intactos
    clc                     ; C <- 0. A, X, Y intactos
    adc #$01                ; A <- T + 1. X, Y intactos
    sta OAM+5,x             ; [OAM+5] <- A: cima/direita = T+1. A, X, Y intactos
    clc                     ; C <- 0. A, X, Y intactos
    adc #$0F                ; A <- T + $10. X, Y intactos
    sta OAM+9,x             ; [OAM+9] <- A: baixo/esquerda = T+$10. A, X, Y intactos
    clc                     ; C <- 0. A, X, Y intactos
    adc #$01                ; A <- T + $11. X, Y intactos
    sta OAM+13,x            ; [OAM+13] <- A: baixo/direita = T+$11. A, X, Y intactos
    rts                     ; volta. A = T + $11. X, Y intactos

@espelhado:
    lda ax_attr             ; A <- paleta. X, Y intactos
    ora #$40                ; A <- A OR %01000000: liga o espelhamento horizontal de cada sprite. X, Y intactos
    sta OAM+2,x             ; [OAM+2] <- A. A, X, Y intactos
    sta OAM+6,x             ; [OAM+6] <- A. A, X, Y intactos
    sta OAM+10,x            ; [OAM+10] <- A. A, X, Y intactos
    sta OAM+14,x            ; [OAM+14] <- A. A, X, Y intactos
    lda ax_tile             ; A <- T. X, Y intactos
    sta OAM+5,x             ; [OAM+5] <- A: T vai para a coluna da DIREITA (desenho espelhado). A, X, Y intactos
    clc                     ; C <- 0. A, X, Y intactos
    adc #$01                ; A <- T + 1. X, Y intactos
    sta OAM+1,x             ; [OAM+1] <- A: T+1 vai para a coluna da ESQUERDA. A, X, Y intactos
    clc                     ; C <- 0. A, X, Y intactos
    adc #$0F                ; A <- T + $10. X, Y intactos
    sta OAM+13,x            ; [OAM+13] <- A: T+$10 vai para baixo/direita. A, X, Y intactos
    clc                     ; C <- 0. A, X, Y intactos
    adc #$01                ; A <- T + $11. X, Y intactos
    sta OAM+9,x             ; [OAM+9] <- A: T+$11 vai para baixo/esquerda. A, X, Y intactos
    rts                     ; volta. A = T + $11. X, Y intactos
.endproc

; -----------------------------------------------------------------------------
;  ax_hide: esconde 4 sprites (Y = $FF, fora da tela), a partir de OAM + X.
;  Altera A.  X e Y intactos.
; -----------------------------------------------------------------------------
.proc ax_hide
    lda #$FF                ; A <- $FF: Y fora da tela (o mesmo valor que o reset usa). X, Y intactos
    sta OAM+0,x             ; [OAM+0] <- A: esconde o sprite 0. A, X, Y intactos
    sta OAM+4,x             ; [OAM+4] <- A: esconde o sprite 1. A, X, Y intactos
    sta OAM+8,x             ; [OAM+8] <- A: esconde o sprite 2. A, X, Y intactos
    sta OAM+12,x            ; [OAM+12] <- A: esconde o sprite 3. A, X, Y intactos
    rts                     ; volta. A = $FF. X, Y intactos
.endproc

; -----------------------------------------------------------------------------
;  TABELAS (ficam na ROM)
; -----------------------------------------------------------------------------
.segment "RODATA"

; Conjunto de desenhos por direcao (indice = player_dir: baixo, cima, direita, esquerda).
; Valor = 5 * conjunto:  0 = "direita" (a esquerda usa o mesmo, espelhado) | 5 = "baixo" | 10 = "cima"
ax_tab_set:  .byte 5, 10, 0, 0

; Tile de cima/esquerda de cada quadro (indice 0 a 14 = mao, 15 = machado no chao).
; Cada quadro e um bloco 2x2 na grade do NEXXT: T, T+1, T+$10, T+$11.
ax_tab_tile: .byte $C0,$C2,$C4,$C6,$C8,$CA,$CC,$CE
             .byte $E0,$E2,$E4,$E6,$E8,$EA,$EC,$EE

; Posicao de cada quadro em relacao ao personagem (com sinal; indice = conjunto * 5 + quadro).
; Quadros de cada conjunto: 0 carregando A, 1 carregando B, 2 preparar, 3 golpe, 4 recuperar.
;               --- direita ---------------   --- baixo ----------------   --- cima ------------------
ax_tab_dx:   .byte   9,  10,   0,  12,  10,       9,  10,   3,   4,  -5,      -9, -10,  -1,  -1,  -3
ax_tab_dy:   .byte  -3,  -4,  -9,   2,   8,      -1,  -2,  -8,  11,  13,      -4,  -4,   7, -10, -10

.segment "CODE"
