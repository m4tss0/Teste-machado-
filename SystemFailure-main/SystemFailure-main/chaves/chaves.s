; =============================================================================
;  chaves.s - as duas CHAVES (verde e azul): sorteiam o lugar e flutuam
;
;  O QUE FAZ
;    - A chave VERDE fica no Quarto 2 e a AZUL na Sala de Maquinas. Em cada sala a chave
;      so aparece na sala dela (nas outras ela fica escondida).
;    - Cada chave tem 3 LUGARES POSSIVEIS (os circulos vermelhos do mapa). A cada partida,
;      quando o jogador aperta START, cada chave sorteia 1 dos seus 3 lugares e fica nele.
;    - A chave flutua: sobe e desce de 1 em 1 pixel, em degraus (estilo jogo antigo).
;          passo:      0  1  2  3  4  5  6  7        (cada passo dura 8 quadros)
;          sobe (px):  0  1  2  3  3  2  1  0        (ciclo de 64 quadros; a azul comeca 4 passos adiante)
;
;  COMO O SORTEIO FUNCIONA (o NES nao tem numero aleatorio)
;    1. Na tela inicial, a cada quadro, ck_rng sobe 1 (chaves_tick). Quando o jogador aperta
;       START, o valor depende de quanto tempo ele esperou: essa e a "semente".
;    2. chaves_init embaralha a semente com um LFSR de 8 bits (o jeito classico dos jogos de NES)
;       e tira o resto da divisao por 3 (0, 1 ou 2). Faz isso 2 vezes: uma para cada chave.
;
;  O QUE ALTERAR NO main.s (4 linhas, detalhes no LEIA-ME.md):
;     .include "chaves.s"          junto dos outros .include de rotinas
;     state_title:   jsr chaves_tick     (primeira linha do estado da tela inicial)
;     start_game:    jsr chaves_init     (depois de jsr hud_init)
;     state_game:    jsr chaves_update   (depois de jsr machado_update)
;
;  Depende dos nomes do jogo: OAM, anim_timer, room, ROOM_QUARTO2 (e ROOM_MAQUINAS, ver abaixo).
;  O desenho esta nos tiles $30-$33 e $40-$43 do TitleSprites.chr; as cores vem das paletas de
;  sprite que o jogo ja tem (verde = paleta 1, azul = paleta 0).
;
;  OAM: personagem $00-$0F | machado $10-$2F | CHAVES $30-$4F (2 chaves x 16 bytes)
;
;  Convencao dos comentarios: "A <- 5" = o acumulador passa a valer 5; "[x] <- A" = a memoria x
;  recebe A; "A, X, Y intactos" = esses registradores nao mudam nesta linha.
; =============================================================================

; -----------------------------------------------------------------------------
;  CONFIGURACAO
; -----------------------------------------------------------------------------
CK_OAM     = $30            ; byte da OAM onde ficam os sprites da chave 0; a chave 1 vem 16 bytes depois
CK_LUGARES = 3              ; quantos lugares possiveis cada chave tem

; A Sala de Maquinas ainda nao esta ligada ao jogo. Quando voces criarem a constante ROOM_MAQUINAS
; no constantes.inc (junto de ROOM_SPAWN e ROOM_QUARTO2), esta linha deixa de valer sozinha.
.ifndef ROOM_MAQUINAS
ROOM_MAQUINAS = 2
.endif

; -----------------------------------------------------------------------------
;  Variaveis na Zero Page (5 bytes)
; -----------------------------------------------------------------------------
.segment "ZEROPAGE"
ck_rng:     .res 1          ; contador na tela inicial; depois do START vira o estado do sorteio
ck_spot:    .res 2          ; lugar sorteado de cada chave (0, 1 ou 2): [0] = verde, [1] = azul
ck_x:       .res 1          ; X da chave que esta sendo desenhada
ck_y:       .res 1          ; Y da chave que esta sendo desenhada (no chao, depois menos a subida)

.segment "CODE"

; =============================================================================
; chaves_tick: chamado a cada quadro da TELA INICIAL. So conta o tempo.
; Altera nada alem de ck_rng. A, X, Y intactos.
; =============================================================================
.proc chaves_tick
    inc ck_rng              ; [ck_rng] <- [ck_rng] + 1 (da a volta em 255). A, X, Y intactos
    rts                     ; volta. A, X, Y intactos
.endproc

; =============================================================================
; chaves_init: chamado UMA vez, quando o jogador aperta START (em start_game).
; Sorteia o lugar de cada chave. Altera A, X.   Y intacto.
; =============================================================================
.proc chaves_init
    lda ck_rng              ; A <- semente (quanto tempo o jogador ficou na tela inicial). X, Y intactos
    bne @tem_semente        ; semente diferente de 0? ok. A, X, Y intactos
    lda #$A5                ; A <- $A5: o LFSR trava se a semente for 0, entao usa outra. X, Y intactos
    sta ck_rng              ; [ck_rng] <- A. A, X, Y intactos
@tem_semente:
    jsr ck_sorteia          ; A <- lugar da chave verde (0 a 2). Altera A, X. Y intacto
    sta ck_spot             ; [ck_spot+0] <- A: lugar da chave verde. A, X, Y intactos
    jsr ck_sorteia          ; A <- lugar da chave azul (0 a 2). Altera A, X. Y intacto
    sta ck_spot+1           ; [ck_spot+1] <- A: lugar da chave azul. A, X, Y intactos
    rts                     ; volta. A, X, Y mantem os valores acima
.endproc

; -----------------------------------------------------------------------------
;  ck_sorteia: devolve em A um numero de 0 a CK_LUGARES-1.
;  Avanca o LFSR 8 passos (embaralha bem a semente) e tira o resto da divisao por 3.
;  Altera A, X.   Y intacto.
; -----------------------------------------------------------------------------
.proc ck_sorteia
    ldx #$08                ; X <- 8 passos do LFSR. A, Y intactos
@passo:
    lsr ck_rng              ; [ck_rng] <- [ck_rng] / 2; o bit que saiu vai para o Carry. A, X, Y intactos
    bcc @sem_taps           ; saiu 0? nao mexe nos "taps". A, X, Y intactos
    lda ck_rng              ; A <- ck_rng. X, Y intactos
    eor #$B8                ; A <- A XOR $B8: os taps do LFSR de 8 bits (ciclo de 255 valores). X, Y intactos
    sta ck_rng              ; [ck_rng] <- A. A, X, Y intactos
@sem_taps:
    dex                     ; X <- X - 1 (um passo a menos). A, Y intactos
    bne @passo              ; ainda faltam passos? repete. A, X, Y intactos
    lda ck_rng              ; A <- valor embaralhado (1 a 255). X, Y intactos
@resto:
    cmp #CK_LUGARES         ; A < 3? C = 0 se sim. X, Y intactos
    bcc @fim                ; sim? acabou: A e o resto (0, 1 ou 2). A, X, Y intactos
    sbc #CK_LUGARES         ; A <- A - 3 (o Carry ja esta em 1, vindo do cmp). X, Y intactos
    jmp @resto              ; repete ate A ficar menor que 3. A, X, Y intactos
@fim:
    rts                     ; volta com A = 0, 1 ou 2
.endproc

; =============================================================================
; chaves_update: chamado todo quadro. Desenha as duas chaves (cada uma na sua sala, no seu
; lugar sorteado, na altura do quadro). Altera A, X, Y.
; =============================================================================
.proc chaves_update
    ldx #$00                ; X <- 0: chave verde. A, Y intactos
    jsr chave_desenha       ; desenha ou esconde a chave verde. Altera A, Y. X intacto
    ldx #$01                ; X <- 1: chave azul. A, Y intactos
    jmp chave_desenha       ; desenha ou esconde a chave azul (tail call: o rts de la volta a quem chamou)
.endproc

; -----------------------------------------------------------------------------
;  ck_oam_idx: Y <- onde a chave X fica na OAM = CK_OAM + 16 * X.
;  Entrada: X = numero da chave (0 ou 1).  Altera A, Y. X intacto.
; -----------------------------------------------------------------------------
.proc ck_oam_idx
    txa                     ; A <- numero da chave. X, Y intactos
    asl a                   ; A <- A * 2. X, Y intactos
    asl a                   ; A <- A * 4. X, Y intactos
    asl a                   ; A <- A * 8. X, Y intactos
    asl a                   ; A <- A * 16: cada chave usa 4 sprites de 4 bytes. X, Y intactos
    clc                     ; C <- 0. A, X, Y intactos
    adc #CK_OAM             ; A <- primeiro byte da chave na OAM. X, Y intactos
    tay                     ; Y <- A. A, X intactos
    rts                     ; volta com Y = posicao na OAM
.endproc

; =============================================================================
; chave_desenha: escreve os 4 sprites (2x2) de uma chave na OAM, ou os esconde se a chave
; nao e desta sala.
; Entrada: X = numero da chave (0 = verde, 1 = azul).  Altera A, Y. X intacto.
; =============================================================================
.proc chave_desenha
    ; --- esta chave pertence a sala em que o jogador esta? ---
    lda room                ; A <- sala atual. X, Y intactos
    cmp ck_tab_sala, x      ; e a sala desta chave? Z = 1 se sim. X, Y intactos
    beq @nesta_sala         ; sim? desenha. A, X, Y intactos
    jsr ck_oam_idx          ; Y <- posicao desta chave na OAM. Altera A, Y. X intacto
    lda #$FF                ; A <- $FF: Y fora da tela (esconde o sprite). X, Y intactos
    sta OAM+0, y            ; [OAM+0] <- A: esconde cima/esquerda. A, X, Y intactos
    sta OAM+4, y            ; [OAM+4] <- A: esconde cima/direita. A, X, Y intactos
    sta OAM+8, y            ; [OAM+8] <- A: esconde baixo/esquerda. A, X, Y intactos
    sta OAM+12, y           ; [OAM+12] <- A: esconde baixo/direita. A, X, Y intactos
    rts                     ; volta. A = $FF

@nesta_sala:
    ; --- onde ela esta: lugar sorteado desta chave (indice = 3 * chave + lugar) ---
    lda ck_spot, x          ; A <- lugar sorteado desta chave (0 a 2). X, Y intactos
    clc                     ; C <- 0. A, X, Y intactos
    adc ck_tab_ini, x       ; A <- 3 * chave + lugar: posicao nas tabelas de lugares. X, Y intactos
    tay                     ; Y <- A. A, X intactos
    lda ck_tab_x, y         ; A <- X desse lugar. X, Y intactos
    sta ck_x                ; [ck_x] <- A. A, X, Y intactos
    lda ck_tab_y, y         ; A <- Y desse lugar (a chave no chao). X, Y intactos
    sta ck_y                ; [ck_y] <- A. A, X, Y intactos

    ; --- quanto a chave subiu neste quadro (0 a 3 pixels) ---
    lda anim_timer          ; A <- relogio das animacoes. X, Y intactos
    lsr a                   ; A <- A / 2. X, Y intactos
    lsr a                   ; A <- A / 4. X, Y intactos
    lsr a                   ; A <- A / 8: o passo muda a cada 8 quadros (tire um lsr para ir 2x mais rapido). X, Y intactos
    clc                     ; C <- 0. A, X, Y intactos
    adc ck_tab_fase, x      ; A <- passo + fase desta chave (a azul esta 4 passos adiante). X, Y intactos
    and #%00000111          ; A <- A mod 8: o passo volta a 0 depois do 7. X, Y intactos
    tay                     ; Y <- passo (0 a 7), indice da tabela da subida. A, X intactos
    lda ck_y                ; A <- Y da chave no chao. X, Y intactos
    sec                     ; C <- 1, antes de subtrair. A, X, Y intactos
    sbc ck_tab_sobe, y      ; A <- Y no chao - subida: quanto maior a subida, mais alto na tela. X, Y intactos
    sta ck_y                ; [ck_y] <- A: Y final deste quadro. A, X, Y intactos

    ; --- onde escrever na OAM ---
    jsr ck_oam_idx          ; Y <- CK_OAM + 16 * chave. Altera A, Y. X intacto

    ; --- Y dos 4 sprites (cima, cima, baixo, baixo) ---
    lda ck_y                ; A <- Y do topo da chave. X, Y intactos
    sta OAM+0, y            ; [OAM+0] <- A: cima/esquerda. A, X, Y intactos
    sta OAM+4, y            ; [OAM+4] <- A: cima/direita. A, X, Y intactos
    clc                     ; C <- 0. A, X, Y intactos
    adc #$08                ; A <- Y + 8: a linha de baixo. X, Y intactos
    sta OAM+8, y            ; [OAM+8] <- A: baixo/esquerda. A, X, Y intactos
    sta OAM+12, y           ; [OAM+12] <- A: baixo/direita. A, X, Y intactos

    ; --- X dos 4 sprites ---
    lda ck_x                ; A <- X da chave. X, Y intactos
    sta OAM+3, y            ; [OAM+3] <- A: cima/esquerda. A, X, Y intactos
    sta OAM+11, y           ; [OAM+11] <- A: baixo/esquerda. A, X, Y intactos
    clc                     ; C <- 0. A, X, Y intactos
    adc #$08                ; A <- X + 8: a coluna da direita. X, Y intactos
    sta OAM+7, y            ; [OAM+7] <- A: cima/direita. A, X, Y intactos
    sta OAM+15, y           ; [OAM+15] <- A: baixo/direita. A, X, Y intactos

    ; --- atributos: so a paleta (a chave nao e espelhada) ---
    lda ck_tab_attr, x      ; A <- paleta de sprite desta chave (1 = verde, 0 = azul). X, Y intactos
    sta OAM+2, y            ; [OAM+2] <- A. A, X, Y intactos
    sta OAM+6, y            ; [OAM+6] <- A. A, X, Y intactos
    sta OAM+10, y           ; [OAM+10] <- A. A, X, Y intactos
    sta OAM+14, y           ; [OAM+14] <- A. A, X, Y intactos

    ; --- tiles: T, T+1, T+$10, T+$11 (a mesma grade 2x2 do personagem) ---
    lda ck_tab_tile, x      ; A <- tile de cima/esquerda desta chave. X, Y intactos
    sta OAM+1, y            ; [OAM+1] <- A: cima/esquerda = T. A, X, Y intactos
    clc                     ; C <- 0. A, X, Y intactos
    adc #$01                ; A <- T + 1. X, Y intactos
    sta OAM+5, y            ; [OAM+5] <- A: cima/direita = T+1. A, X, Y intactos
    clc                     ; C <- 0. A, X, Y intactos
    adc #$0F                ; A <- T + $10. X, Y intactos
    sta OAM+9, y            ; [OAM+9] <- A: baixo/esquerda = T+$10. A, X, Y intactos
    clc                     ; C <- 0. A, X, Y intactos
    adc #$01                ; A <- T + $11. X, Y intactos
    sta OAM+13, y           ; [OAM+13] <- A: baixo/direita = T+$11. A, X, Y intactos
    rts                     ; volta. X = numero da chave (intacto)
.endproc

; -----------------------------------------------------------------------------
;  TABELAS (ficam na ROM)
; -----------------------------------------------------------------------------
.segment "RODATA"

; ---- uma entrada por chave: [0] = VERDE, [1] = AZUL ----
ck_tab_sala:  .byte ROOM_QUARTO2, ROOM_MAQUINAS     ; sala em que cada chave aparece
ck_tab_tile:  .byte $30, $32        ; tile de cima/esquerda (verde $30-$41, azul $32-$43)
ck_tab_attr:  .byte $01, $00        ; paleta de sprite: 1 = verde, 0 = azul (as que o ppu.s ja tem)
ck_tab_fase:  .byte   0,   4        ; em que passo do ciclo a chave comeca (a azul esta no meio)
ck_tab_ini:   .byte   0, CK_LUGARES  ; onde comecam os lugares de cada chave nas tabelas abaixo

; ---- LUGARES POSSIVEIS: 3 para a chave verde, depois 3 para a azul ----
; (X, Y) e o canto de cima/esquerda da chave NO CHAO, em pixels. Sao os circulos vermelhos do mapa.
; Para mudar um lugar, mude o par X/Y da mesma posicao nas duas linhas. Todos caem num quadrado de 16x16
; de chao livre (X e Y multiplos de 16).
;                 --- verde (Quarto 2) ---     --- azul (Sala de Maquinas) ---
;                 lugar 0  lugar 1  lugar 2     lugar 0  lugar 1  lugar 2
ck_tab_x:     .byte  112,     16,     112,        192,     192,     96
ck_tab_y:     .byte   96,    208,     208,         64,     128,    176

; quanto a chave sobe em cada um dos 8 passos do ciclo (pixels)
ck_tab_sobe:  .byte 0, 1, 2, 3, 3, 2, 1, 0

.segment "CODE"
