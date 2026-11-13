#!/usr/bin/env python3
"""
mesclar_machado.py - gera assets/Tiles/TitleSprites_machado.chr

Pega o TitleSprites.chr ORIGINAL (nunca e alterado) e acrescenta o machado nos tiles $C0-$FF,
arrumado em blocos 2x2 na grade do NEXXT (16 tiles por linha):

        TL = T     TR = T+$01
        BL = T+$10 BR = T+$11        (e o mesmo formato do personagem)

Quadro i (0 a 14) fica no bloco de base:  $C0 + (i // 8) * $20 + (i % 8) * 2
Item no chao (quadro 15):                 $EE

O script RECUSA e nao grava nada se algum tile de destino ja tiver desenho.

Uso (a partir da pasta do projeto):
    python3 tools/mesclar_machado.py
"""
import os
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.dirname(AQUI)
ORIGINAL = os.path.join(RAIZ, "assets", "Tiles", "TitleSprites.chr")
FONTE = os.path.join(RAIZ, "assets", "Machado", "machado_slots.chr")
SAIDA = os.path.join(RAIZ, "assets", "Tiles", "TitleSprites_machado.chr")

HALF = 0x1000            # em machado_slots.chr os sprites estao na 2a metade
SRC_MAO = 0x70           # 15 quadros x 4 tiles em fila: $70-$AB
SRC_CHAO = 0x68          # machado no chao: 4 tiles em fila
BASE = 0xC0              # primeiro tile livre no TitleSprites.chr


def base_quadro(i):
    return BASE + (i // 8) * 0x20 + (i % 8) * 2


def main():
    orig = bytearray(open(ORIGINAL, "rb").read())
    fonte = open(FONTE, "rb").read()
    if len(orig) != 4096:
        sys.exit("TitleSprites.chr deve ter 4096 bytes (tem %d)" % len(orig))
    if len(fonte) != 8192:
        sys.exit("machado_slots.chr deve ter 8192 bytes (tem %d)" % len(fonte))

    # lista (origem, base de destino): 15 quadros + item
    blocos = [(SRC_MAO + 4 * i, base_quadro(i)) for i in range(15)]
    blocos.append((SRC_CHAO, base_quadro(15)))

    destinos = []
    for _, b in blocos:
        destinos += [b, b + 1, b + 0x10, b + 0x11]
    if len(set(destinos)) != len(destinos):
        sys.exit("erro interno: dois quadros no mesmo tile")
    ocupados = [t for t in destinos if any(orig[t * 16:t * 16 + 16])]
    if ocupados:
        sys.exit("RECUSADO: ja ha desenho nos tiles %s. Nada foi gravado." %
                 ", ".join("$%02X" % t for t in ocupados))
    if min(destinos) < BASE or max(destinos) > 0xFF:
        sys.exit("destino fora de $C0-$FF")

    for origem, b in blocos:
        for k, off in enumerate((0, 1, 0x10, 0x11)):     # TL, TR, BL, BR
            s = HALF + (origem + k) * 16
            d = (b + off) * 16
            orig[d:d + 16] = fonte[s:s + 16]

    open(SAIDA, "wb").write(bytes(orig))
    print("gravado:", os.path.relpath(SAIDA, RAIZ), len(orig), "bytes")
    for i in range(15):
        print("  quadro %2d -> tile base $%02X" % (i, base_quadro(i)))
    print("  item chao -> tile base $%02X" % base_quadro(15))


if __name__ == "__main__":
    main()
