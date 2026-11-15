#!/usr/bin/env python3
"""Draws the boot screen u-boot shows (tela-boot.bmp) from the same text the
console draws later (rootfs/etc/tela-boot.txt), with the kernel's 8x8 font,
so the picture does not change when the kernel takes over the screen.

Usage: gerar-tela-boot.py <linux>/lib/fonts/font_8x8.c rootfs/etc/tela-boot.txt boot/tela-boot.bmp

Layout (must match the progresso() function in rootfs/etc/main):
  40x30 text cells of 8x8 pixels on the 320x240 screen, art in bright white,
  progress bar on row 28 / column 7 in bright green, shown at 0%.
u-boot only draws 4/8/24-bit BMPs: this writes an 8-bit one.
"""
import re
import struct
import sys

W, H, CELL = 320, 240, 8
BLACK, WHITE, GREEN = 0, 1, 2
# Linux console colours 15 (bright white) and 10 (bright green)
PALETTE = {BLACK: (0, 0, 0), WHITE: (0xFF, 0xFF, 0xFF), GREEN: (0x55, 0xFF, 0x55)}
BAR_ROW, BAR_COL = 28, 7


def load_font(path):
    data = [int(m, 16) for m in re.findall(r'^\s*(0x[0-9a-fA-F]{2}),', open(path).read(), re.M)]
    if len(data) != 256 * 8:
        sys.exit(f"{path}: esperava 2048 bytes de fonte, achei {len(data)}")
    return data


def main():
    font_c, art_txt, out_bmp = sys.argv[1:4]
    font = load_font(font_c)
    pix = bytearray(W * H)

    def put_text(row, col, text, color):  # row/col are 1-based, like the console
        for i, ch in enumerate(text):
            x0, y0 = (col - 1 + i) * CELL, (row - 1) * CELL
            if x0 >= W or y0 >= H:
                continue
            glyph = font[ord(ch) * 8: ord(ch) * 8 + 8]
            for dy, bits in enumerate(glyph):
                for dx in range(8):
                    if bits & (0x80 >> dx):
                        pix[(y0 + dy) * W + x0 + dx] = color

    for row, line in enumerate(open(art_txt).read().split('\n'), start=1):
        put_text(row, 1, line, WHITE)
    put_text(BAR_ROW, BAR_COL, '[' + '.' * 20 + ']   0%', GREEN)

    pal = b''.join(struct.pack('<BBBB', *reversed(PALETTE.get(i, (0, 0, 0))), 0) for i in range(256))
    rows = b''.join(bytes(pix[y * W:(y + 1) * W]) for y in reversed(range(H)))  # BMP is bottom-up
    off = 14 + 40 + len(pal)
    hdr = b'BM' + struct.pack('<IHHI', off + len(rows), 0, 0, off)
    dib = struct.pack('<IiiHHIIiiII', 40, W, H, 1, 8, 0, len(rows), 2835, 2835, 256, 0)
    open(out_bmp, 'wb').write(hdr + dib + pal + rows)


if __name__ == '__main__':
    main()
