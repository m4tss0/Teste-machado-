#!/usr/bin/env python3
"""
gerar_chaves.py - acrescenta o desenho da CHAVE (16x16 = 4 tiles) ao TitleSprites.chr

O mesmo desenho serve para as duas chaves: a cor vem da PALETA de sprite (verde ou azul),
igual ao HUD, que usa o tile $37 do Rooms.chr nas duas cores.

O desenho fica no formato 2x2 da grade do NEXXT (o mesmo do personagem e do machado):

        TL = T       TR = T+$01        com T = $30  ->  tiles $30, $31, $40, $41
        BL = T+$10   BR = T+$11

Indices de cor do desenho (paleta de sprite):
        0 = transparente    1 = contorno    2 = corpo da chave    3 = brilho

Uso:
    python3 gerar_chaves.py ENTRADA.chr SAIDA.chr [--base 0x30]

  ENTRADA.chr  o TitleSprites.chr do jogo (4096 bytes). NUNCA e alterado.
  SAIDA.chr    arquivo novo (tem de ter outro nome/caminho).
  --base       tile de cima/esquerda do desenho. Padrao: 0x30.

O script RECUSA e nao grava nada se algum dos 4 tiles de destino ja tiver desenho.
Para mudar o desenho, edite o texto de CHAVE abaixo (cada linha tem 16 caracteres).
So precisa de Python 3 (sem bibliotecas extras).
"""
import argparse
import os
import sys

# . = transparente | 1 = contorno | 2 = corpo | 3 = brilho
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


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("entrada")
    ap.add_argument("saida")
    ap.add_argument("--base", type=num, default=0x30)
    a = ap.parse_args()

    if os.path.abspath(a.entrada) == os.path.abspath(a.saida):
        sys.exit("A saida tem de ser OUTRO arquivo (para nao sobrescrever o seu CHR).")
    chr_ = bytearray(open(a.entrada, "rb").read())
    if len(chr_) != 4096:
        sys.exit("O CHR de entrada tem %d bytes; esperava 4096 (uma tabela de sprites)." % len(chr_))
    if len(CHAVE) != 16 or any(len(l) != 16 for l in CHAVE):
        sys.exit("CHAVE deve ter 16 linhas de 16 caracteres.")
    grade = [[0 if c == "." else int(c) for c in lin] for lin in CHAVE]
    if any(not 0 <= v <= 3 for l in grade for v in l):
        sys.exit("CHAVE so pode ter os caracteres . 1 2 3")

    destinos = [a.base, a.base + 1, a.base + 0x10, a.base + 0x11]    # TL, TR, BL, BR
    if a.base < 0 or max(destinos) > 0xFF:
        sys.exit("Destino fora da tabela: $%02X-$%02X" % (min(destinos), max(destinos)))
    ocupados = [t for t in destinos if any(chr_[t * 16:t * 16 + 16])]
    if ocupados:
        sys.exit("RECUSADO: ja ha desenho no(s) tile(s) %s. Nada foi gravado. Escolha outro --base." %
                 ", ".join("$%02X" % t for t in ocupados))

    origens = [(0, 0), (8, 0), (0, 8), (8, 8)]
    for t, (x0, y0) in zip(destinos, origens):
        chr_[t * 16:t * 16 + 16] = tile_bytes(grade, x0, y0)

    open(a.saida, "wb").write(bytes(chr_))
    print("gravado:", a.saida, len(chr_), "bytes")
    print("chave nos tiles " + ", ".join("$%02X" % t for t in destinos) + "  (tile de cima/esquerda = $%02X)" % a.base)


if __name__ == "__main__":
    main()
