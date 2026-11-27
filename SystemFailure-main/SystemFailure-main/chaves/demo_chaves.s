; =============================================================================
;  demo_chaves.s - SO PARA CONFERIR AS CORES. NAO FAZ PARTE DO JOGO.
;  Desenha as duas chaves fixas na tela, a cada quadro, usando as paletas de sprite
;  que o jogo ja tem (ppu.s sem nenhuma mudanca):
;     chave VERDE: tiles $30,$31,$40,$41  atributo $01 (paleta 1)  em x=112, y=64
;     chave AZUL:  tiles $32,$33,$42,$43  atributo $00 (paleta 0)  em x=140, y=64
;  Usa a OAM a partir de $0240 (o jogo usa $0200-$022F).
; =============================================================================
.segment "CODE"
.proc demo_chaves
    ldx #0                  ; X <- 0: indice dentro da tabela
@copia:
    lda @dados, x           ; A <- byte da tabela
    sta $0240, x            ; [OAM+$40+X] <- A
    inx                     ; X <- X + 1
    cpx #32                 ; copiou os 32 bytes (8 sprites x 4)?
    bne @copia              ; nao? repete
    rts
@dados:                     ; Y, tile, atributo, X
    .byte 64,$30,$01,112,  64,$31,$01,120,  72,$40,$01,112,  72,$41,$01,120   ; verde
    .byte 64,$32,$00,140,  64,$33,$00,148,  72,$42,$00,140,  72,$43,$00,148   ; azul
.endproc
