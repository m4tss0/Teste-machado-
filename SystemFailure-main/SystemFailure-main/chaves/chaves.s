; =============================================================================
;  chaves.s - as duas CHAVES (verde e azul) como sprites que FLUTUAM
;
;  Estilo de jogo antigo: a chave sobe e desce de 1 em 1 pixel, em degraus,
;  sem movimento suave. Um ciclo completo dura 64 quadros (um pouco mais de 1 s):
;
;     passo:      0  1  2  3  4  5  6  7        (cada passo dura 8 quadros)
;     sobe (px):  0  1  2  3  3  2  1  0        (0 = no chao, 3 = no alto)
;
;  A chave azul comeca no meio do ciclo (fase 4), entao as duas nao se mexem juntas.
;
;  COMO USAR (2 linhas no main.s):
;     .include "chaves.s"          junto dos outros .include de rotinas
;     jsr chaves_update            no state_game, depois de draw_player
;
;  Depende dos nomes do jogo: OAM e anim_timer (o relogio que update_player incrementa
;  a cada quadro). O desenho esta nos tiles $30-$33 e $40-$43 do TitleSprites.chr
;  (veja LEIA-ME.md) e as cores vem das paletas de sprite que o jogo ja tem
;  (verde = paleta 1, azul = paleta 0).
;
;  OAM: personagem $00-$0F | machado $10-$2F | CHAVES $30-$4F (2 chaves x 16 bytes)
;
;  POSICOES: as da tabela ck_tab_x / ck_tab_y sao so de TESTE (chao livre no Spawn e no
;  Quarto 2). A posicao final de cada chave, e o "pegar", ficam para depois.
;
;  Convencao dos comentarios: "A <- 5" = o acumulador passa a valer 5; "[x] <- A" = a memoria x
;  recebe A; "A, X, Y intactos" = esses registradores nao mudam nesta linha.
; =============================================================================

; -----------------------------------------------------------------------------
;  CONFIGURACAO
; -----------------------------------------------------------------------------
CK_OAM = $30                ; byte da OAM onde ficam os sprites da chave 0; a chave 1 vem 16 bytes depois

; -----------------------------------------------------------------------------
;  Variavel na Zero Page (1 byte)
; -----------------------------------------------------------------------------
.segment "ZEROPAGE"
ck_y:       .res 1          ; Y da chave neste quadro (posicao base menos a subida)

.segment "CODE"

; =============================================================================
; chaves_update: chamado todo quadro. Desenha as duas chaves, ja na altura do quadro.
; Altera A, X, Y.
; =============================================================================
.proc chaves_update
    ldx #$00                ; X <- 0: chave verde. A, Y intactos
    jsr chave_desenha       ; desenha a chave verde. Altera A, Y. X intacto
    ldx #$01                ; X <- 1: chave azul. A, Y intactos
    jmp chave_desenha       ; desenha a chave azul (tail call: o rts de la volta a quem chamou)
.endproc

; =============================================================================
; chave_desenha: escreve os 4 sprites (2x2) de uma chave na OAM.
; Entrada: X = numero da chave (0 = verde, 1 = azul).  Altera A, Y. X intacto.
; =============================================================================
.proc chave_desenha
    ; --- quanto a chave subiu neste quadro (0 a 3 pixels) ---
    lda anim_timer          ; A <- relogio das animacoes. X, Y intactos
    lsr a                   ; A <- A / 2. X, Y intactos
    lsr a                   ; A <- A / 4. X, Y intactos
    lsr a                   ; A <- A / 8: o passo muda a cada 8 quadros (tire um lsr para ir 2x mais rapido). X, Y intactos
    clc                     ; C <- 0. A, X, Y intactos
    adc ck_tab_fase, x      ; A <- passo + fase desta chave (a azul esta 4 passos adiante). X, Y intactos
    and #%00000111          ; A <- A mod 8: o passo volta a 0 depois do 7. X, Y intactos
    tay                     ; Y <- passo (0 a 7), indice da tabela da subida. A, X intactos
    lda ck_tab_y, x         ; A <- Y da chave no chao. X, Y intactos
    sec                     ; C <- 1, antes de subtrair. A, X, Y intactos
    sbc ck_tab_sobe, y      ; A <- Y no chao - subida: quanto maior a subida, mais alto na tela. X, Y intactos
    sta ck_y                ; [ck_y] <- A. A, X, Y intactos

    ; --- onde escrever na OAM: CK_OAM + 16 * numero da chave ---
    txa                     ; A <- numero da chave (0 ou 1). X, Y intactos
    asl a                   ; A <- A * 2. X, Y intactos
    asl a                   ; A <- A * 4. X, Y intactos
    asl a                   ; A <- A * 8. X, Y intactos
    asl a                   ; A <- A * 16: cada chave usa 4 sprites de 4 bytes. X, Y intactos
    clc                     ; C <- 0. A, X, Y intactos
    adc #CK_OAM             ; A <- primeiro byte da chave na OAM. X, Y intactos
    tay                     ; Y <- posicao na OAM (Y so e usado como indice daqui para frente). A, X intactos

    ; --- Y dos 4 sprites (cima, cima, baixo, baixo) ---
    lda ck_y                ; A <- Y do topo da chave. X, Y intactos
    sta OAM+0, y            ; [OAM+0] <- A: cima/esquerda. A, X, Y intactos
    sta OAM+4, y            ; [OAM+4] <- A: cima/direita. A, X, Y intactos
    clc                     ; C <- 0. A, X, Y intactos
    adc #$08                ; A <- Y + 8: a linha de baixo. X, Y intactos
    sta OAM+8, y            ; [OAM+8] <- A: baixo/esquerda. A, X, Y intactos
    sta OAM+12, y           ; [OAM+12] <- A: baixo/direita. A, X, Y intactos

    ; --- X dos 4 sprites ---
    lda ck_tab_x, x         ; A <- X da chave. X, Y intactos
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
;  TABELAS (ficam na ROM). Um valor por chave: o 1o e da chave VERDE, o 2o da AZUL.
; -----------------------------------------------------------------------------
.segment "RODATA"

ck_tab_tile:  .byte $30, $32        ; tile de cima/esquerda (verde $30-$41, azul $32-$43)
ck_tab_attr:  .byte $01, $00        ; paleta de sprite: 1 = verde, 0 = azul (as que o ppu.s ja tem)
ck_tab_x:     .byte 112, 140        ; X no chao (TESTE: posicao final fica para depois)
ck_tab_y:     .byte  64,  64        ; Y no chao (TESTE: idem)
ck_tab_fase:  .byte   0,   4        ; em que passo do ciclo a chave comeca (a azul esta no meio)

; quanto a chave sobe em cada um dos 8 passos do ciclo (pixels)
ck_tab_sobe:  .byte 0, 1, 2, 3, 3, 2, 1, 0

.segment "CODE"
