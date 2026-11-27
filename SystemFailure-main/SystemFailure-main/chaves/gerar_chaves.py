#!/usr/bin/env python3
"""
gerar_chaves.py - acrescenta as DUAS CHAVES (verde e azul) ao TitleSprites.chr

Usa so as paletas de sprite que o jogo JA TEM (ppu.s, nao precisa mudar nada):

    paleta 1 = $0F,$0B,$2A,$10  (a do "inimigo parado")  -> chave VERDE:  corpo $2A, contorno $0B, brilho $10
    paleta 0 = $0F,$07,$37,$31  (a do personagem)        -> chave AZUL:   corpo $31, contorno $07, brilho $37

A cor azul ($31) so existe na posicao 3 da paleta 0 (a posicao 2 dela e $37, bege), entao a chave azul
precisa de tiles proprios, com o corpo pintado com o indice 3. Por isso sao 2 desenhos de 4 tiles.

Cada chave e um bloco 2x2 na grade do NEXXT (o mesmo formato do personagem e do machado):

        TL = T       TR = T+$01
        BL = T+$10   BR = T+$11

        chave VERDE: T = $30  ->  tiles $30, $31, $40, $41   (usar com atributo $01)
        chave AZUL:  T = $32  ->  tiles $32, $33, $42, $43   (usar com atributo $00)

Uso:
    python3 gerar_chaves.py ENTRADA.chr SAIDA.chr [--verde 0x30] [--azul 0x32]

  ENTRADA.chr  o TitleSprites.chr do jogo (4096 bytes). NUNCA e alterado.
  SAIDA.chr    arquivo novo (tem de ser outro arquivo).

O script RECUSA e nao grava nada se algum dos 8 tiles de destino ja tiver desenho.
Para mudar o desenho, edite o texto de CHAVE (16 linhas de 16 caracteres).
So precisa de Python 3 (sem bibliotecas extras).
"""
import argparse
import os
import sys

# Desenho base. . = transparente | 1 = contorno | 2 = corpo | 3 = brilho
CHAVE = [
    ".....111111.....",
    "....11322211....",
    "...1132222211...",
    "...132....221...",
    "...132....221...",
    "...122....221...",
    "...122....221...",
    "...1122222211...",
    "....11222211....",
    "....1113211.....",
    "....122321......",
    "....122321......",
    "....111321......",
    "....122321......",
    "....122221......",
    "....111111......",
]

# Como cada chave troca os indices de cor do desenho base (contorno, corpo, brilho):
VERDE_MAPA = {0: 0, 1: 1, 2: 2, 3: 3}     # corpo = indice 2 ($2A na paleta 1)
AZUL_MAPA = {0: 0, 1: 1, 2: 3, 3: 2}      # corpo = indice 3 ($31 na paleta 0), brilho = indice 2 ($37)


def num(s):
    return int(s, 0)


def tile_bytes(grade, x0, y0):
    """16 bytes de um tile 8x8: 8 de plano 0 (bit 0 da cor) + 8 de plano 1 (bit 1 da cor)."""
    p0, p1 = [], []
    for y in range(8):
        a = b = 0
        for x in range(8):
            c = grade[y0 + y][x0 + x]
            a = (a << 1) | (c & 1)
            b = (b << 1) | ((c >> 1) & 1)
        p0.append(a)
        p1.append(b)
    return bytes(p0 + p1)


def tiles_do_bloco(base):
    return [base, base + 1, base + 0x10, base + 0x11]       # TL, TR, BL, BR


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("entrada")
    ap.add_argument("saida")
    ap.add_argument("--verde", type=num, default=0x30)
    ap.add_argument("--azul", type=num, default=0x32)
    a = ap.parse_args()

    if os.path.abspath(a.entrada) == os.path.abspath(a.saida):
        sys.exit("A saida tem de ser OUTRO arquivo (para nao sobrescrever o seu CHR).")
    chr_ = bytearray(open(a.entrada, "rb").read())
    if len(chr_) != 4096:
        sys.exit("O CHR de entrada tem %d bytes; esperava 4096 (uma tabela de sprites)." % len(chr_))
    if len(CHAVE) != 16 or any(len(l) != 16 for l in CHAVE):
        sys.exit("CHAVE deve ter 16 linhas de 16 caracteres.")
    base = [[0 if c == "." else int(c) for c in lin] for lin in CHAVE]
    if any(not 0 <= v <= 3 for l in base for v in l):
        sys.exit("CHAVE so pode ter os caracteres . 1 2 3")

    pedidos = [("verde", a.verde, VERDE_MAPA), ("azul", a.azul, AZUL_MAPA)]
    todos = []
    for nome, b, _ in pedidos:
        if b < 0 or max(tiles_do_bloco(b)) > 0xFF:
            sys.exit("Destino da chave %s fora da tabela: $%02X" % (nome, b))
        todos += tiles_do_bloco(b)
    if len(set(todos)) != len(todos):
        sys.exit("As duas chaves se sobrepoem. Escolha bases diferentes (--verde / --azul).")
    ocupados = [t for t in todos if any(chr_[t * 16:t * 16 + 16])]
    if ocupados:
        sys.exit("RECUSADO: ja ha desenho no(s) tile(s) %s. Nada foi gravado. Escolha outra base." %
                 ", ".join("$%02X" % t for t in ocupados))

    origens = [(0, 0), (8, 0), (0, 8), (8, 8)]
    for nome, b, mapa in pedidos:
        grade = [[mapa[v] for v in linha] for linha in base]
        for t, (x0, y0) in zip(tiles_do_bloco(b), origens):
            chr_[t * 16:t * 16 + 16] = tile_bytes(grade, x0, y0)

    open(a.saida, "wb").write(bytes(chr_))
    print("gravado:", a.saida, len(chr_), "bytes")
    print("chave VERDE: tiles " + ", ".join("$%02X" % t for t in tiles_do_bloco(a.verde)) + "  -> atributo $01 (paleta 1)")
    print("chave AZUL:  tiles " + ", ".join("$%02X" % t for t in tiles_do_bloco(a.azul)) + "  -> atributo $00 (paleta 0)")


if __name__ == "__main__":
    main()
